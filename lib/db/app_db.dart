// lib/db/app_db.dart
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

part 'app_db.g.dart';

class Projects extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
}

class Grids extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get projectId => integer().references(Projects, #id)();
  TextColumn get name => text()();
  RealColumn get centerLat => real()();
  RealColumn get centerLon => real()();
  IntColumn get rows => integer()();
  IntColumn get cols => integer()();
  RealColumn get cellSizeM => real()();   // meters
  RealColumn get rotationDeg => real()(); // degrees
}

class Points extends Table {
  IntColumn get id => integer().autoIncrement()();

  // FK
  IntColumn get projectId => integer().references(Projects, #id)();

  // time & position
  DateTimeColumn get ts => dateTime()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  RealColumn get altitude => real()(); // meters

  // magnetic payload
  RealColumn get magneticX => real()();  // µT
  RealColumn get magneticY => real()();  // µT
  RealColumn get magneticZ => real()();  // µT
  RealColumn get totalField => real()(); // µT

  // kinematics & meta
  RealColumn get speedMs => real().nullable()();
  RealColumn get courseDeg => real().nullable()();
  RealColumn get accuracyM => real().nullable()();  // m
  RealColumn get headingDeg => real().nullable()(); // deg
  TextColumn get source => text().nullable()();     // 'phone' | 'ble'
}

@DriftDatabase(tables: [Projects, Grids, Points])
class AppDb extends _$AppDb {
  AppDb() : super(_open());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async => m.createAll(),
    onUpgrade: (m, from, to) async {
      // IMPORTANT: Use generated columns from `points`, not `Points()...`
      if (from < 3) {
        await m.addColumn(points, points.accuracyM);
        await m.addColumn(points, points.source);
      }
      if (from < 4) {
        await m.addColumn(points, points.altitude);
        await m.addColumn(points, points.magneticX);
        await m.addColumn(points, points.magneticY);
        await m.addColumn(points, points.magneticZ);
        await m.addColumn(points, points.totalField);
        await m.addColumn(points, points.headingDeg);
      }
    },
  );

  // ----------------- PROJECTS -----------------
  Future<int> createProject(String name) =>
      into(projects).insert(ProjectsCompanion.insert(name: name));
      
  Future<List<Project>> listProjects() => select(projects).get();

  // FIXED: Proper transaction implementation for deleteProject
  Future<void> deleteProject(int projectId) async {
    await transaction(() async {
      // Delete all points for this project first
      await (delete(points)..where((p) => p.projectId.equals(projectId))).go();
      
      // Delete all grids for this project
      await (delete(grids)..where((g) => g.projectId.equals(projectId))).go();
      
      // Finally delete the project itself
      await (delete(projects)..where((p) => p.id.equals(projectId))).go();
    });
  }

  // ------------------ GRIDS -------------------
  Future<int> createGrid({
    required int projectId,
    required String name,
    required double centerLat,
    required double centerLon,
    required int rows,
    required int cols,
    required double cellSizeM,
    required double rotationDeg,
  }) {
    return into(grids).insert(GridsCompanion.insert(
      projectId: projectId,
      name: name,
      centerLat: centerLat,
      centerLon: centerLon,
      rows: rows,
      cols: cols,
      cellSizeM: cellSizeM,
      rotationDeg: rotationDeg,
    ));
  }

  Future<List<Grid>> listGrids(int projectId) =>
      (select(grids)..where((g) => g.projectId.equals(projectId))).get();

  // ------------------ POINTS ------------------
  Future<int> insertPoint({
    required int projectId,
    required double lat,
    required double lon,
    required double altitude,
    required double magneticX,
    required double magneticY,
    required double magneticZ,
    required double totalField,
    double? courseDeg,
    double? speedMs,
    double? accuracyM,
    double? headingDeg,
    String? source,
  }) {
    return into(points).insert(PointsCompanion.insert(
      projectId: projectId,
      ts: DateTime.now(),
      lat: lat,
      lon: lon,
      altitude: altitude,
      magneticX: magneticX,
      magneticY: magneticY,
      magneticZ: magneticZ,
      totalField: totalField,
      courseDeg: Value(courseDeg),
      speedMs: Value(speedMs),
      accuracyM: Value(accuracyM),
      headingDeg: Value(headingDeg),
      source: Value(source),
    ));
  }

  Future<List<Point>> listPoints(int projectId) =>
      (select(points)
            ..where((p) => p.projectId.equals(projectId))
            ..orderBy([(p) => OrderingTerm.asc(p.ts)]))
          .get();

  Stream<List<Point>> watchPoints(int projectId) =>
      (select(points)
            ..where((p) => p.projectId.equals(projectId))
            ..orderBy([(p) => OrderingTerm.asc(p.ts)]))
          .watch();
}

LazyDatabase _open() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/geomag.db');
    return NativeDatabase.createInBackground(file);
  });
}