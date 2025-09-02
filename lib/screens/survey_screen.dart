// lib/screens/survey_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../db/app_db.dart' as db;
import '../services/magnetometer_service.dart';
import '../services/export_service.dart';

class SurveyScreen extends StatefulWidget {
  final int projectId;
  final db.AppDb database;

  const SurveyScreen({
    super.key,
    required this.projectId,
    required this.database,
  });

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  // Map
  final MapController _map = MapController();
  bool _mapReady = false;
  bool _pendingFollow = false;

  // Position / heading
  LatLng? _pos;
  LatLng? _lastPos;

  double _deviceHeading = 0; // compass deg
  double _courseHeading = 0; // course/bearing deg (moving)
  double _navHeading = 0;    // final chosen heading
  double _zoom = 17;

  bool _follow = true;
  bool _rotate = true;
  bool _autoHeading = true; // course when moving, compass when still
  bool _useSatellite = false;

  static const double _alpha = 0.25;      // heading smoothing
  static const double _speedThresh = 1.5; // m/s to trust GPS course

  // Streams/layers
  StreamSubscription<Position>? _posSub;
  StreamSubscription<List<db.Point>>? _pointsSub;
  StreamSubscription<CompassEvent>? _compassSub;

  List<Polyline> _gridLines = [];
  List<Marker> _pointMarkers = [];

  // Recording + magnetometer
  late final PhoneMagnetometerService _phoneMag;
  StreamSubscription<MagVector>? _magSub;
  MagVector? _mag; // x/y/z + magnitude
  String _activeSource = 'phone'; // 'phone' or 'ble' placeholder

  bool _recording = false;
  DateTime? _lastWrite;
  LatLng? _lastWritePos;

  static const int _minSecondsBetween = 1;
  static const double _minMetersBetween = 2.0;
  static const double _maxAllowedAccuracyM = 20.0;

  // Export service
  late final ExportService _exporter;

