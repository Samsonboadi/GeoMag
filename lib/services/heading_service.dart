import 'dart:math';
import 'package:flutter_compass/flutter_compass.dart';


class HeadingService {
static double normalize(double d){ var x = d % 360; if (x < 0) x += 360; return x; }
static double smooth(double prev, double next, double a){
final diff = ((next - prev + 540) % 360) - 180; return normalize(prev + a*diff);
}
Stream<double> stream({double alpha = 0.25}) async* {
double current = 0;
await for (final e in FlutterCompass.events!) {
if (e.heading == null) continue;
current = smooth(current, e.heading!, alpha);
yield current;
}
}
}