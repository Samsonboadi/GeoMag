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
import '../widgets/modern_feedback.dart';
import '../widgets/modern_loading.dart';
import 'data_analysis_screen.dart';

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

  // Point counter for UI
  int _pointCount = 0;

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
    if (!serviceEnabled) {
      if (mounted) {
        ModernFeedback.showError(context, 'Location services are disabled');
      }
      return;
    }

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) {
        if (mounted) {
          ModernFeedback.showError(context, 'Location permission denied');
        }
        return;
      }
    }
    if (perm == LocationPermission.deniedForever) {
      if (mounted) {
        ModernFeedback.showError(context, 'Location permission permanently denied');
      }
      return;
    }

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
          _pointCount++;
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
    try {
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
    } catch (e) {
      if (mounted) {
        ModernFeedback.showError(context, 'Failed to load grids: $e');
      }
    }
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
      setState(() {
        _pointMarkers = markers;
        _pointCount = rows.length;
      });
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

    await ModernBottomSheet.show(
      context,
      title: 'Export Survey Data',
      child: StatefulBuilder(
        builder: (ctx, setM) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              left: 16,
              right: 16,
              top: 8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CheckboxListTile(
                  value: selCsv,
                  onChanged: (v) => setM(() => selCsv = v ?? false),
                  title: const Text('CSV (points)'),
                  subtitle: const Text('Comma-separated values format'),
                  dense: true,
                ),
                CheckboxListTile(
                  value: selGeojson,
                  onChanged: (v) => setM(() => selGeojson = v ?? false),
                  title: const Text('GeoJSON (points + grids)'),
                  subtitle: const Text('Geographic JSON format'),
                  dense: true,
                ),
                CheckboxListTile(
                  value: selKml,
                  onChanged: (v) => setM(() => selKml = v ?? false),
                  title: const Text('KML (Google Earth)'),
                  subtitle: const Text('Keyhole Markup Language'),
                  dense: true,
                ),
                CheckboxListTile(
                  value: selWkt,
                  onChanged: (v) => setM(() => selWkt = v ?? false),
                  title: const Text('WKT CSV (Shapefile import)'),
                  subtitle: const Text('Well-Known Text format'),
                  dense: true,
                ),
                const Divider(),
                CheckboxListTile(
                  value: selDb,
                  onChanged: (v) => setM(() => selDb = v ?? false),
                  title: const Text('SQLite DB (geomag.db copy)'),
                  subtitle: const Text('Complete database backup'),
                  dense: true,
                ),
                SwitchListTile(
                  value: makeZip,
                  onChanged: (v) => setM(() => makeZip = v),
                  title: const Text('Package as .zip (if multiple)'),
                  subtitle: const Text('Combine multiple files into archive'),
                  dense: true,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.ios_share),
                        label: const Text('Export'),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _performExport(
                            csv: selCsv,
                            geojson: selGeojson,
                            kml: selKml,
                            wkt: selWkt,
                            db: selDb,
                            zip: makeZip,
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
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
        ModernFeedback.showWarning(context, 'Select at least one format.');
        return;
      }

      // Show progress dialog
      ModernProgressDialog.show(
        context,
        title: 'Exporting Data',
        message: 'Preparing export files...',
      );

      await _exporter.export(
        projectId: widget.projectId,
        kinds: kinds,
        zipIfMultiple: zip,
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // Close progress dialog
      ModernFeedback.showSuccess(context, 'Export completed successfully');
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close progress dialog
      ModernFeedback.showError(context, 'Export failed: $e');
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
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text('Survey Project ${widget.projectId}'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DataAnalysisScreen(
                    projectId: widget.projectId,
                    database: widget.database,
                  ),
                ),
              );
            },
            tooltip: 'View Analysis',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              _showSettingsSheet();
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_pos == null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Waiting for GPS location...',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
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
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 2),
                                  color: Colors.black.withOpacity(0.3),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.navigation,
                              size: 30,
                              color: theme.colorScheme.primary,
                            ),
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
            child: _ModernLegend(
              minV: 20,
              maxV: 70,
              title: 'Total Field (µT)',
              theme: theme,
            ),
          ),

          // Status overlay (top-right)
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 12,
            child: _StatusOverlay(
              theme: theme,
              magneticData: _mag,
              isRecording: _recording,
              pointCount: _pointCount,
              useSatellite: _useSatellite,
              onToggleSatellite: () => setState(() => _useSatellite = !_useSatellite),
              rotate: _rotate,
              onToggleRotate: () {
                setState(() => _rotate = !_rotate);
                if (_follow && _mapReady) _applyFollow();
              },
              follow: _follow,
              onToggleFollow: () => setState(() => _follow = !_follow),
              activeSource: _activeSource,
              onToggleSource: () => _toggleMagnetometerSource(),
            ),
          ),

          // Bottom controls
          Positioned(
            left: 12,
            bottom: 16 + MediaQuery.of(context).padding.bottom,
            child: Row(
              children: [
                _ModernActionButton(
                  icon: Icons.grid_on,
                  label: 'New Grid',
                  onPressed: _showNewGridSheet,
                  theme: theme,
                ),
                const SizedBox(width: 8),
                _ModernActionButton(
                  icon: Icons.ios_share,
                  label: 'Export',
                  onPressed: _showExportSheet,
                  theme: theme,
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
                  _ModernFAB(
                    icon: Icons.center_focus_strong,
                    label: 'Recenter',
                    onPressed: () {
                      setState(() => _follow = true);
                      if (_mapReady) _applyFollow();
                    },
                    theme: theme,
                    heroTag: 'recenter',
                  ),
                const SizedBox(height: 8),
                _ModernFAB(
                  icon: _recording ? Icons.stop : Icons.fiber_manual_record,
                  label: _recording ? 'Stop' : 'Record',
                  onPressed: _toggleRecording,
                  backgroundColor: _recording ? Colors.red : Colors.green,
                  theme: theme,
                  heroTag: 'record',
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
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleRecording() async {
    setState(() => _recording = !_recording);
    
    if (_recording) {
      _lastWrite = null;
      _lastWritePos = null;
      await WakelockPlus.enable(); // keep screen awake
      ModernFeedback.showSuccess(context, 'Recording started');
    } else {
      await WakelockPlus.disable();
      ModernFeedback.showInfo(context, 'Recording stopped - $_pointCount points collected');
    }
  }

  Future<void> _toggleMagnetometerSource() async {
    setState(() {
      _activeSource = (_activeSource == 'phone') ? 'ble' : 'phone';
    });
    
    if (_activeSource == 'phone') {
      _phoneMag.start();
      ModernFeedback.showInfo(context, 'Using phone magnetometer');
    } else {
      await _phoneMag.stop();
      ModernFeedback.showWarning(context, 'External sensor mode (connect BLE device)');
    }
  }

  Future<void> _showSettingsSheet() async {
    await ModernBottomSheet.show(
      context,
      title: 'Survey Settings',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Auto Heading'),
              subtitle: const Text('Use GPS course when moving, compass when stationary'),
              value: _autoHeading,
              onChanged: (v) => setState(() => _autoHeading = v),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About Survey Settings'),
              subtitle: const Text('Configure data collection parameters'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                _showInfoDialog();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog() {
    ModernDialog.show(
      context,
      title: 'Survey Information',
      message: 'This geomagnetic survey tool collects magnetic field measurements with GPS coordinates. Data is automatically filtered for accuracy and spacing.',
      icon: Icons.info,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Got it'),
        ),
      ],
    );
  }

  // ------- New grid sheet -------
  Future<void> _showNewGridSheet() async {
    final name = TextEditingController(text: 'Grid ${DateTime.now().millisecondsSinceEpoch % 1000}');
    final rows = TextEditingController(text: '10');
    final cols = TextEditingController(text: '10');
    final cell = TextEditingController(text: '25');
    final rot = TextEditingController(text: '0');

    await ModernBottomSheet.show(
      context,
      title: 'Create Survey Grid',
      isScrollControlled: true,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(
                labelText: 'Grid Name',
                prefixIcon: Icon(Icons.label_outline),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: rows,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Rows',
                      prefixIcon: Icon(Icons.table_rows),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: cols,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Columns',
                      prefixIcon: Icon(Icons.view_column),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: cell,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Cell size (m)',
                      prefixIcon: Icon(Icons.straighten),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: rot,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Rotation (deg)',
                      prefixIcon: Icon(Icons.rotate_right),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.grid_on),
                label: const Text('Create Grid'),
                onPressed: () async {
                  final gridName = name.text.trim().isEmpty ? 'Grid' : name.text.trim();
                  final c = _pos ?? const LatLng(0, 0);
                  
                  try {
                    await widget.database.createGrid(
                      projectId: widget.projectId,
                      name: gridName,
                      centerLat: c.latitude,
                      centerLon: c.longitude,
                      rows: int.tryParse(rows.text) ?? 10,
                      cols: int.tryParse(cols.text) ?? 10,
                      cellSizeM: double.tryParse(cell.text) ?? 25,
                      rotationDeg: double.tryParse(rot.text) ?? 0,
                    );
                    
                    if (!mounted) return;
                    Navigator.pop(context);
                    await _loadGrids();
                    ModernFeedback.showSuccess(context, 'Grid "$gridName" created');
                  } catch (e) {
                    if (!mounted) return;
                    ModernFeedback.showError(context, 'Failed to create grid: $e');
                  }
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ---------- Modern UI Components ----------

class _ModernLegend extends StatelessWidget {
  final double minV;
  final double maxV;
  final String title;
  final ThemeData theme;

  const _ModernLegend({
    required this.minV,
    required this.maxV,
    required this.title,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 120,
            height: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF3B82F6), // blue
                    Color(0xFF10B981), // green  
                    Color(0xFFF59E0B), // yellow
                    Color(0xFFEF4444), // red
                  ],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${minV.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${maxV.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusOverlay extends StatelessWidget {
  final ThemeData theme;
  final MagVector? magneticData;
  final bool isRecording;
  final int pointCount;
  final bool useSatellite;
  final VoidCallback onToggleSatellite;
  final bool rotate;
  final VoidCallback onToggleRotate;
  final bool follow;
  final VoidCallback onToggleFollow;
  final String activeSource;
  final VoidCallback onToggleSource;

  const _StatusOverlay({
    required this.theme,
    this.magneticData,
    required this.isRecording,
    required this.pointCount,
    required this.useSatellite,
    required this.onToggleSatellite,
    required this.rotate,
    required this.onToggleRotate,
    required this.follow,
    required this.onToggleFollow,
    required this.activeSource,
    required this.onToggleSource,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Recording status
        if (isRecording)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red, Colors.red.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'REC $pointCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        
        const SizedBox(height: 8),
        
        // Control buttons
        _ControlButton(
          icon: useSatellite ? Icons.satellite_alt : Icons.map,
          label: useSatellite ? 'Imagery' : 'Map',
          onTap: onToggleSatellite,
          theme: theme,
        ),
        const SizedBox(height: 8),
        _ControlButton(
          icon: rotate ? Icons.explore : Icons.explore_off,
          label: rotate ? 'Rotate On' : 'Rotate Off',
          onTap: onToggleRotate,
          theme: theme,
        ),
        const SizedBox(height: 8),
        _ControlButton(
          icon: follow ? Icons.my_location : Icons.location_disabled,
          label: follow ? 'Following' : 'Free pan',
          onTap: onToggleFollow,
          theme: theme,
        ),
        const SizedBox(height: 8),
        _ControlButton(
          icon: activeSource == 'phone' ? Icons.phone_android : Icons.sensors,
          label: activeSource == 'phone' ? 'Phone' : 'External',
          onTap: onToggleSource,
          theme: theme,
        ),
        
        const SizedBox(height: 16),
        
        // Magnetic field display
        if (magneticData != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.85),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Magnetic Field',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${magneticData!.mag.toStringAsFixed(1)} µT',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'X:${magneticData!.x.toStringAsFixed(1)} Y:${magneticData!.y.toStringAsFixed(1)} Z:${magneticData!.z.toStringAsFixed(1)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final ThemeData theme;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModernActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final ThemeData theme;

  const _ModernActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.primaryContainer.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: theme.colorScheme.onPrimaryContainer,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModernFAB extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final ThemeData theme;
  final String heroTag;

  const _ModernFAB({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.backgroundColor,
    required this.theme,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? theme.colorScheme.primary;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bgColor, bgColor.withOpacity(0.9)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}