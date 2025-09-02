// lib/widgets/modern_status_overlay.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

class ModernStatusOverlay extends StatelessWidget {
  final MagVector? magneticData;
  final double? accuracy;
  final double? speed;
  final double? heading;
  final bool isRecording;
  final int pointCount;

  const ModernStatusOverlay({
    super.key,
    this.magneticData,
    this.accuracy,
    this.speed,
    this.heading,
    required this.isRecording,
    required this.pointCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.sensors,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Sensor Data',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isRecording ? Colors.red : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isRecording ? 'LIVE' : 'IDLE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Magnetic field data
            if (magneticData != null) ...[
              _DataRow(
                label: 'Total Field',
                value: '${magneticData!.mag.toStringAsFixed(1)} µT',
                icon: Icons.tune,
                color: _getFieldColor(magneticData!.mag),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _DataRow(
                      label: 'X',
                      value: '${magneticData!.x.toStringAsFixed(1)}',
                      compact: true,
                      color: Colors.red.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DataRow(
                      label: 'Y',
                      value: '${magneticData!.y.toStringAsFixed(1)}',
                      compact: true,
                      color: Colors.green.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DataRow(
                      label: 'Z',
                      value: '${magneticData!.z.toStringAsFixed(1)}',
                      compact: true,
                      color: Colors.blue.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ] else
              _DataRow(
                label: 'Magnetic Field',
                value: 'No data',
                icon: Icons.signal_wifi_off,
                color: Colors.orange,
              ),
            
            if (magneticData != null) const SizedBox(height: 12),
            
            // GPS data
            Row(
              children: [
                Expanded(
                  child: _DataRow(
                    label: 'Accuracy',
                    value: accuracy != null 
                      ? '±${accuracy!.toStringAsFixed(1)}m'
                      : 'N/A',
                    icon: Icons.gps_fixed,
                    compact: true,
                    color: _getAccuracyColor(accuracy),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DataRow(
                    label: 'Speed',
                    value: speed != null 
                      ? '${(speed! * 3.6).toStringAsFixed(1)} km/h'
                      : '0.0 km/h',
                    icon: Icons.speed,
                    compact: true,
                    color: _getSpeedColor(speed),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Survey stats
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Points Collected',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$pointCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getFieldColor(double field) {
    if (field < 30) return Colors.blue;
    if (field < 50) return Colors.green;
    if (field < 65) return Colors.orange;
    return Colors.red;
  }

  Color _getAccuracyColor(double? acc) {
    if (acc == null) return Colors.grey;
    if (acc <= 5) return Colors.green;
    if (acc <= 10) return Colors.orange;
    return Colors.red;
  }

  Color _getSpeedColor(double? speed) {
    if (speed == null || speed < 0.5) return Colors.grey;
    if (speed < 2) return Colors.green;
    if (speed < 5) return Colors.orange;
    return Colors.red;
  }
}

class _DataRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? color;
  final bool compact;

  const _DataRow({
    required this.label,
    required this.value,
    this.icon,
    this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(compact ? 0.05 : 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: color ?? Colors.white.withOpacity(0.7),
              size: compact ? 14 : 16,
            ),
            SizedBox(width: compact ? 6 : 8),
          ],
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: compact ? 12 : 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color ?? Colors.white,
              fontSize: compact ? 12 : 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// Helper class for magnetic vector data
class MagVector {
  final double x, y, z, mag;
  const MagVector(this.x, this.y, this.z, this.mag);
}