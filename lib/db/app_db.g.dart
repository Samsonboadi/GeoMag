// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_db.dart';

// ignore_for_file: type=lint
class $ProjectsTable extends Projects with TableInfo<$ProjectsTable, Project> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'projects';
  @override
  VerificationContext validateIntegrity(Insertable<Project> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Project map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Project(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
    );
  }

  @override
  $ProjectsTable createAlias(String alias) {
    return $ProjectsTable(attachedDatabase, alias);
  }
}

class Project extends DataClass implements Insertable<Project> {
  final int id;
  final String name;
  const Project({required this.id, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    return map;
  }

  ProjectsCompanion toCompanion(bool nullToAbsent) {
    return ProjectsCompanion(
      id: Value(id),
      name: Value(name),
    );
  }

  factory Project.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Project(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
    };
  }

  Project copyWith({int? id, String? name}) => Project(
        id: id ?? this.id,
        name: name ?? this.name,
      );
  Project copyWithCompanion(ProjectsCompanion data) {
    return Project(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Project(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Project && other.id == this.id && other.name == this.name);
}

class ProjectsCompanion extends UpdateCompanion<Project> {
  final Value<int> id;
  final Value<String> name;
  const ProjectsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
  });
  ProjectsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
  }) : name = Value(name);
  static Insertable<Project> custom({
    Expression<int>? id,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    });
  }

  ProjectsCompanion copyWith({Value<int>? id, Value<String>? name}) {
    return ProjectsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProjectsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class $GridsTable extends Grids with TableInfo<$GridsTable, Grid> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GridsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _projectIdMeta =
      const VerificationMeta('projectId');
  @override
  late final GeneratedColumn<int> projectId = GeneratedColumn<int>(
      'project_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES projects (id)'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _centerLatMeta =
      const VerificationMeta('centerLat');
  @override
  late final GeneratedColumn<double> centerLat = GeneratedColumn<double>(
      'center_lat', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _centerLonMeta =
      const VerificationMeta('centerLon');
  @override
  late final GeneratedColumn<double> centerLon = GeneratedColumn<double>(
      'center_lon', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _rowsMeta = const VerificationMeta('rows');
  @override
  late final GeneratedColumn<int> rows = GeneratedColumn<int>(
      'rows', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _colsMeta = const VerificationMeta('cols');
  @override
  late final GeneratedColumn<int> cols = GeneratedColumn<int>(
      'cols', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _cellSizeMMeta =
      const VerificationMeta('cellSizeM');
  @override
  late final GeneratedColumn<double> cellSizeM = GeneratedColumn<double>(
      'cell_size_m', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _rotationDegMeta =
      const VerificationMeta('rotationDeg');
  @override
  late final GeneratedColumn<double> rotationDeg = GeneratedColumn<double>(
      'rotation_deg', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        projectId,
        name,
        centerLat,
        centerLon,
        rows,
        cols,
        cellSizeM,
        rotationDeg
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'grids';
  @override
  VerificationContext validateIntegrity(Insertable<Grid> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('project_id')) {
      context.handle(_projectIdMeta,
          projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta));
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('center_lat')) {
      context.handle(_centerLatMeta,
          centerLat.isAcceptableOrUnknown(data['center_lat']!, _centerLatMeta));
    } else if (isInserting) {
      context.missing(_centerLatMeta);
    }
    if (data.containsKey('center_lon')) {
      context.handle(_centerLonMeta,
          centerLon.isAcceptableOrUnknown(data['center_lon']!, _centerLonMeta));
    } else if (isInserting) {
      context.missing(_centerLonMeta);
    }
    if (data.containsKey('rows')) {
      context.handle(
          _rowsMeta, rows.isAcceptableOrUnknown(data['rows']!, _rowsMeta));
    } else if (isInserting) {
      context.missing(_rowsMeta);
    }
    if (data.containsKey('cols')) {
      context.handle(
          _colsMeta, cols.isAcceptableOrUnknown(data['cols']!, _colsMeta));
    } else if (isInserting) {
      context.missing(_colsMeta);
    }
    if (data.containsKey('cell_size_m')) {
      context.handle(
          _cellSizeMMeta,
          cellSizeM.isAcceptableOrUnknown(
              data['cell_size_m']!, _cellSizeMMeta));
    } else if (isInserting) {
      context.missing(_cellSizeMMeta);
    }
    if (data.containsKey('rotation_deg')) {
      context.handle(
          _rotationDegMeta,
          rotationDeg.isAcceptableOrUnknown(
              data['rotation_deg']!, _rotationDegMeta));
    } else if (isInserting) {
      context.missing(_rotationDegMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Grid map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Grid(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      projectId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}project_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      centerLat: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}center_lat'])!,
      centerLon: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}center_lon'])!,
      rows: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}rows'])!,
      cols: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}cols'])!,
      cellSizeM: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}cell_size_m'])!,
      rotationDeg: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}rotation_deg'])!,
    );
  }

  @override
  $GridsTable createAlias(String alias) {
    return $GridsTable(attachedDatabase, alias);
  }
}