  @override
  void initState() {
    super.initState();
    _exporter = ExportService(widget.database);
    _initLocation();
    _loadGrids();
    _watchPoints();

    // Phone magnetometer
    _phoneMag = PhoneMagnetometerService(alpha: 0.25)..start();
    _magSub = _phoneMag.stream.listen((v) {
      _mag = v;
      if (mounted && !_recording) setState(() {});
    });

    // Compass (for stationary heading)
    _compassSub = FlutterCompass.events?.listen((e) {
      final h = e.heading;
      if (h == null) return;
      _deviceHeading = h;
      _recomputeHeading(moving: false, hasCourse: false);
      if (mounted && _rotate && _follow && _mapReady) {
        _map.rotate(_navHeading);
      }
    });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _pointsSub?.cancel();
    _compassSub?.cancel();
    _magSub?.cancel();
    _phoneMag.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  // ------- Location stream -------
  Future<void> _initLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) return;
    }
    if (perm == LocationPermission.deniedForever) return;

    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 2,
      ),
    ).listen((p) async {
      final ll = LatLng(p.latitude, p.longitude);
      final moving = p.speed >= _speedThresh;
      final hasCourse = p.heading >= 0 && p.heading <= 360;

      if (moving && hasCourse) {
        _courseHeading = _smoothDeg(_courseHeading, p.heading, _alpha);
      } else if (_pos != null) {
        _courseHeading = _smoothDeg(_courseHeading, _bearing(_pos!, ll), _alpha);
      }

      _lastPos = _pos;
      _pos = ll;
      _recomputeHeading(moving: moving, hasCourse: hasCourse);

      if (_follow) {
        if (_mapReady) _applyFollow();
        else _pendingFollow = true;
      }

      // --- Recording: gate & write ---
      if (_recording) {
        final now = DateTime.now();
        final timeOk = _lastWrite == null || now.difference(_lastWrite!).inSeconds >= _minSecondsBetween;
        final distOk = _lastWritePos == null ||
            const Distance().as(LengthUnit.Meter, _lastWritePos!, ll) >= _minMetersBetween;
        final accOk = p.accuracy.isFinite ? (p.accuracy <= _maxAllowedAccuracyM) : true;

        if (timeOk && distOk && accOk && _mag != null) {
          final mv = _mag!;
          final movingHeading = p.heading.isFinite ? p.heading : null;
          final chosenHeading = _autoHeading
              ? (movingHeading ?? _deviceHeading)
              : _deviceHeading;

          await widget.database.insertPoint(
            projectId: widget.projectId,
            lat: p.latitude,
            lon: p.longitude,
            altitude: p.altitude.isFinite ? p.altitude : 0.0,
            magneticX: mv.x,
            magneticY: mv.y,
            magneticZ: mv.z,
            totalField: mv.mag,
            courseDeg: movingHeading,
            speedMs: p.speed.isFinite ? p.speed : null,
            accuracyM: p.accuracy.isFinite ? p.accuracy : null,
            headingDeg: chosenHeading,
            source: (_activeSource == 'ble') ? 'ble' : 'phone',
          );

          _lastWrite = now;
          _lastWritePos = ll;
        }
      }

      if (mounted) setState(() {});
    });
  }





  double _cameraBearingDeg() {
    if (!_mapReady) return 0.0;
    try {
      final r = _map.camera.rotation;
      // If it looks like radians (|r| <= 2π), convert to degrees.
      if (r.abs() <= 6.283185307179586) return r * 180.0 / math.pi;
      return r; // already degrees
    } catch (_) {
      return 0.0; // controller not bound yet; be safe
    }
}


  double _markerAngleRad() {
    final screenDeg = _normalizeDeg(_navHeading - _cameraBearingDeg() + 90.0);
    return screenDeg * math.pi / 180.0;
  }






  // ------- DB layers -------
  Future<void> _loadGrids() async {
    final grids = await widget.database.listGrids(widget.projectId);
    final dist = const Distance();
    LatLng off(LatLng o, double meters, double brg) => dist.offset(o, meters, brg);

    final List<Polyline> lines = [];
    for (final g in grids) {
      final center = LatLng(g.centerLat, g.centerLon);
      final totalW = g.cols * g.cellSizeM;
      final totalH = g.rows * g.cellSizeM;

      final topLeft = off(
        off(center, -(totalH / 2), g.rotationDeg + 90),
        -(totalW / 2),
        g.rotationDeg,
      );

      // verticals
      for (int c = 0; c <= g.cols; c++) {
        final s = off(topLeft, c * g.cellSizeM, g.rotationDeg);
        final e = off(s, totalH, g.rotationDeg + 90);
        lines.add(Polyline(points: [s, e], strokeWidth: 1.5, color: Colors.black54));
      }
      // horizontals
      for (int r = 0; r <= g.rows; r++) {
        final s = off(topLeft, r * g.cellSizeM, g.rotationDeg + 90);
        final e = off(s, totalW, g.rotationDeg);
        lines.add(Polyline(points: [s, e], strokeWidth: 1.5, color: Colors.black54));
      }
    }

    if (!mounted) return;
    setState(() => _gridLines = lines);
  }

  void _watchPoints() {
    _pointsSub = widget.database.watchPoints(widget.projectId).listen((rows) {
      final markers = rows.map((p) {
        return Marker(
          point: LatLng(p.lat, p.lon),
          width: 14,
          height: 14,
          alignment: Alignment.center,
          child: Container(
            decoration: BoxDecoration(
              color: _colorFor(p.totalField),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.2),
            ),
          ),
        );
      }).toList();

      if (!mounted) return;
      setState(() => _pointMarkers = markers);
    });
  }

  // ------- Heading math -------
  double _normalizeDeg(double d) {
    double x = d % 360.0;
    if (x < 0) x += 360.0;
    return x;
  }

  double _smoothDeg(double prev, double next, double a) {
    final diff = ((next - prev + 540) % 360) - 180;
    return _normalizeDeg(prev + a * diff);
  }

  double _bearing(LatLng a, LatLng b) {
    final l1 = a.latitude * math.pi / 180;
    final l2 = b.latitude * math.pi / 180;
    final dLon = (b.longitude - a.longitude) * math.pi / 180;
    final y = math.sin(dLon) * math.cos(l2);
    final x = math.cos(l1) * math.sin(l2) - math.sin(l1) * math.cos(l2) * math.cos(dLon);
    return _normalizeDeg(math.atan2(y, x) * 180 / math.pi);
  }

  void _recomputeHeading({bool moving = false, bool hasCourse = false}) {
    final target = _autoHeading
        ? ((moving && hasCourse) ? _courseHeading : _deviceHeading)
        : _deviceHeading;

    _navHeading = _smoothDeg(_navHeading, target, _alpha);

    if (_follow && _rotate && _mapReady) {
      try { _map.rotate(_navHeading); } catch (_) {/* ignore until ready */}
    }
  }

  // ------- Map helpers -------
  void _applyFollow() {
    if (_pos == null || !_mapReady) return;
    if (_rotate) {
      try {
        _map.moveAndRotate(_pos!, _zoom, _navHeading);
      } catch (_) {
        _map.move(_pos!, _zoom);
        _map.rotate(_navHeading);
      }
    } else {
      _map.move(_pos!, _zoom);
    }
  }

  // ------- Export bottom sheet -------
  Future<void> _showExportSheet() async {
    bool selCsv = true;
    bool selGeojson = true;
    bool selKml = false;
    bool selWkt = false;
    bool selDb = true;
    bool makeZip = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16, right: 16, top: 12,
          ),
          child: StatefulBuilder(
            builder: (ctx, setM) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 4, width: 44, margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(2)),
                  ),
                  const Text('Export survey data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  CheckboxListTile(value: selCsv, onChanged: (v) => setM(() => selCsv = v ?? false), title: const Text('CSV (points)'), dense: true),
                  CheckboxListTile(value: selGeojson, onChanged: (v) => setM(() => selGeojson = v ?? false), title: const Text('GeoJSON (points + grids)'), dense: true),
                  CheckboxListTile(value: selKml, onChanged: (v) => setM(() => selKml = v ?? false), title: const Text('KML (Google Earth)'), dense: true),
                  CheckboxListTile(value: selWkt, onChanged: (v) => setM(() => selWkt = v ?? false), title: const Text('WKT CSV (Shapefile import)'), dense: true),
                  const Divider(),
                  CheckboxListTile(value: selDb, onChanged: (v) => setM(() => selDb = v ?? false), title: const Text('SQLite DB (geomag.db copy)'), dense: true),
                  SwitchListTile(value: makeZip, onChanged: (v) => setM(() => makeZip = v), title: const Text('Package as .zip (if multiple)'), dense: true),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                      const Spacer(),
                      FilledButton.icon(
                        icon: const Icon(Icons.ios_share),
                        label: const Text('Export'),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _performExport(
                            csv: selCsv, geojson: selGeojson, kml: selKml, wkt: selWkt, db: selDb, zip: makeZip,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _performExport({
    required bool csv,
    required bool geojson,
    required bool kml,
    required bool wkt,
    required bool db,
    required bool zip,
  }) async {
    try {
      final kinds = <ExportKind>[
        if (csv) ExportKind.csvPoints,
        if (geojson) ExportKind.geojsonPointsAndGrids,
        if (kml) ExportKind.kmlPointsAndGrids,
        if (wkt) ExportKind.wktPointsCsv,
        if (db) ExportKind.sqliteDbCopy,
      ];
      if (kinds.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select at least one format.')),
        );
        return;
      }

      await _exporter.export(
        projectId: widget.projectId,
        kinds: kinds,
        zipIfMultiple: zip,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export complete.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  // ------- Color scale (total field -> color) -------
  Color _colorFor(double v, {double vmin = 20, double vmax = 70}) {
    v = v.clamp(vmin, vmax);
    final t = (v - vmin) / (vmax - vmin);
    return HSVColor.lerp(
      const HSVColor.fromAHSV(1, 220, 0.8, 0.9),
      const HSVColor.fromAHSV(1, 0, 0.9, 0.9),
      t,
    )!.toColor();
  }

  // ------- UI -------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (_pos == null)
            const Center(child: CircularProgressIndicator())
          else
            FlutterMap(
              mapController: _map,
              options: MapOptions(
                initialCenter: _pos!,
                initialZoom: _zoom,
                initialRotation: _navHeading,
                onMapReady: () {
                  _mapReady = true;
                  if (_pendingFollow && _pos != null && _follow) {
                    _applyFollow();
                    _pendingFollow = false;
                  }
                  if (_pos != null && _follow) _applyFollow();
                  setState(() {});
                },
                onPositionChanged: (pos, hasGesture) {
                  if (hasGesture && _follow) setState(() => _follow = false);
                },
              ),
              children: [
                if (!_useSatellite)
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.geomag',
                  )
                else
                  TileLayer(
                    urlTemplate: 'https://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                    userAgentPackageName: 'com.example.geomag',
                  ),

                if (_gridLines.isNotEmpty) PolylineLayer(polylines: _gridLines),

                if (_pointMarkers.isNotEmpty) MarkerLayer(markers: _pointMarkers),

                if (_pos != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _pos!,
                        width: 56,
                        height: 56,
                        alignment: Alignment.center,
                        child: Transform.rotate(
                          angle: _markerAngleRad(),
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.92),
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                  offset: Offset(0, 2),
                                  color: Color(0x55000000),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.navigation, size: 30, color: Colors.indigo),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),

          // Legend (top-left)
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 12,
            child: _Legend(minV: 20, maxV: 70, title: 'Total Field (µT)'),
          ),

          // Controls (top-right)
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _ControlButton(
                  icon: _useSatellite ? Icons.satellite_alt : Icons.map,
                  label: _useSatellite ? 'Imagery' : 'Map',
                  onTap: () => setState(() => _useSatellite = !_useSatellite),
                ),
                const SizedBox(height: 8),
                _ControlButton(
                  icon: _rotate ? Icons.explore : Icons.explore_off,
                  label: _rotate ? 'Rotate On' : 'Rotate Off',
                  onTap: () {
                    setState(() => _rotate = !_rotate);
                    if (_follow && _mapReady) _applyFollow();
                  },
                ),
                const SizedBox(height: 8),
                _ControlButton(
                  icon: _follow ? Icons.my_location : Icons.location_disabled,
                  label: _follow ? 'Following' : 'Free pan',
                  onTap: () => setState(() => _follow = !_follow),
                ),
                const SizedBox(height: 8),
                _ControlButton(
                  icon: _activeSource == 'phone' ? Icons.phone_android : Icons.sensors,
                  label: _activeSource == 'phone' ? 'Phone mag' : 'External',
                  onTap: () async {
                    setState(() {
                      _activeSource = (_activeSource == 'phone') ? 'ble' : 'phone';
                    });
                    if (_activeSource == 'phone') {
                      _phoneMag.start();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Using phone magnetometer')),
                        );
                      }
                    } else {
                      await _phoneMag.stop();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('External sensor mode (connect later)')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),

          // Bottom-left: grid + export
          Positioned(
            left: 12,
            bottom: 16 + MediaQuery.of(context).padding.bottom,
            child: Row(
              children: [
                FilledButton.tonal(
                  onPressed: _showNewGridSheet,
                  child: const Row(children: [Icon(Icons.grid_on), SizedBox(width: 8), Text('New Grid')]),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: _showExportSheet,
                  child: const Row(children: [Icon(Icons.ios_share), SizedBox(width: 8), Text('Export')]),
                ),
              ],
            ),
          ),

          // Bottom-right: recenter + record
          Positioned(
            right: 12,
            bottom: 16 + MediaQuery.of(context).padding.bottom,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!_follow)
                  FloatingActionButton.extended(
                    heroTag: 'recenter',
                    onPressed: () {
                      setState(() => _follow = true);
                      if (_mapReady) _applyFollow();
                    },
                    icon: const Icon(Icons.center_focus_strong),
                    label: const Text('Recenter'),
                  ),
                const SizedBox(height: 8),
                FloatingActionButton.extended(
                  heroTag: 'record',
                  backgroundColor: _recording ? Colors.red : Colors.green,
                  onPressed: () async {
                    setState(() => _recording = !_recording);
                    if (_recording) {
                      _lastWrite = null;
                      _lastWritePos = null;
                      await WakelockPlus.enable(); // keep screen awake
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Recording started')),
                        );
                      }
                    } else {
                      await WakelockPlus.disable();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Recording stopped')),
                        );
                      }
                    }
                  },
                  icon: Icon(_recording ? Icons.stop : Icons.fiber_manual_record),
                  label: Text(_recording ? 'Stop' : 'Record'),
                ),
              ],
            ),
          ),

          // Attribution
          Positioned(
            left: 8,
            bottom: MediaQuery.of(context).padding.bottom + 4,
            child: Opacity(
              opacity: 0.6,
              child: Text(
                _useSatellite ? 'Imagery © Esri' : '© OpenStreetMap contributors',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------- New grid sheet -------
  Future<void> _showNewGridSheet() async {
    final name = TextEditingController(text: 'Grid');
    final rows = TextEditingController(text: '10');
    final cols = TextEditingController(text: '10');
    final cell = TextEditingController(text: '25');
    final rot = TextEditingController(text: '0');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('New Survey Grid', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: rows,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Rows'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: cols,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Cols'),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: cell,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Cell size (m)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: rot,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Rotation (deg)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                icon: const Icon(Icons.grid_on),
                label: const Text('Create'),
                onPressed: () async {
                  final c = _pos ?? const LatLng(0, 0);
                  await widget.database.createGrid(
                    projectId: widget.projectId,
                    name: name.text.trim().isEmpty ? 'Grid' : name.text.trim(),
                    centerLat: c.latitude,
                    centerLon: c.longitude,
                    rows: int.tryParse(rows.text) ?? 10,
                    cols: int.tryParse(cols.text) ?? 10,
                    cellSizeM: double.tryParse(cell.text) ?? 25,
                    rotationDeg: double.tryParse(rot.text) ?? 0,
                  );
                  if (!mounted) return;
                  Navigator.pop(ctx);
                  await _loadGrids();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------- Small UI helpers (legend + buttons) ----------

class _Legend extends StatelessWidget {
  final double minV;
  final double maxV;
  final String title;
  const _Legend({required this.minV, required this.maxV, required this.title});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                SizedBox(
                  width: 120, height: 10,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [
                        Color(0xFF2B6CB0), // blue
                        Color(0xFFE53E3E), // red
                      ]),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('${minV.toStringAsFixed(0)}'),
                    const SizedBox(width: 96),
                    Text('${maxV.toStringAsFixed(0)}'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ControlButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}
