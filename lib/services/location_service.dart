import 'dart:async';
import 'package:geolocator/geolocator.dart';


class LocationService {
Stream<Position> stream({double distanceFilter = 2}) {
  return Geolocator.getPositionStream(
    locationSettings: LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: distanceFilter.round(), // convert double → int
    ),
  );

}}
