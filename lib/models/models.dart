import 'package:latlong2/latlong.dart';


class ProjectModel {
final int id;
final String name;
ProjectModel({required this.id, required this.name});
}


class GridModel {
final int id;
final int projectId;
final String name;
final LatLng center;
final int rows;
final int cols;
final double cellSizeM;
final double rotationDeg;
GridModel({
required this.id,
required this.projectId,
required this.name,
required this.center,
required this.rows,
required this.cols,
required this.cellSizeM,
required this.rotationDeg,
});
}


class PointModel {
final int id;
final int projectId;
final double lat;
final double lon;
final DateTime ts;
final double intensity;
final double? courseDeg;
final double? speedMs;
PointModel({
required this.id,
required this.projectId,
required this.lat,
required this.lon,
required this.ts,
required this.intensity,
this.courseDeg,
this.speedMs,
});
}