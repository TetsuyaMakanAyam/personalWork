import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class AnimatedProximityRadar extends StatefulWidget {
  final double distanceCm;
  final double thresholdCm;
  final double size;

  const AnimatedProximityRadar({
    super.key,
    required this.distanceCm,
    required this.thresholdCm,
    this.size = 135,
  });

  @override
  State<AnimatedProximityRadar> createState() => _AnimatedProximityRadarState();
}

class _AnimatedProximityRadarState extends State<AnimatedProximityRadar>
    with SingleTickerProviderStateMixin {
  late AnimationController _sweepController;

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _sweepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final bool isBreached =
        widget.distanceCm > 0 && widget.distanceCm <= widget.thresholdCm;

    return TickerMode(
      enabled: !reduceMotion,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 100, end: widget.distanceCm),
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeOutCubic,
        builder: (context, animatedDist, _) {
          return AnimatedBuilder(
            animation: _sweepController,
            builder: (context, _) {
              return SizedBox(
                width: widget.size,
                height: widget.size,
                child: CustomPaint(
                  painter: _ProximityRadarPainter(
                    distanceCm: animatedDist,
                    thresholdCm: widget.thresholdCm,
                    sweepAngle: reduceMotion
                        ? 0.5
                        : _sweepController.value * 2 * math.pi,
                    isBreached: isBreached,
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.darkBackground.withOpacity(0.82),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isBreached
                              ? AppColors.criticalDanger
                              : AppColors.primaryAccent.withOpacity(0.45),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${animatedDist.toStringAsFixed(1)} cm',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: isBreached
                                      ? AppColors.criticalDanger
                                      : AppColors.darkMainText,
                                ),
                          ),
                          Text(
                            isBreached ? 'PROXIMITY ALERT' : 'CLEAR ZONE',
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
                                      fontSize: 8.5,
                                      color: isBreached
                                          ? AppColors.criticalDanger
                                          : AppColors.success,
                                    ),
                          ),
                        ],
                      ),
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

class _ProximityRadarPainter extends CustomPainter {
  final double distanceCm;
  final double thresholdCm;
  final double sweepAngle;
  final bool isBreached;

  _ProximityRadarPainter({
    required this.distanceCm,
    required this.thresholdCm,
    required this.sweepAngle,
    required this.isBreached,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double maxRadius = (math.min(size.width, size.height) / 2) - 4;
    final Color primaryColor =
        isBreached ? AppColors.criticalDanger : AppColors.primaryAccent;

    // 1. Concentric range rings
    for (int i = 1; i <= 3; i++) {
      final double r = maxRadius * (i / 3);
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = primaryColor.withOpacity(0.22),
      );
    }

    // 2. Threshold Perimeter Ring (Normalized up to 120cm display range)
    final double thresholdRadius =
        maxRadius * (thresholdCm / 120.0).clamp(0.18, 0.85);
    canvas.drawCircle(
      center,
      thresholdRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = AppColors.warning.withOpacity(0.65),
    );

    // 3. Rotating Radar Sector Sweep
    final Rect radarRect = Rect.fromCircle(center: center, radius: maxRadius);
    canvas.drawArc(
      radarRect,
      sweepAngle - 0.85,
      0.85,
      true,
      Paint()
        ..shader = SweepGradient(
          colors: [
            primaryColor.withOpacity(0.0),
            primaryColor.withOpacity(0.26),
          ],
          startAngle: 0,
          endAngle: 0.85,
          transform: GradientRotation(sweepAngle - 0.85),
        ).createShader(radarRect),
    );

    // 4. Detected Object Blip along top-right vector
    final double objectNorm = (distanceCm / 120.0).clamp(0.1, 0.95);
    final double objectRadius = maxRadius * objectNorm;
    const double blipAngle = -math.pi / 3;
    final Offset blipPos = Offset(
      center.dx + objectRadius * math.cos(blipAngle),
      center.dy + objectRadius * math.sin(blipAngle),
    );

    canvas.drawCircle(
      blipPos,
      8.0,
      Paint()
        ..color = primaryColor.withOpacity(0.32)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawCircle(
      blipPos,
      4.2,
      Paint()..color = primaryColor,
    );
  }

  @override
  bool shouldRepaint(covariant _ProximityRadarPainter oldDelegate) {
    return oldDelegate.distanceCm != distanceCm ||
        oldDelegate.thresholdCm != thresholdCm ||
        oldDelegate.sweepAngle != sweepAngle ||
        oldDelegate.isBreached != isBreached;
  }
}
