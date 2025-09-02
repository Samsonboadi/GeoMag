// lib/services/export_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../db/app_db.dart' as db;

enum ExportKind {
  csvPoints,
  geojsonPointsAndGrids,
  kmlPointsAndGrids,
  wktPointsCsv,
  sqliteDbCopy,
}

class ExportService {
  ExportService(this.database);

  final db.AppDb database;

  /// High-level export: pick any combination of kinds.
  /// If [zipIfMultiple] is true and there is more than one output file, a ZIP is created and shared.
  Future<void> export({
    required int projectId,
    required List<ExportKind> kinds,
    bool zipIfMultiple = false,
  }) async {
    if (kinds.isEmpty) {
      throw Exception('Select at least one export format.');
    }

    final files = <io.File>[];

    for (final k in kinds) {
      switch (k) {
        case ExportKind.csvPoints:
          files.add(await _exportPointsCSV(projectId));
          break;
        case ExportKind.geojsonPointsAndGrids:
          files.add(await _exportGeoJson(projectId));
          break;
        case ExportKind.kmlPointsAndGrids:
          files.add(await _exportKML(projectId));
          break;
        case ExportKind.wktPointsCsv:
          files.add(await _exportWktCsv(projectId));
          break;
        case ExportKind.sqliteDbCopy:
          files.add(await _exportDatabaseCopy());
          break;
      }
    }

    if (files.isEmpty) {
      throw Exception('Nothing to export.');
    }

    if (zipIfMultiple && files.length > 1) {
      final zip = await _zipFiles(projectId, files);
      await _shareFiles([zip]);
    } else {
      await _shareFiles(files);
    }
  }

  // ---------------- Paths & helpers ----------------

  Future<io.Directory> _exportsRoot() async {
    final dir = await getApplicationDocumentsDirectory();
    final root = io.Directory('${dir.path}/exports');
    if (!await root.exists()) await root.create(recursive: true);
    return root;
  }

  Future<io.Directory> _projectExportDir(int projectId) async {
    final root = await _exportsRoot();
    final stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '')
        .replaceAll('.', '');
    final dir = io.Directory('${root.path}/project_$projectId$stamp');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<void> _shareFiles(List<io.File> files) async {
    if (kIsWeb) {
      // On web, share raw text is more reliable; but we’re primarily targeting mobile.
      // For now, fall back to sharing as attachments where supported.
      await Share.shareXFiles(files.map((f) => XFile(f.path)).toList());
      return;
    }
    await Share.shareXFiles(
      files.map((f) => XFile(f.path)).toList(),
      subject: 'GeoMag export',
    );
  }

  Future<io.File> _zipFiles(int projectId, List<io.File> files) async {
    final dir = await _projectExportDir(projectId);
    final zipFile = io.File('${dir.path}/geomag_export.zip');
    final encoder = ZipFileEncoder()..create(zipFile.path);
    for (final f in files) {
      encoder.addFile(f);
    }
    encoder.close();
    return zipFile;
  }

  // ---------------- CSV (points) ----------------

  Future<io.File> _exportPointsCSV(int projectId) async {
    final dir = await _projectExportDir(projectId);
    final file = io.File('${dir.path}/points_$projectId.csv');
    final pts = await database.listPoints(projectId);

    final sink = file.openWrite();
    sink.writeln(
        'id,timestamp,lat,lon,altitude,magX,magY,magZ,totalField,speedMs,courseDeg,accuracyM,headingDeg,source');
    for (final p in pts) {
      sink.writeln(
          '${p.id},${p.ts.toIso8601String()},${p.lat},${p.lon},${p.altitude},'
          '${p.magneticX},${p.magneticY},${p.magneticZ},${p.totalField},'
          '${p.speedMs ?? ''},${p.courseDeg ?? ''},${p.accuracyM ?? ''},${p.headingDeg ?? ''},${p.source ?? ''}');
    }
    await sink.flush();
    await sink.close();
    return file;
  }

  // ---------------- GeoJSON (points + grids) ----------------