class Grid extends DataClass implements Insertable<Grid> {
  final int id;
  final int projectId;
  final String name;
  final double centerLat;
  final double centerLon;
  final int rows;
  final int cols;
  final double cellSizeM;
  final double rotationDeg;
  const Grid(
      {required this.id,
      required this.projectId,
      required this.name,
      required this.centerLat,
      required this.centerLon,
      required this.rows,
      required this.cols,
      required this.cellSizeM,
      required this.rotationDeg});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['project_id'] = Variable<int>(projectId);
    map['name'] = Variable<String>(name);
    map['center_lat'] = Variable<double>(centerLat);
    map['center_lon'] = Variable<double>(centerLon);
    map['rows'] = Variable<int>(rows);
    map['cols'] = Variable<int>(cols);
    map['cell_size_m'] = Variable<double>(cellSizeM);
    map['rotation_deg'] = Variable<double>(rotationDeg);
    return map;
  }

  GridsCompanion toCompanion(bool nullToAbsent) {
    return GridsCompanion(
      id: Value(id),
      projectId: Value(projectId),
      name: Value(name),
      centerLat: Value(centerLat),
      centerLon: Value(centerLon),
      rows: Value(rows),
      cols: Value(cols),
      cellSizeM: Value(cellSizeM),
      rotationDeg: Value(rotationDeg),
    );
  }

  factory Grid.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Grid(
      id: serializer.fromJson<int>(json['id']),
      projectId: serializer.fromJson<int>(json['projectId']),
      name: serializer.fromJson<String>(json['name']),
      centerLat: serializer.fromJson<double>(json['centerLat']),
      centerLon: serializer.fromJson<double>(json['centerLon']),
      rows: serializer.fromJson<int>(json['rows']),
      cols: serializer.fromJson<int>(json['cols']),
      cellSizeM: serializer.fromJson<double>(json['cellSizeM']),
      rotationDeg: serializer.fromJson<double>(json['rotationDeg']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'projectId': serializer.toJson<int>(projectId),
      'name': serializer.toJson<String>(name),
      'centerLat': serializer.toJson<double>(centerLat),
      'centerLon': serializer.toJson<double>(centerLon),
      'rows': serializer.toJson<int>(rows),
      'cols': serializer.toJson<int>(cols),
      'cellSizeM': serializer.toJson<double>(cellSizeM),
      'rotationDeg': serializer.toJson<double>(rotationDeg),
    };
  }

  Grid copyWith(
          {int? id,
          int? projectId,
          String? name,
          double? centerLat,
          double? centerLon,
          int? rows,
          int? cols,
          double? cellSizeM,
          double? rotationDeg}) =>
      Grid(
        id: id ?? this.id,
        projectId: projectId ?? this.projectId,
        name: name ?? this.name,
        centerLat: centerLat ?? this.centerLat,
        centerLon: centerLon ?? this.centerLon,
        rows: rows ?? this.rows,
        cols: cols ?? this.cols,
        cellSizeM: cellSizeM ?? this.cellSizeM,
        rotationDeg: rotationDeg ?? this.rotationDeg,
      );
  Grid copyWithCompanion(GridsCompanion data) {
    return Grid(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      name: data.name.present ? data.name.value : this.name,
      centerLat: data.centerLat.present ? data.centerLat.value : this.centerLat,
      centerLon: data.centerLon.present ? data.centerLon.value : this.centerLon,
      rows: data.rows.present ? data.rows.value : this.rows,
      cols: data.cols.present ? data.cols.value : this.cols,
      cellSizeM: data.cellSizeM.present ? data.cellSizeM.value : this.cellSizeM,
      rotationDeg:
          data.rotationDeg.present ? data.rotationDeg.value : this.rotationDeg,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Grid(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('name: $name, ')
          ..write('centerLat: $centerLat, ')
          ..write('centerLon: $centerLon, ')
          ..write('rows: $rows, ')
          ..write('cols: $cols, ')
          ..write('cellSizeM: $cellSizeM, ')
          ..write('rotationDeg: $rotationDeg')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, projectId, name, centerLat, centerLon,
      rows, cols, cellSizeM, rotationDeg);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Grid &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.name == this.name &&
          other.centerLat == this.centerLat &&
          other.centerLon == this.centerLon &&
          other.rows == this.rows &&
          other.cols == this.cols &&
          other.cellSizeM == this.cellSizeM &&
          other.rotationDeg == this.rotationDeg);
}

