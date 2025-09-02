// lib/services/magnetometer_service.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:sensors_plus/sensors_plus.dart';

class MagVector {
  final double x, y, z, mag;
  const MagVector(this.x, this.y, this.z, this.mag);
}

/// Phone magnetometer with simple EMA smoothing.
class PhoneMagnetometerService {
  PhoneMagnetometerService({this.alpha = 0.25});

  final double alpha; // 0..1
  StreamSubscription<MagnetometerEvent>? _sub;
  final _ctrl = StreamController<MagVector>.broadcast();

  double? _sx, _sy, _sz, _smag;

  Stream<MagVector> get stream => _ctrl.stream;

  void start() {
    _sub ??= magnetometerEventStream().listen((e) {
      final mag = math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z);

      _sx = _sx == null ? e.x : _sx! + alpha * (e.x - _sx!);
      _sy = _sy == null ? e.y : _sy! + alpha * (e.y - _sy!);
      _sz = _sz == null ? e.z : _sz! + alpha * (e.z - _sz!);
      _smag = _smag == null ? mag : _smag! + alpha * (mag - _smag!);

      _ctrl.add(MagVector(_sx!, _sy!, _sz!, _smag!));
    });
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  Future<void> dispose() async {
    await stop();
    await _ctrl.close();
  }
}
