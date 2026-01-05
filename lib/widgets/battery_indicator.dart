import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

class BatteryIndicator extends StatefulWidget {
  final int level;
  final bool isCharging;
  final double size;

  const BatteryIndicator({
    super.key,
    required this.level,
    this.isCharging = false,
    this.size = 200,
  });

  @override
  State<BatteryIndicator> createState() => _BatteryIndicatorState();
}

class _BatteryIndicatorState extends State<BatteryIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.isCharging) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(BatteryIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCharging && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isCharging && _controller.isAnimating) {
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
    final color = AppTheme.getBatteryColor(widget.level);
    
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isCharging ? _pulseAnimation.value : 1.0,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background circle
                CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _BatteryRingPainter(
                    progress: widget.level / 100,
                    color: color,
                    backgroundColor: AppTheme.surfaceLight,
                  ),
                ),
                // Percentage text
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${widget.level}%',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (widget.isCharging) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bolt,
                            color: AppTheme.warning,
                            size: 20,
                          ),
                          Text(
                            'Charging',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.warning,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BatteryRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _BatteryRingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 20) / 2;
    const strokeWidth = 12.0;

    // Background ring
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress ring
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );
    
    // Glow effect
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 8
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BatteryRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