class GridsCompanion extends UpdateCompanion<Grid> {
  final Value<int> id;
  final Value<int> projectId;
  final Value<String> name;
  final Value<double> centerLat;
  final Value<double> centerLon;
  final Value<int> rows;
  final Value<int> cols;
  final Value<double> cellSizeM;
  final Value<double> rotationDeg;
  const GridsCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.name = const Value.absent(),
    this.centerLat = const Value.absent(),
    this.centerLon = const Value.absent(),
    this.rows = const Value.absent(),
    this.cols = const Value.absent(),
    this.cellSizeM = const Value.absent(),
    this.rotationDeg = const Value.absent(),
  });
  GridsCompanion.insert({
    this.id = const Value.absent(),
    required int projectId,
    required String name,
    required double centerLat,
    required double centerLon,
    required int rows,
    required int cols,
    required double cellSizeM,
    required double rotationDeg,
  })  : projectId = Value(projectId),
        name = Value(name),
        centerLat = Value(centerLat),
        centerLon = Value(centerLon),
        rows = Value(rows),
        cols = Value(cols),
        cellSizeM = Value(cellSizeM),
        rotationDeg = Value(rotationDeg);
  static Insertable<Grid> custom({
    Expression<int>? id,
    Expression<int>? projectId,
    Expression<String>? name,
    Expression<double>? centerLat,
    Expression<double>? centerLon,
    Expression<int>? rows,
    Expression<int>? cols,
    Expression<double>? cellSizeM,
    Expression<double>? rotationDeg,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (name != null) 'name': name,
      if (centerLat != null) 'center_lat': centerLat,
      if (centerLon != null) 'center_lon': centerLon,
      if (rows != null) 'rows': rows,
      if (cols != null) 'cols': cols,
      if (cellSizeM != null) 'cell_size_m': cellSizeM,
      if (rotationDeg != null) 'rotation_deg': rotationDeg,
    });
  }

  GridsCompanion copyWith(
      {Value<int>? id,
      Value<int>? projectId,
      Value<String>? name,
      Value<double>? centerLat,
      Value<double>? centerLon,
      Value<int>? rows,
      Value<int>? cols,
      Value<double>? cellSizeM,
      Value<double>? rotationDeg}) {
    return GridsCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      centerLat: centerLat ?? this.centerLat,
      centerLon: centerLon ?? this.centerLon,
      rows: rows ?? this.rows,
      cols: cols ?? this.cols,
      cellSizeM: cellSizeM ?? this.cellSizeM,
      rotationDeg: rotationDeg ?? this.rotationDeg,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<int>(projectId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (centerLat.present) {
      map['center_lat'] = Variable<double>(centerLat.value);
    }
    if (centerLon.present) {
      map['center_lon'] = Variable<double>(centerLon.value);
    }
    if (rows.present) {
      map['rows'] = Variable<int>(rows.value);
    }
    if (cols.present) {
      map['cols'] = Variable<int>(cols.value);
    }
    if (cellSizeM.present) {
      map['cell_size_m'] = Variable<double>(cellSizeM.value);
    }
    if (rotationDeg.present) {
      map['rotation_deg'] = Variable<double>(rotationDeg.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GridsCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('name: $name, ')
          ..write('centerLat: $centerLat, ')
          ..write('centerLon: $centerLon, ')
          ..write('rows: $rows, ')
          ..write('cols: $cols, ')
          ..write('cellSizeM: $cellSizeM, ')
          ..write('rotationDeg: $rotationDeg')
          ..write(')'))
        .toString();
  }
}

class $PointsTable extends Points with TableInfo<$PointsTable, Point> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _projectIdMeta =
      const VerificationMeta('projectId');
  @override
  late final GeneratedColumn<int> projectId = GeneratedColumn<int>(
      'project_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES projects (id)'));
  static const VerificationMeta _tsMeta = const VerificationMeta('ts');
  @override
  late final GeneratedColumn<DateTime> ts = GeneratedColumn<DateTime>(
      'ts', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
      'lat', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _lonMeta = const VerificationMeta('lon');
  @override
  late final GeneratedColumn<double> lon = GeneratedColumn<double>(
      'lon', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _altitudeMeta =
      const VerificationMeta('altitude');
  @override
  late final GeneratedColumn<double> altitude = GeneratedColumn<double>(
      'altitude', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _magneticXMeta =
      const VerificationMeta('magneticX');
  @override
  late final GeneratedColumn<double> magneticX = GeneratedColumn<double>(
      'magnetic_x', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _magneticYMeta =
      const VerificationMeta('magneticY');
  @override
  late final GeneratedColumn<double> magneticY = GeneratedColumn<double>(
      'magnetic_y', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _magneticZMeta =
      const VerificationMeta('magneticZ');
  @override
  late final GeneratedColumn<double> magneticZ = GeneratedColumn<double>(
      'magnetic_z', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _totalFieldMeta =
      const VerificationMeta('totalField');
  @override
  late final GeneratedColumn<double> totalField = GeneratedColumn<double>(
      'total_field', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _speedMsMeta =
      const VerificationMeta('speedMs');
  @override
  late final GeneratedColumn<double> speedMs = GeneratedColumn<double>(
      'speed_ms', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _courseDegMeta =
      const VerificationMeta('courseDeg');
  @override
  late final GeneratedColumn<double> courseDeg = GeneratedColumn<double>(
      'course_deg', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _accuracyMMeta =
      const VerificationMeta('accuracyM');
  @override
  late final GeneratedColumn<double> accuracyM = GeneratedColumn<double>(
      'accuracy_m', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _headingDegMeta =
      const VerificationMeta('headingDeg');
  @override
  late final GeneratedColumn<double> headingDeg = GeneratedColumn<double>(
      'heading_deg', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        projectId,
        ts,
        lat,
        lon,
        altitude,
        magneticX,
        magneticY,
        magneticZ,
        totalField,
        speedMs,
        courseDeg,
        accuracyM,
        headingDeg,
        source
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'points';
  @override
  VerificationContext validateIntegrity(Insertable<Point> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('project_id')) {
      context.handle(_projectIdMeta,
          projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta));
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('ts')) {
      context.handle(_tsMeta, ts.isAcceptableOrUnknown(data['ts']!, _tsMeta));
    } else if (isInserting) {
      context.missing(_tsMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(
          _latMeta, lat.isAcceptableOrUnknown(data['lat']!, _latMeta));
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lon')) {
      context.handle(
          _lonMeta, lon.isAcceptableOrUnknown(data['lon']!, _lonMeta));
    } else if (isInserting) {
      context.missing(_lonMeta);
    }
    if (data.containsKey('altitude')) {
      context.handle(_altitudeMeta,
          altitude.isAcceptableOrUnknown(data['altitude']!, _altitudeMeta));
    } else if (isInserting) {
      context.missing(_altitudeMeta);
    }
    if (data.containsKey('magnetic_x')) {
      context.handle(_magneticXMeta,
          magneticX.isAcceptableOrUnknown(data['magnetic_x']!, _magneticXMeta));
    } else if (isInserting) {
      context.missing(_magneticXMeta);
    }
    if (data.containsKey('magnetic_y')) {
      context.handle(_magneticYMeta,
          magneticY.isAcceptableOrUnknown(data['magnetic_y']!, _magneticYMeta));
    } else if (isInserting) {
      context.missing(_magneticYMeta);
    }
    if (data.containsKey('magnetic_z')) {
      context.handle(_magneticZMeta,
          magneticZ.isAcceptableOrUnknown(data['magnetic_z']!, _magneticZMeta));
    } else if (isInserting) {
      context.missing(_magneticZMeta);
    }
    if (data.containsKey('total_field')) {
      context.handle(
          _totalFieldMeta,
          totalField.isAcceptableOrUnknown(
              data['total_field']!, _totalFieldMeta));
    } else if (isInserting) {
      context.missing(_totalFieldMeta);
    }
    if (data.containsKey('speed_ms')) {
      context.handle(_speedMsMeta,
          speedMs.isAcceptableOrUnknown(data['speed_ms']!, _speedMsMeta));
    }
    if (data.containsKey('course_deg')) {
      context.handle(_courseDegMeta,
          courseDeg.isAcceptableOrUnknown(data['course_deg']!, _courseDegMeta));
    }
    if (data.containsKey('accuracy_m')) {
      context.handle(_accuracyMMeta,
          accuracyM.isAcceptableOrUnknown(data['accuracy_m']!, _accuracyMMeta));
    }
    if (data.containsKey('heading_deg')) {
      context.handle(
          _headingDegMeta,
          headingDeg.isAcceptableOrUnknown(
              data['heading_deg']!, _headingDegMeta));
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Point map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Point(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      projectId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}project_id'])!,
      ts: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}ts'])!,
      lat: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}lat'])!,
      lon: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}lon'])!,
      altitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}altitude'])!,
      magneticX: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}magnetic_x'])!,
      magneticY: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}magnetic_y'])!,
      magneticZ: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}magnetic_z'])!,
      totalField: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total_field'])!,
      speedMs: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}speed_ms']),
      courseDeg: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}course_deg']),
      accuracyM: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}accuracy_m']),
      headingDeg: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}heading_deg']),
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source']),
    );
  }

  @override
  $PointsTable createAlias(String alias) {
    return $PointsTable(attachedDatabase, alias);
  }
}