  Future<io.File> _exportGeoJson(int projectId) async {
    final dir = await _projectExportDir(projectId);
    final file = io.File('${dir.path}/geomag_$projectId.geojson');

    final pts = await database.listPoints(projectId);
    final grids = await database.listGrids(projectId);

    final features = <Map<String, dynamic>>[];

    // Points (Point geometry)
    for (final p in pts) {
      features.add({
        'type': 'Feature',
        'properties': {
          'id': p.id,
          'timestamp': p.ts.toIso8601String(),
          'altitude': p.altitude,
          'magX': p.magneticX,
          'magY': p.magneticY,
          'magZ': p.magneticZ,
          'totalField': p.totalField,
          'speedMs': p.speedMs,
          'courseDeg': p.courseDeg,
          'accuracyM': p.accuracyM,
          'headingDeg': p.headingDeg,
          'source': p.source,
        },
        'geometry': {
          'type': 'Point',
          'coordinates': [p.lon, p.lat, p.altitude]
        }
      });
    }

    // Grids (as LineStrings for layout — corners only; these are not stored in DB,
    // so we export as center + parameters for reproducibility, and fake box edges).
    // If you later persist full grid corner coords, replace this section accordingly.
    for (final g in grids) {
      features.add({
        'type': 'Feature',
        'properties': {
          'grid_id': g.id,
          'name': g.name,
          'centerLat': g.centerLat,
          'centerLon': g.centerLon,
          'rows': g.rows,
          'cols': g.cols,
          'cellSizeM': g.cellSizeM,
          'rotationDeg': g.rotationDeg,
          'type': 'survey_grid',
        },
        'geometry': {
          'type': 'Point',
          'coordinates': [g.centerLon, g.centerLat]
        }
      });
    }

    final fc = {
      'type': 'FeatureCollection',
      'crs': {
        'type': 'name',
        'properties': {'name': 'EPSG:4326'}
      },
      'features': features,
    };

    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(fc));
    return file;
  }

  // ---------------- KML (points + grids summary) ----------------

  Future<io.File> _exportKML(int projectId) async {
    final dir = await _projectExportDir(projectId);
    final file = io.File('${dir.path}/geomag_$projectId.kml');

    final pts = await database.listPoints(projectId);
    final grids = await database.listGrids(projectId);

    final b = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln('<kml xmlns="http://www.opengis.net/kml/2.2"><Document>')
      ..writeln('<name>GeoMag Project $projectId</name>')
      ..writeln(
          '<Style id="point"><IconStyle><color>ff00ff00</color><scale>0.9</scale></IconStyle></Style>')
      ..writeln(
          '<Style id="grid"><IconStyle><color>ffff0000</color><scale>0.9</scale></IconStyle></Style>');

    if (pts.isNotEmpty) {
      b.writeln('<Folder><name>Points</name>');
      for (final p in pts) {
        b
          ..writeln('<Placemark>')
          ..writeln('<name>Pt ${p.id}</name>')
          ..writeln('<styleUrl>#point</styleUrl>')
          ..writeln('<description><![CDATA['
              'Total: ${p.totalField.toStringAsFixed(1)} µT<br/>'
              'X:${p.magneticX.toStringAsFixed(1)} '
              'Y:${p.magneticY.toStringAsFixed(1)} '
              'Z:${p.magneticZ.toStringAsFixed(1)}<br/>'
              'Acc: ±${(p.accuracyM ?? 0).toStringAsFixed(1)} m<br/>'
              'Time: ${p.ts.toIso8601String()}'
              ']]></description>')
          ..writeln(
              '<Point><coordinates>${p.lon},${p.lat},${p.altitude}</coordinates></Point>')
          ..writeln('</Placemark>');
      }
      b.writeln('</Folder>');
    }

    if (grids.isNotEmpty) {
      b.writeln('<Folder><name>Grids (centers)</name>');
      for (final g in grids) {
        b
          ..writeln('<Placemark>')
          ..writeln('<name>${_escape(g.name)}</name>')
          ..writeln('<styleUrl>#grid</styleUrl>')
          ..writeln('<description><![CDATA['
              'rows:${g.rows}, cols:${g.cols}, cell:${g.cellSizeM} m, rot:${g.rotationDeg}°'
              ']]></description>')
          ..writeln(
              '<Point><coordinates>${g.centerLon},${g.centerLat},0</coordinates></Point>')
          ..writeln('</Placemark>');
      }
      b.writeln('</Folder>');
    }

    b.writeln('</Document></kml>');
    await file.writeAsString(b.toString(), encoding: utf8);
    return file;
  }

  // ---------------- WKT CSV (points) ----------------

  Future<io.File> _exportWktCsv(int projectId) async {
    final dir = await _projectExportDir(projectId);
    final file = io.File('${dir.path}/wkt_points_$projectId.csv');
    final pts = await database.listPoints(projectId);

    final b = StringBuffer()
      ..writeln('# WKT CSV (EPSG:4326)')
      ..writeln(
          'WKT,ID,TIMESTAMP,LAT,LON,ALT,MagX,MagY,MagZ,Total,SpeedMs,CourseDeg,AccuracyM,HeadingDeg,Source');

    for (final p in pts) {
      b.writeln(
          '"POINTZ(${p.lon} ${p.lat} ${p.altitude})",${p.id},${p.ts.toIso8601String()},'
          '${p.lat},${p.lon},${p.altitude},'
          '${p.magneticX},${p.magneticY},${p.magneticZ},${p.totalField},'
          '${p.speedMs ?? ''},${p.courseDeg ?? ''},${p.accuracyM ?? ''},${p.headingDeg ?? ''},${p.source ?? ''}');
    }

    await file.writeAsString(b.toString(), encoding: utf8);
    return file;
  }

  // ---------------- SQLite DB copy ----------------

  Future<io.File> _exportDatabaseCopy() async {
    final docs = await getApplicationDocumentsDirectory();
    final src = io.File('${docs.path}/geomag.db');
    if (!await src.exists()) {
      throw Exception('Database not found at ${src.path}');
    }

    final root = await _exportsRoot();
    final out = io.File(
        '${root.path}/geomag_copy_${DateTime.now().millisecondsSinceEpoch}.db');
    await out.writeAsBytes(await src.readAsBytes(), flush: true);
    return out;
  }

  // ---------------- utils ----------------

  String _escape(String s) =>
      s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
}
