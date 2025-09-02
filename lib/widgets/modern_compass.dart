// lib/widgets/modern_compass.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

class ModernCompass extends StatelessWidget {
  final double heading;
  final double size;
  final bool showDegrees;
  final Color? accentColor;

  const ModernCompass({
    super.key,
    required this.heading,
    this.size = 120,
    this.showDegrees = true,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = accentColor ?? theme.colorScheme.primary;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Compass rose background
          CustomPaint(
            size: Size(size, size),
            painter: _CompassRosePainter(),
          ),
          
          // Direction needle
          Transform.rotate(
            angle: heading * math.pi / 180,
            child: CustomPaint(
              size: Size(size * 0.7, size * 0.7),
              painter: _CompassNeedlePainter(accentColor: accent),
            ),
          ),
          
          // Center dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1),
            ),
          ),
          
          // Degree display
          if (showDegrees)
            Positioned(
              bottom: size * 0.15,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Text(
                  '${heading.round()}°',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CompassRosePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Cardinal directions
    final cardinalDirections = ['N', 'E', 'S', 'W'];
    final cardinalAngles = [0, 90, 180, 270];
    
    for (int i = 0; i < 4; i++) {
      final angle = cardinalAngles[i] * math.pi / 180;
      final startRadius = radius * 0.85;
      final endRadius = radius * 0.95;
      
      // Direction lines
      paint.color = Colors.white.withOpacity(0.8);
      canvas.drawLine(
        center + Offset(math.sin(angle) * startRadius, -math.cos(angle) * startRadius),
        center + Offset(math.sin(angle) * endRadius, -math.cos(angle) * endRadius),
        paint,
      );
      
      // Direction labels
      final textPainter = TextPainter(
        text: TextSpan(
          text: cardinalDirections[i],
          style: TextStyle(
            color: i == 0 ? Colors.red : Colors.white.withOpacity(0.9),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      
      final labelRadius = radius * 0.75;
      final labelOffset = center + Offset(
        math.sin(angle) * labelRadius - textPainter.width / 2,
        -math.cos(angle) * labelRadius - textPainter.height / 2,
      );
      textPainter.paint(canvas, labelOffset);
    }
    
    // Intermediate tick marks
    paint.color = Colors.white.withOpacity(0.4);
    for (int i = 0; i < 360; i += 30) {
      if (i % 90 != 0) { // Skip cardinal directions
        final angle = i * math.pi / 180;
        final startRadius = radius * 0.88;
        final endRadius = radius * 0.95;
        
        canvas.drawLine(
          center + Offset(math.sin(angle) * startRadius, -math.cos(angle) * startRadius),
          center + Offset(math.sin(angle) * endRadius, -math.cos(angle) * endRadius),
          paint,
        );
      }
    }
    
    // Minor tick marks
    paint.strokeWidth = 1;
    paint.color = Colors.white.withOpacity(0.2);
    for (int i = 0; i < 360; i += 10) {
      if (i % 30 != 0) { // Skip major ticks
        final angle = i * math.pi / 180;
        final startRadius = radius * 0.91;
        final endRadius = radius * 0.95;
        
        canvas.drawLine(
          center + Offset(math.sin(angle) * startRadius, -math.cos(angle) * startRadius),
          center + Offset(math.sin(angle) * endRadius, -math.cos(angle) * endRadius),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CompassNeedlePainter extends CustomPainter {
  final Color accentColor;

  _CompassNeedlePainter({required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    final paint = Paint()..style = PaintingStyle.fill;
    
    // North needle (red)
    final northPath = Path();
    northPath.moveTo(center.dx, center.dy - radius * 0.8);
    northPath.lineTo(center.dx - 6, center.dy - 4);
    northPath.lineTo(center.dx + 6, center.dy - 4);
    northPath.close();
    
    paint.color = Colors.red;
    canvas.drawPath(northPath, paint);
    
    // South needle (white)
    final southPath = Path();
    southPath.moveTo(center.dx, center.dy + radius * 0.8);
    southPath.lineTo(center.dx - 6, center.dy + 4);
    southPath.lineTo(center.dx + 6, center.dy + 4);
    southPath.close();
    
    paint.color = Colors.white.withOpacity(0.9);
    canvas.drawPath(southPath, paint);
    
    // Needle shaft
    paint.color = Colors.white.withOpacity(0.8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center,
          width: 3,
          height: radius * 1.4,
        ),
        const Radius.circular(1.5),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ModernMagneticFieldIndicator extends StatelessWidget {
  final double fieldStrength;
  final double size;
  final double minField;
  final double maxField;

  const ModernMagneticFieldIndicator({
    super.key,
    required this.fieldStrength,
    this.size = 80,
    this.minField = 20,
    this.maxField = 70,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalizedValue = ((fieldStrength - minField) / (maxField - minField)).clamp(0.0, 1.0);
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background arc
          CustomPaint(
            size: Size(size, size),
            painter: _FieldIndicatorPainter(
              value: normalizedValue,
              fieldStrength: fieldStrength,
            ),
          ),
          
          // Center value
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                fieldStrength.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              Text(
                'µT',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 10,
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

class _FieldIndicatorPainter extends CustomPainter {
  final double value;
  final double fieldStrength;

  _FieldIndicatorPainter({required this.value, required this.fieldStrength});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    
    // Background arc
    paint.color = Colors.white.withOpacity(0.2);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2,
      false,
      paint,
    );
    
    // Value arc with gradient effect
    paint.shader = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: -math.pi / 2 + (value * math.pi * 2),
      colors: [
        Colors.blue,
        Colors.cyan,
        Colors.green,
        Colors.yellow,
        Colors.orange,
        Colors.red,
      ],
    ).createShader(Rect.fromCircle(center: center, radius: radius));
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      value * math.pi * 2,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ModernGPSStatusIndicator extends StatelessWidget {
  final double? accuracy;
  final int satelliteCount;
  final bool hasSignal;

  const ModernGPSStatusIndicator({
    super.key,
    this.accuracy,
    this.satelliteCount = 0,
    required this.hasSignal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasSignal ? Icons.gps_fixed : Icons.gps_not_fixed,
            color: hasSignal ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          if (accuracy != null)
            Text(
              '±${accuracy!.toStringAsFixed(1)}m',
              style: TextStyle(
                color: _getAccuracyColor(accuracy!),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            Text(
              'No GPS',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Color _getAccuracyColor(double acc) {
    if (acc <= 3) return Colors.green;
    if (acc <= 8) return Colors.orange;
    return Colors.red;
  }
}

class ModernSensorCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Color? accentColor;
  final VoidCallback? onTap;

  const ModernSensorCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = accentColor ?? theme.colorScheme.primary;
    
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: accent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (onTap != null)
                      Icon(
                        Icons.chevron_right,
                        color: Colors.white.withOpacity(0.5),
                        size: 20,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ModernProgressBar extends StatelessWidget {
  final double value;
  final String label;
  final String? valueText;
  final Color? color;

  const ModernProgressBar({
    super.key,
    required this.value,
    required this.label,
    this.valueText,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progressColor = color ?? theme.colorScheme.primary;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (valueText != null)
              Text(
                valueText!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    progressColor.withOpacity(0.8),
                    progressColor,
                  ],
                ),
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                    color: progressColor.withOpacity(0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ModernMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final IconData icon;
  final Color? color;

  const ModernMetricTile({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = color ?? theme.colorScheme.primary;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: accentColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 4),
                Text(
                  unit!,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// Animated recording indicator
class ModernRecordingIndicator extends StatefulWidget {
  final bool isRecording;
  final int pointCount;

  const ModernRecordingIndicator({
    super.key,
    required this.isRecording,
    required this.pointCount,
  });

  @override
  State<ModernRecordingIndicator> createState() => _ModernRecordingIndicatorState();
}

class _ModernRecordingIndicatorState extends State<ModernRecordingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isRecording) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(ModernRecordingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !oldWidget.isRecording) {
      _controller.repeat(reverse: true);
    } else if (!widget.isRecording && oldWidget.isRecording) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isRecording) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.withOpacity(0.9),
            Colors.red.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'RECORDING',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                '${widget.pointCount} points',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 11,
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