class Point extends DataClass implements Insertable<Point> {
  final int id;
  final int projectId;
  final DateTime ts;
  final double lat;
  final double lon;
  final double altitude;
  final double magneticX;
  final double magneticY;
  final double magneticZ;
  final double totalField;
  final double? speedMs;
  final double? courseDeg;
  final double? accuracyM;
  final double? headingDeg;
  final String? source;
  const Point(
      {required this.id,
      required this.projectId,
      required this.ts,
      required this.lat,
      required this.lon,
      required this.altitude,
      required this.magneticX,
      required this.magneticY,
      required this.magneticZ,
      required this.totalField,
      this.speedMs,
      this.courseDeg,
      this.accuracyM,
      this.headingDeg,
      this.source});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['project_id'] = Variable<int>(projectId);
    map['ts'] = Variable<DateTime>(ts);
    map['lat'] = Variable<double>(lat);
    map['lon'] = Variable<double>(lon);
    map['altitude'] = Variable<double>(altitude);
    map['magnetic_x'] = Variable<double>(magneticX);
    map['magnetic_y'] = Variable<double>(magneticY);
    map['magnetic_z'] = Variable<double>(magneticZ);
    map['total_field'] = Variable<double>(totalField);
    if (!nullToAbsent || speedMs != null) {
      map['speed_ms'] = Variable<double>(speedMs);
    }
    if (!nullToAbsent || courseDeg != null) {
      map['course_deg'] = Variable<double>(courseDeg);
    }
    if (!nullToAbsent || accuracyM != null) {
      map['accuracy_m'] = Variable<double>(accuracyM);
    }
    if (!nullToAbsent || headingDeg != null) {
      map['heading_deg'] = Variable<double>(headingDeg);
    }
    if (!nullToAbsent || source != null) {
      map['source'] = Variable<String>(source);
    }
    return map;
  }

  PointsCompanion toCompanion(bool nullToAbsent) {
    return PointsCompanion(
      id: Value(id),
      projectId: Value(projectId),
      ts: Value(ts),
      lat: Value(lat),
      lon: Value(lon),
      altitude: Value(altitude),
      magneticX: Value(magneticX),
      magneticY: Value(magneticY),
      magneticZ: Value(magneticZ),
      totalField: Value(totalField),
      speedMs: speedMs == null && nullToAbsent
          ? const Value.absent()
          : Value(speedMs),
      courseDeg: courseDeg == null && nullToAbsent
          ? const Value.absent()
          : Value(courseDeg),
      accuracyM: accuracyM == null && nullToAbsent
          ? const Value.absent()
          : Value(accuracyM),
      headingDeg: headingDeg == null && nullToAbsent
          ? const Value.absent()
          : Value(headingDeg),
      source:
          source == null && nullToAbsent ? const Value.absent() : Value(source),
    );
  }

  factory Point.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Point(
      id: serializer.fromJson<int>(json['id']),
      projectId: serializer.fromJson<int>(json['projectId']),
      ts: serializer.fromJson<DateTime>(json['ts']),
      lat: serializer.fromJson<double>(json['lat']),
      lon: serializer.fromJson<double>(json['lon']),
      altitude: serializer.fromJson<double>(json['altitude']),
      magneticX: serializer.fromJson<double>(json['magneticX']),
      magneticY: serializer.fromJson<double>(json['magneticY']),
      magneticZ: serializer.fromJson<double>(json['magneticZ']),
      totalField: serializer.fromJson<double>(json['totalField']),
      speedMs: serializer.fromJson<double?>(json['speedMs']),
      courseDeg: serializer.fromJson<double?>(json['courseDeg']),
      accuracyM: serializer.fromJson<double?>(json['accuracyM']),
      headingDeg: serializer.fromJson<double?>(json['headingDeg']),
      source: serializer.fromJson<String?>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'projectId': serializer.toJson<int>(projectId),
      'ts': serializer.toJson<DateTime>(ts),
      'lat': serializer.toJson<double>(lat),
      'lon': serializer.toJson<double>(lon),
      'altitude': serializer.toJson<double>(altitude),
      'magneticX': serializer.toJson<double>(magneticX),
      'magneticY': serializer.toJson<double>(magneticY),
      'magneticZ': serializer.toJson<double>(magneticZ),
      'totalField': serializer.toJson<double>(totalField),
      'speedMs': serializer.toJson<double?>(speedMs),
      'courseDeg': serializer.toJson<double?>(courseDeg),
      'accuracyM': serializer.toJson<double?>(accuracyM),
      'headingDeg': serializer.toJson<double?>(headingDeg),
      'source': serializer.toJson<String?>(source),
    };
  }

  Point copyWith(
          {int? id,
          int? projectId,
          DateTime? ts,
          double? lat,
          double? lon,
          double? altitude,
          double? magneticX,
          double? magneticY,
          double? magneticZ,
          double? totalField,
          Value<double?> speedMs = const Value.absent(),
          Value<double?> courseDeg = const Value.absent(),
          Value<double?> accuracyM = const Value.absent(),
          Value<double?> headingDeg = const Value.absent(),
          Value<String?> source = const Value.absent()}) =>
      Point(
        id: id ?? this.id,
        projectId: projectId ?? this.projectId,
        ts: ts ?? this.ts,
        lat: lat ?? this.lat,
        lon: lon ?? this.lon,
        altitude: altitude ?? this.altitude,
        magneticX: magneticX ?? this.magneticX,
        magneticY: magneticY ?? this.magneticY,
        magneticZ: magneticZ ?? this.magneticZ,
        totalField: totalField ?? this.totalField,
        speedMs: speedMs.present ? speedMs.value : this.speedMs,
        courseDeg: courseDeg.present ? courseDeg.value : this.courseDeg,
        accuracyM: accuracyM.present ? accuracyM.value : this.accuracyM,
        headingDeg: headingDeg.present ? headingDeg.value : this.headingDeg,
        source: source.present ? source.value : this.source,
      );
  Point copyWithCompanion(PointsCompanion data) {
    return Point(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      ts: data.ts.present ? data.ts.value : this.ts,
      lat: data.lat.present ? data.lat.value : this.lat,
      lon: data.lon.present ? data.lon.value : this.lon,
      altitude: data.altitude.present ? data.altitude.value : this.altitude,
      magneticX: data.magneticX.present ? data.magneticX.value : this.magneticX,
      magneticY: data.magneticY.present ? data.magneticY.value : this.magneticY,
      magneticZ: data.magneticZ.present ? data.magneticZ.value : this.magneticZ,
      totalField:
          data.totalField.present ? data.totalField.value : this.totalField,
      speedMs: data.speedMs.present ? data.speedMs.value : this.speedMs,
      courseDeg: data.courseDeg.present ? data.courseDeg.value : this.courseDeg,
      accuracyM: data.accuracyM.present ? data.accuracyM.value : this.accuracyM,
      headingDeg:
          data.headingDeg.present ? data.headingDeg.value : this.headingDeg,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Point(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('ts: $ts, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('altitude: $altitude, ')
          ..write('magneticX: $magneticX, ')
          ..write('magneticY: $magneticY, ')
          ..write('magneticZ: $magneticZ, ')
          ..write('totalField: $totalField, ')
          ..write('speedMs: $speedMs, ')
          ..write('courseDeg: $courseDeg, ')
          ..write('accuracyM: $accuracyM, ')
          ..write('headingDeg: $headingDeg, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      projectId,
      ts,
      lat,
      lon,
      altitude,
      magneticX,
      magneticY,
      magneticZ,
      totalField,
      speedMs,
      courseDeg,
      accuracyM,
      headingDeg,
      source);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Point &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.ts == this.ts &&
          other.lat == this.lat &&
          other.lon == this.lon &&
          other.altitude == this.altitude &&
          other.magneticX == this.magneticX &&
          other.magneticY == this.magneticY &&
          other.magneticZ == this.magneticZ &&
          other.totalField == this.totalField &&
          other.speedMs == this.speedMs &&
          other.courseDeg == this.courseDeg &&
          other.accuracyM == this.accuracyM &&
          other.headingDeg == this.headingDeg &&
          other.source == this.source);
}

class PointsCompanion extends UpdateCompanion<Point> {
  final Value<int> id;
  final Value<int> projectId;
  final Value<DateTime> ts;
  final Value<double> lat;
  final Value<double> lon;
  final Value<double> altitude;
  final Value<double> magneticX;
  final Value<double> magneticY;
  final Value<double> magneticZ;
  final Value<double> totalField;
  final Value<double?> speedMs;
  final Value<double?> courseDeg;
  final Value<double?> accuracyM;
  final Value<double?> headingDeg;
  final Value<String?> source;
  const PointsCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.ts = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
    this.altitude = const Value.absent(),
    this.magneticX = const Value.absent(),
    this.magneticY = const Value.absent(),
    this.magneticZ = const Value.absent(),
    this.totalField = const Value.absent(),
    this.speedMs = const Value.absent(),
    this.courseDeg = const Value.absent(),
    this.accuracyM = const Value.absent(),
    this.headingDeg = const Value.absent(),
    this.source = const Value.absent(),
  });
  PointsCompanion.insert({
    this.id = const Value.absent(),
    required int projectId,
    required DateTime ts,
    required double lat,
    required double lon,
    required double altitude,
    required double magneticX,
    required double magneticY,
    required double magneticZ,
    required double totalField,
    this.speedMs = const Value.absent(),
    this.courseDeg = const Value.absent(),
    this.accuracyM = const Value.absent(),
    this.headingDeg = const Value.absent(),
    this.source = const Value.absent(),
  })  : projectId = Value(projectId),
        ts = Value(ts),
        lat = Value(lat),
        lon = Value(lon),
        altitude = Value(altitude),
        magneticX = Value(magneticX),
        magneticY = Value(magneticY),
        magneticZ = Value(magneticZ),
        totalField = Value(totalField);
  static Insertable<Point> custom({
    Expression<int>? id,
    Expression<int>? projectId,
    Expression<DateTime>? ts,
    Expression<double>? lat,
    Expression<double>? lon,
    Expression<double>? altitude,
    Expression<double>? magneticX,
    Expression<double>? magneticY,
    Expression<double>? magneticZ,
    Expression<double>? totalField,
    Expression<double>? speedMs,
    Expression<double>? courseDeg,
    Expression<double>? accuracyM,
    Expression<double>? headingDeg,
    Expression<String>? source,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (ts != null) 'ts': ts,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      if (altitude != null) 'altitude': altitude,
      if (magneticX != null) 'magnetic_x': magneticX,
      if (magneticY != null) 'magnetic_y': magneticY,
      if (magneticZ != null) 'magnetic_z': magneticZ,
      if (totalField != null) 'total_field': totalField,
      if (speedMs != null) 'speed_ms': speedMs,
      if (courseDeg != null) 'course_deg': courseDeg,
      if (accuracyM != null) 'accuracy_m': accuracyM,
      if (headingDeg != null) 'heading_deg': headingDeg,
      if (source != null) 'source': source,
    });
  }

  PointsCompanion copyWith(
      {Value<int>? id,
      Value<int>? projectId,
      Value<DateTime>? ts,
      Value<double>? lat,
      Value<double>? lon,
      Value<double>? altitude,
      Value<double>? magneticX,
      Value<double>? magneticY,
      Value<double>? magneticZ,
      Value<double>? totalField,
      Value<double?>? speedMs,
      Value<double?>? courseDeg,
      Value<double?>? accuracyM,
      Value<double?>? headingDeg,
      Value<String?>? source}) {
    return PointsCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      ts: ts ?? this.ts,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      altitude: altitude ?? this.altitude,
      magneticX: magneticX ?? this.magneticX,
      magneticY: magneticY ?? this.magneticY,
      magneticZ: magneticZ ?? this.magneticZ,
      totalField: totalField ?? this.totalField,
      speedMs: speedMs ?? this.speedMs,
      courseDeg: courseDeg ?? this.courseDeg,
      accuracyM: accuracyM ?? this.accuracyM,
      headingDeg: headingDeg ?? this.headingDeg,
      source: source ?? this.source,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<int>(projectId.value);
    }
    if (ts.present) {
      map['ts'] = Variable<DateTime>(ts.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lon.present) {
      map['lon'] = Variable<double>(lon.value);
    }
    if (altitude.present) {
      map['altitude'] = Variable<double>(altitude.value);
    }
    if (magneticX.present) {
      map['magnetic_x'] = Variable<double>(magneticX.value);
    }
    if (magneticY.present) {
      map['magnetic_y'] = Variable<double>(magneticY.value);
    }
    if (magneticZ.present) {
      map['magnetic_z'] = Variable<double>(magneticZ.value);
    }
    if (totalField.present) {
      map['total_field'] = Variable<double>(totalField.value);
    }
    if (speedMs.present) {
      map['speed_ms'] = Variable<double>(speedMs.value);
    }
    if (courseDeg.present) {
      map['course_deg'] = Variable<double>(courseDeg.value);
    }
    if (accuracyM.present) {
      map['accuracy_m'] = Variable<double>(accuracyM.value);
    }
    if (headingDeg.present) {
      map['heading_deg'] = Variable<double>(headingDeg.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PointsCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('ts: $ts, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('altitude: $altitude, ')
          ..write('magneticX: $magneticX, ')
          ..write('magneticY: $magneticY, ')
          ..write('magneticZ: $magneticZ, ')
          ..write('totalField: $totalField, ')
          ..write('speedMs: $speedMs, ')
          ..write('courseDeg: $courseDeg, ')
          ..write('accuracyM: $accuracyM, ')
          ..write('headingDeg: $headingDeg, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDb extends GeneratedDatabase {
  _$AppDb(QueryExecutor e) : super(e);
  $AppDbManager get managers => $AppDbManager(this);
  late final $ProjectsTable projects = $ProjectsTable(this);
  late final $GridsTable grids = $GridsTable(this);
  late final $PointsTable points = $PointsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [projects, grids, points];
}

typedef $$ProjectsTableCreateCompanionBuilder = ProjectsCompanion Function({
  Value<int> id,
  required String name,
});
typedef $$ProjectsTableUpdateCompanionBuilder = ProjectsCompanion Function({
  Value<int> id,
  Value<String> name,
});

final class $$ProjectsTableReferences
    extends BaseReferences<_$AppDb, $ProjectsTable, Project> {
  $$ProjectsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$GridsTable, List<Grid>> _gridsRefsTable(
          _$AppDb db) =>
      MultiTypedResultKey.fromTable(db.grids,
          aliasName: $_aliasNameGenerator(db.projects.id, db.grids.projectId));

  $$GridsTableProcessedTableManager get gridsRefs {
    final manager = $$GridsTableTableManager($_db, $_db.grids)
        .filter((f) => f.projectId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_gridsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$PointsTable, List<Point>> _pointsRefsTable(
          _$AppDb db) =>
      MultiTypedResultKey.fromTable(db.points,
          aliasName: $_aliasNameGenerator(db.projects.id, db.points.projectId));

  $$PointsTableProcessedTableManager get pointsRefs {
    final manager = $$PointsTableTableManager($_db, $_db.points)
        .filter((f) => f.projectId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_pointsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ProjectsTableFilterComposer extends Composer<_$AppDb, $ProjectsTable> {
  $$ProjectsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  Expression<bool> gridsRefs(
      Expression<bool> Function($$GridsTableFilterComposer f) f) {
    final $$GridsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.grids,
        getReferencedColumn: (t) => t.projectId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GridsTableFilterComposer(
              $db: $db,
              $table: $db.grids,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> pointsRefs(
      Expression<bool> Function($$PointsTableFilterComposer f) f) {
    final $$PointsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.points,
        getReferencedColumn: (t) => t.projectId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PointsTableFilterComposer(
              $db: $db,
              $table: $db.points,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ProjectsTableOrderingComposer
    extends Composer<_$AppDb, $ProjectsTable> {
  $$ProjectsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));
}

class $$ProjectsTableAnnotationComposer
    extends Composer<_$AppDb, $ProjectsTable> {
  $$ProjectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  Expression<T> gridsRefs<T extends Object>(
      Expression<T> Function($$GridsTableAnnotationComposer a) f) {
    final $$GridsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.grids,
        getReferencedColumn: (t) => t.projectId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GridsTableAnnotationComposer(
              $db: $db,
              $table: $db.grids,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> pointsRefs<T extends Object>(
      Expression<T> Function($$PointsTableAnnotationComposer a) f) {
    final $$PointsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.points,
        getReferencedColumn: (t) => t.projectId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PointsTableAnnotationComposer(
              $db: $db,
              $table: $db.points,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ProjectsTableTableManager extends RootTableManager<
    _$AppDb,
    $ProjectsTable,
    Project,
    $$ProjectsTableFilterComposer,
    $$ProjectsTableOrderingComposer,
    $$ProjectsTableAnnotationComposer,
    $$ProjectsTableCreateCompanionBuilder,
    $$ProjectsTableUpdateCompanionBuilder,
    (Project, $$ProjectsTableReferences),
    Project,
    PrefetchHooks Function({bool gridsRefs, bool pointsRefs})> {
  $$ProjectsTableTableManager(_$AppDb db, $ProjectsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
          }) =>
              ProjectsCompanion(
            id: id,
            name: name,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
          }) =>
              ProjectsCompanion.insert(
            id: id,
            name: name,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$ProjectsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({gridsRefs = false, pointsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (gridsRefs) db.grids,
                if (pointsRefs) db.points
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (gridsRefs)
                    await $_getPrefetchedData<Project, $ProjectsTable, Grid>(
                        currentTable: table,
                        referencedTable:
                            $$ProjectsTableReferences._gridsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProjectsTableReferences(db, table, p0).gridsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.projectId == item.id),
                        typedResults: items),
                  if (pointsRefs)
                    await $_getPrefetchedData<Project, $ProjectsTable, Point>(
                        currentTable: table,
                        referencedTable:
                            $$ProjectsTableReferences._pointsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProjectsTableReferences(db, table, p0).pointsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.projectId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ProjectsTableProcessedTableManager = ProcessedTableManager<
    _$AppDb,
    $ProjectsTable,
    Project,
    $$ProjectsTableFilterComposer,
    $$ProjectsTableOrderingComposer,
    $$ProjectsTableAnnotationComposer,
    $$ProjectsTableCreateCompanionBuilder,
    $$ProjectsTableUpdateCompanionBuilder,
    (Project, $$ProjectsTableReferences),
    Project,
    PrefetchHooks Function({bool gridsRefs, bool pointsRefs})>;
typedef $$GridsTableCreateCompanionBuilder = GridsCompanion Function({
  Value<int> id,
  required int projectId,
  required String name,
  required double centerLat,
  required double centerLon,
  required int rows,
  required int cols,
  required double cellSizeM,
  required double rotationDeg,
});
typedef $$GridsTableUpdateCompanionBuilder = GridsCompanion Function({
  Value<int> id,
  Value<int> projectId,
  Value<String> name,
  Value<double> centerLat,
  Value<double> centerLon,
  Value<int> rows,
  Value<int> cols,
  Value<double> cellSizeM,
  Value<double> rotationDeg,
});

final class $$GridsTableReferences
    extends BaseReferences<_$AppDb, $GridsTable, Grid> {
  $$GridsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProjectsTable _projectIdTable(_$AppDb db) => db.projects
      .createAlias($_aliasNameGenerator(db.grids.projectId, db.projects.id));

  $$ProjectsTableProcessedTableManager get projectId {
    final $_column = $_itemColumn<int>('project_id')!;

    final manager = $$ProjectsTableTableManager($_db, $_db.projects)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_projectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$GridsTableFilterComposer extends Composer<_$AppDb, $GridsTable> {
  $$GridsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get centerLat => $composableBuilder(
      column: $table.centerLat, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get centerLon => $composableBuilder(
      column: $table.centerLon, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get rows => $composableBuilder(
      column: $table.rows, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get cols => $composableBuilder(
      column: $table.cols, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get cellSizeM => $composableBuilder(
      column: $table.cellSizeM, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get rotationDeg => $composableBuilder(
      column: $table.rotationDeg, builder: (column) => ColumnFilters(column));

  $$ProjectsTableFilterComposer get projectId {
    final $$ProjectsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.projectId,
        referencedTable: $db.projects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProjectsTableFilterComposer(
              $db: $db,
              $table: $db.projects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$GridsTableOrderingComposer extends Composer<_$AppDb, $GridsTable> {
  $$GridsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get centerLat => $composableBuilder(
      column: $table.centerLat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get centerLon => $composableBuilder(
      column: $table.centerLon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get rows => $composableBuilder(
      column: $table.rows, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get cols => $composableBuilder(
      column: $table.cols, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get cellSizeM => $composableBuilder(
      column: $table.cellSizeM, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get rotationDeg => $composableBuilder(
      column: $table.rotationDeg, builder: (column) => ColumnOrderings(column));

  $$ProjectsTableOrderingComposer get projectId {
    final $$ProjectsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.projectId,
        referencedTable: $db.projects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProjectsTableOrderingComposer(
              $db: $db,
              $table: $db.projects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$GridsTableAnnotationComposer extends Composer<_$AppDb, $GridsTable> {
  $$GridsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get centerLat =>
      $composableBuilder(column: $table.centerLat, builder: (column) => column);

  GeneratedColumn<double> get centerLon =>
      $composableBuilder(column: $table.centerLon, builder: (column) => column);

  GeneratedColumn<int> get rows =>
      $composableBuilder(column: $table.rows, builder: (column) => column);

  GeneratedColumn<int> get cols =>
      $composableBuilder(column: $table.cols, builder: (column) => column);

  GeneratedColumn<double> get cellSizeM =>
      $composableBuilder(column: $table.cellSizeM, builder: (column) => column);

  GeneratedColumn<double> get rotationDeg => $composableBuilder(
      column: $table.rotationDeg, builder: (column) => column);

  $$ProjectsTableAnnotationComposer get projectId {
    final $$ProjectsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.projectId,
        referencedTable: $db.projects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProjectsTableAnnotationComposer(
              $db: $db,
              $table: $db.projects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$GridsTableTableManager extends RootTableManager<
    _$AppDb,
    $GridsTable,
    Grid,
    $$GridsTableFilterComposer,
    $$GridsTableOrderingComposer,
    $$GridsTableAnnotationComposer,
    $$GridsTableCreateCompanionBuilder,
    $$GridsTableUpdateCompanionBuilder,
    (Grid, $$GridsTableReferences),
    Grid,
    PrefetchHooks Function({bool projectId})> {
  $$GridsTableTableManager(_$AppDb db, $GridsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GridsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GridsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GridsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> projectId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<double> centerLat = const Value.absent(),
            Value<double> centerLon = const Value.absent(),
            Value<int> rows = const Value.absent(),
            Value<int> cols = const Value.absent(),
            Value<double> cellSizeM = const Value.absent(),
            Value<double> rotationDeg = const Value.absent(),
          }) =>
              GridsCompanion(
            id: id,
            projectId: projectId,
            name: name,
            centerLat: centerLat,
            centerLon: centerLon,
            rows: rows,
            cols: cols,
            cellSizeM: cellSizeM,
            rotationDeg: rotationDeg,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int projectId,
            required String name,
            required double centerLat,
            required double centerLon,
            required int rows,
            required int cols,
            required double cellSizeM,
            required double rotationDeg,
          }) =>
              GridsCompanion.insert(
            id: id,
            projectId: projectId,
            name: name,
            centerLat: centerLat,
            centerLon: centerLon,
            rows: rows,
            cols: cols,
            cellSizeM: cellSizeM,
            rotationDeg: rotationDeg,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$GridsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({projectId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (projectId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.projectId,
                    referencedTable: $$GridsTableReferences._projectIdTable(db),
                    referencedColumn:
                        $$GridsTableReferences._projectIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$GridsTableProcessedTableManager = ProcessedTableManager<
    _$AppDb,
    $GridsTable,
    Grid,
    $$GridsTableFilterComposer,
    $$GridsTableOrderingComposer,
    $$GridsTableAnnotationComposer,
    $$GridsTableCreateCompanionBuilder,
    $$GridsTableUpdateCompanionBuilder,
    (Grid, $$GridsTableReferences),
    Grid,
    PrefetchHooks Function({bool projectId})>;
typedef $$PointsTableCreateCompanionBuilder = PointsCompanion Function({
  Value<int> id,
  required int projectId,
  required DateTime ts,
  required double lat,
  required double lon,
  required double altitude,
  required double magneticX,
  required double magneticY,
  required double magneticZ,
  required double totalField,
  Value<double?> speedMs,
  Value<double?> courseDeg,
  Value<double?> accuracyM,
  Value<double?> headingDeg,
  Value<String?> source,
});
typedef $$PointsTableUpdateCompanionBuilder = PointsCompanion Function({
  Value<int> id,
  Value<int> projectId,
  Value<DateTime> ts,
  Value<double> lat,
  Value<double> lon,
  Value<double> altitude,
  Value<double> magneticX,
  Value<double> magneticY,
  Value<double> magneticZ,
  Value<double> totalField,
  Value<double?> speedMs,
  Value<double?> courseDeg,
  Value<double?> accuracyM,
  Value<double?> headingDeg,
  Value<String?> source,
});

final class $$PointsTableReferences
    extends BaseReferences<_$AppDb, $PointsTable, Point> {
  $$PointsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProjectsTable _projectIdTable(_$AppDb db) => db.projects
      .createAlias($_aliasNameGenerator(db.points.projectId, db.projects.id));

  $$ProjectsTableProcessedTableManager get projectId {
    final $_column = $_itemColumn<int>('project_id')!;

    final manager = $$ProjectsTableTableManager($_db, $_db.projects)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_projectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$PointsTableFilterComposer extends Composer<_$AppDb, $PointsTable> {
  $$PointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get ts => $composableBuilder(
      column: $table.ts, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get lat => $composableBuilder(
      column: $table.lat, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get lon => $composableBuilder(
      column: $table.lon, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get altitude => $composableBuilder(
      column: $table.altitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get magneticX => $composableBuilder(
      column: $table.magneticX, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get magneticY => $composableBuilder(
      column: $table.magneticY, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get magneticZ => $composableBuilder(
      column: $table.magneticZ, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalField => $composableBuilder(
      column: $table.totalField, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get speedMs => $composableBuilder(
      column: $table.speedMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get courseDeg => $composableBuilder(
      column: $table.courseDeg, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get accuracyM => $composableBuilder(
      column: $table.accuracyM, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get headingDeg => $composableBuilder(
      column: $table.headingDeg, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  $$ProjectsTableFilterComposer get projectId {
    final $$ProjectsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.projectId,
        referencedTable: $db.projects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProjectsTableFilterComposer(
              $db: $db,
              $table: $db.projects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PointsTableOrderingComposer extends Composer<_$AppDb, $PointsTable> {
  $$PointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get ts => $composableBuilder(
      column: $table.ts, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get lat => $composableBuilder(
      column: $table.lat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get lon => $composableBuilder(
      column: $table.lon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get altitude => $composableBuilder(
      column: $table.altitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get magneticX => $composableBuilder(
      column: $table.magneticX, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get magneticY => $composableBuilder(
      column: $table.magneticY, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get magneticZ => $composableBuilder(
      column: $table.magneticZ, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalField => $composableBuilder(
      column: $table.totalField, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get speedMs => $composableBuilder(
      column: $table.speedMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get courseDeg => $composableBuilder(
      column: $table.courseDeg, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get accuracyM => $composableBuilder(
      column: $table.accuracyM, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get headingDeg => $composableBuilder(
      column: $table.headingDeg, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  $$ProjectsTableOrderingComposer get projectId {
    final $$ProjectsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.projectId,
        referencedTable: $db.projects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProjectsTableOrderingComposer(
              $db: $db,
              $table: $db.projects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PointsTableAnnotationComposer extends Composer<_$AppDb, $PointsTable> {
  $$PointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get ts =>
      $composableBuilder(column: $table.ts, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lon =>
      $composableBuilder(column: $table.lon, builder: (column) => column);

  GeneratedColumn<double> get altitude =>
      $composableBuilder(column: $table.altitude, builder: (column) => column);

  GeneratedColumn<double> get magneticX =>
      $composableBuilder(column: $table.magneticX, builder: (column) => column);

  GeneratedColumn<double> get magneticY =>
      $composableBuilder(column: $table.magneticY, builder: (column) => column);

  GeneratedColumn<double> get magneticZ =>
      $composableBuilder(column: $table.magneticZ, builder: (column) => column);

  GeneratedColumn<double> get totalField => $composableBuilder(
      column: $table.totalField, builder: (column) => column);

  GeneratedColumn<double> get speedMs =>
      $composableBuilder(column: $table.speedMs, builder: (column) => column);

  GeneratedColumn<double> get courseDeg =>
      $composableBuilder(column: $table.courseDeg, builder: (column) => column);

  GeneratedColumn<double> get accuracyM =>
      $composableBuilder(column: $table.accuracyM, builder: (column) => column);

  GeneratedColumn<double> get headingDeg => $composableBuilder(
      column: $table.headingDeg, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  $$ProjectsTableAnnotationComposer get projectId {
    final $$ProjectsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.projectId,
        referencedTable: $db.projects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProjectsTableAnnotationComposer(
              $db: $db,
              $table: $db.projects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PointsTableTableManager extends RootTableManager<
    _$AppDb,
    $PointsTable,
    Point,
    $$PointsTableFilterComposer,
    $$PointsTableOrderingComposer,
    $$PointsTableAnnotationComposer,
    $$PointsTableCreateCompanionBuilder,
    $$PointsTableUpdateCompanionBuilder,
    (Point, $$PointsTableReferences),
    Point,
    PrefetchHooks Function({bool projectId})> {
  $$PointsTableTableManager(_$AppDb db, $PointsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> projectId = const Value.absent(),
            Value<DateTime> ts = const Value.absent(),
            Value<double> lat = const Value.absent(),
            Value<double> lon = const Value.absent(),
            Value<double> altitude = const Value.absent(),
            Value<double> magneticX = const Value.absent(),
            Value<double> magneticY = const Value.absent(),
            Value<double> magneticZ = const Value.absent(),
            Value<double> totalField = const Value.absent(),
            Value<double?> speedMs = const Value.absent(),
            Value<double?> courseDeg = const Value.absent(),
            Value<double?> accuracyM = const Value.absent(),
            Value<double?> headingDeg = const Value.absent(),
            Value<String?> source = const Value.absent(),
          }) =>
              PointsCompanion(
            id: id,
            projectId: projectId,
            ts: ts,
            lat: lat,
            lon: lon,
            altitude: altitude,
            magneticX: magneticX,
            magneticY: magneticY,
            magneticZ: magneticZ,
            totalField: totalField,
            speedMs: speedMs,
            courseDeg: courseDeg,
            accuracyM: accuracyM,
            headingDeg: headingDeg,
            source: source,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int projectId,
            required DateTime ts,
            required double lat,
            required double lon,
            required double altitude,
            required double magneticX,
            required double magneticY,
            required double magneticZ,
            required double totalField,
            Value<double?> speedMs = const Value.absent(),
            Value<double?> courseDeg = const Value.absent(),
            Value<double?> accuracyM = const Value.absent(),
            Value<double?> headingDeg = const Value.absent(),
            Value<String?> source = const Value.absent(),
          }) =>
              PointsCompanion.insert(
            id: id,
            projectId: projectId,
            ts: ts,
            lat: lat,
            lon: lon,
            altitude: altitude,
            magneticX: magneticX,
            magneticY: magneticY,
            magneticZ: magneticZ,
            totalField: totalField,
            speedMs: speedMs,
            courseDeg: courseDeg,
            accuracyM: accuracyM,
            headingDeg: headingDeg,
            source: source,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$PointsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({projectId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (projectId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.projectId,
                    referencedTable:
                        $$PointsTableReferences._projectIdTable(db),
                    referencedColumn:
                        $$PointsTableReferences._projectIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$PointsTableProcessedTableManager = ProcessedTableManager<
    _$AppDb,
    $PointsTable,
    Point,
    $$PointsTableFilterComposer,
    $$PointsTableOrderingComposer,
    $$PointsTableAnnotationComposer,
    $$PointsTableCreateCompanionBuilder,
    $$PointsTableUpdateCompanionBuilder,
    (Point, $$PointsTableReferences),
    Point,
    PrefetchHooks Function({bool projectId})>;

class $AppDbManager {
  final _$AppDb _db;
  $AppDbManager(this._db);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db, _db.projects);
  $$GridsTableTableManager get grids =>
      $$GridsTableTableManager(_db, _db.grids);
  $$PointsTableTableManager get points =>
      $$PointsTableTableManager(_db, _db.points);
}
