import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class AnimatedTemperatureGauge extends StatefulWidget {
  final double temperature;
  final double maxThreshold;
  final double size;
  final bool isCompact;

  const AnimatedTemperatureGauge({
    super.key,
    required this.temperature,
    required this.maxThreshold,
    this.size = 180,
    this.isCompact = false,
  });

  @override
  State<AnimatedTemperatureGauge> createState() =>
      _AnimatedTemperatureGaugeState();
}

class _AnimatedTemperatureGaugeState extends State<AnimatedTemperatureGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _updatePulseState();
  }

  @override
  void didUpdateWidget(covariant AnimatedTemperatureGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.temperature != widget.temperature ||
        oldWidget.maxThreshold != widget.maxThreshold) {
      _updatePulseState();
    }
  }

  void _updatePulseState() {
    final bool isOverThreshold = widget.temperature >= widget.maxThreshold;
    if (isOverThreshold && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!isOverThreshold && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.value = 0.0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final bool isExceeded = widget.temperature >= widget.maxThreshold;

    return TickerMode(
      enabled: !reduceMotion,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: widget.temperature),
        duration: reduceMotion
            ? const Duration(milliseconds: 50)
            : const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
        builder: (context, animatedTemp, _) {
          return AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              final double pulseFactor =
                  isExceeded ? _pulseController.value : 0.0;

              return SizedBox(
                width: widget.size,
                height: widget.size,
                child: CustomPaint(
                  painter: _TemperatureGaugePainter(
                    temperature: animatedTemp,
                    maxThreshold: widget.maxThreshold,
                    pulseFactor: pulseFactor,
                    isCompact: widget.isCompact,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${animatedTemp.toStringAsFixed(1)}°C',
                          style: widget.isCompact
                              ? Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: isExceeded
                                        ? AppColors.criticalDanger
                                        : AppColors.darkMainText,
                                  )
                              : Theme.of(context)
                                  .textTheme
                                  .displayMedium
                                  ?.copyWith(
                                    color: isExceeded
                                        ? AppColors.criticalDanger
                                        : AppColors.darkMainText,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isExceeded
                              ? 'LIMIT ${widget.maxThreshold.toStringAsFixed(1)}°C'
                              : 'MAX ${widget.maxThreshold.toStringAsFixed(1)}°C',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontSize: widget.isCompact ? 9 : 11,
                                    color: isExceeded
                                        ? AppColors.criticalDanger
                                        : AppColors.darkSecondaryText,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _TemperatureGaugePainter extends CustomPainter {
  final double temperature;
  final double maxThreshold;
  final double pulseFactor;
  final bool isCompact;

  _TemperatureGaugePainter({
    required this.temperature,
    required this.maxThreshold,
    required this.pulseFactor,
    required this.isCompact,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius =
        (math.min(size.width, size.height) / 2) - (isCompact ? 10 : 16);
    final double strokeWidth = isCompact ? 8.5 : 13.0;

    const double startAngle = 135 * math.pi / 180;
    const double sweepRange = 270 * math.pi / 180;

    // 1. Recessed 3D Outer Bezel Shadow
    final Paint bezelPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 5
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF060A12);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepRange,
      false,
      bezelPaint,
    );

    // 2. Inactive Track
    final Paint trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF1E2D45);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepRange,
      false,
      trackPaint,
    );

    // 3. Normalized Progress (0°C to 60°C display scale)
    final double normalized = (temperature / 60.0).clamp(0.0, 1.0);
    final double activeSweep = sweepRange * normalized;

    final bool isHigh = temperature >= maxThreshold;
    final bool isWarm = temperature >= (maxThreshold * 0.85);

    final List<Color> arcColors = isHigh
        ? [
            AppColors.warning,
            AppColors.criticalDanger,
            const Color(0xFFFF2E55),
          ]
        : (isWarm
            ? [AppColors.primaryAccent, AppColors.warning]
            : [const Color(0xFF38BDF8), AppColors.primaryAccent, AppColors.success]);

    // 4. Ambient Glow around Active Arc
    if (activeSweep > 0.02) {
      final Paint glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 6 + (pulseFactor * 6)
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          isCompact ? 6 : (10 + pulseFactor * 6),
        )
        ..color = (isHigh ? AppColors.criticalDanger : AppColors.primaryAccent)
            .withOpacity(0.32 + pulseFactor * 0.25);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        activeSweep,
        false,
        glowPaint,
      );

      // 5. Gradient Active Progress Stroke
      final Rect arcRect = Rect.fromCircle(center: center, radius: radius);
      final Paint activePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: 0,
          endAngle: math.pi * 2,
          colors: arcColors,
          transform: const GradientRotation(startAngle - 0.2),
        ).createShader(arcRect);

      canvas.drawArc(arcRect, startAngle, activeSweep, false, activePaint);
    }

    // 6. Threshold Marker Tick on Perimeter
    final double thresholdNorm = (maxThreshold / 60.0).clamp(0.0, 1.0);
    final double thresholdAngle = startAngle + (sweepRange * thresholdNorm);
    final Offset markerInner = Offset(
      center.dx + (radius - strokeWidth * 0.8) * math.cos(thresholdAngle),
      center.dy + (radius - strokeWidth * 0.8) * math.sin(thresholdAngle),
    );
    final Offset markerOuter = Offset(
      center.dx + (radius + strokeWidth * 0.8) * math.cos(thresholdAngle),
      center.dy + (radius + strokeWidth * 0.8) * math.sin(thresholdAngle),
    );
    canvas.drawLine(
      markerInner,
      markerOuter,
      Paint()
        ..color = AppColors.criticalDanger
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _TemperatureGaugePainter oldDelegate) {
    return oldDelegate.temperature != temperature ||
        oldDelegate.maxThreshold != maxThreshold ||
        oldDelegate.pulseFactor != pulseFactor;
  }
}
