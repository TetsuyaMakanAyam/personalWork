import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class AnimatedHumidityWave extends StatefulWidget {
  final double humidityPercent;
  final double height;

  const AnimatedHumidityWave({
    super.key,
    required this.humidityPercent,
    this.height = 110,
  });

  @override
  State<AnimatedHumidityWave> createState() => _AnimatedHumidityWaveState();
}

class _AnimatedHumidityWaveState extends State<AnimatedHumidityWave>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return TickerMode(
      enabled: !reduceMotion,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(
          begin: 0,
          end: widget.humidityPercent.clamp(0.0, 100.0),
        ),
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
        builder: (context, animatedPct, _) {
          return AnimatedBuilder(
            animation: _waveController,
            builder: (context, _) {
              return Container(
                height: widget.height,
                decoration: BoxDecoration(
                  color: const Color(0xFF0A1322),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.primaryAccent.withOpacity(0.25),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(17),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _HumidityWavePainter(
                            fillRatio: animatedPct / 100.0,
                            phase: reduceMotion
                                ? 0.0
                                : _waveController.value * 2 * math.pi,
                          ),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${animatedPct.toStringAsFixed(1)}%',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.darkMainText,
                                    shadows: const [
                                      Shadow(
                                        color: Colors.black54,
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                            ),
                            Text(
                              animatedPct > 70
                                  ? 'HIGH MOISTURE'
                                  : (animatedPct < 30 ? 'DRY AIR' : 'OPTIMAL RH'),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    fontSize: 9.5,
                                    color: AppColors.darkMainText.withOpacity(0.88),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _HumidityWavePainter extends CustomPainter {
  final double fillRatio;
  final double phase;

  _HumidityWavePainter({
    required this.fillRatio,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double baseHeight = size.height * (1.0 - fillRatio.clamp(0.05, 0.95));

    // Background secondary wave
    final Path backWave = Path()..moveTo(0, size.height);
    for (double x = 0; x <= size.width; x += 2) {
      final double y =
          baseHeight + math.sin((x / size.width * 2 * math.pi) + phase) * 5.0;
      backWave.lineTo(x, y);
    }
    backWave.lineTo(size.width, size.height);
    backWave.close();

    canvas.drawPath(
      backWave,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF38BDF8).withOpacity(0.32),
            const Color(0xFF0284C7).withOpacity(0.55),
          ],
        ).createShader(Offset.zero & size),
    );

    // Foreground cyan wave
    final Path frontWave = Path()..moveTo(0, size.height);
    for (double x = 0; x <= size.width; x += 2) {
      final double y = baseHeight +
          math.cos((x / size.width * 2 * math.pi) + phase + 0.9) * 4.5;
      frontWave.lineTo(x, y);
    }
    frontWave.lineTo(size.width, size.height);
    frontWave.close();

    canvas.drawPath(
      frontWave,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryAccent.withOpacity(0.65),
            const Color(0xFF0369A1).withOpacity(0.85),
          ],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant _HumidityWavePainter oldDelegate) {
    return oldDelegate.fillRatio != fillRatio || oldDelegate.phase != phase;
  }
}
