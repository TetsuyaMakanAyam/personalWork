import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../constants/app_constants.dart';

class AnimatedGasAdcMeter extends StatefulWidget {
  final int gasAdcValue; // 0..4095 raw ADC counts
  final int maxAdcThreshold;
  final bool isCompact;

  const AnimatedGasAdcMeter({
    super.key,
    required this.gasAdcValue,
    required this.maxAdcThreshold,
    this.isCompact = false,
  });

  @override
  State<AnimatedGasAdcMeter> createState() => _AnimatedGasAdcMeterState();
}

class _AnimatedGasAdcMeterState extends State<AnimatedGasAdcMeter>
    with SingleTickerProviderStateMixin {
  late AnimationController _dangerPulseCtrl;

  @override
  void initState() {
    super.initState();
    _dangerPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    _syncPulse();
  }

  @override
  void didUpdateWidget(covariant AnimatedGasAdcMeter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gasAdcValue != widget.gasAdcValue ||
        oldWidget.maxAdcThreshold != widget.maxAdcThreshold) {
      _syncPulse();
    }
  }

  void _syncPulse() {
    final bool danger = widget.gasAdcValue >= widget.maxAdcThreshold;
    if (danger && !_dangerPulseCtrl.isAnimating) {
      _dangerPulseCtrl.repeat(reverse: true);
    } else if (!danger && _dangerPulseCtrl.isAnimating) {
      _dangerPulseCtrl.stop();
      _dangerPulseCtrl.value = 0.0;
    }
  }

  @override
  void dispose() {
    _dangerPulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDanger = widget.gasAdcValue >= widget.maxAdcThreshold;
    final bool isElevated =
        !isDanger && widget.gasAdcValue >= (widget.maxAdcThreshold * 0.75);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: 0,
        end: widget.gasAdcValue.clamp(0, AppConstants.maxGasAdc).toDouble(),
      ),
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeOutCubic,
      builder: (context, animatedAdc, _) {
        return AnimatedBuilder(
          animation: _dangerPulseCtrl,
          builder: (context, _) {
            final Color activeColor = isDanger
                ? AppColors.criticalDanger
                : (isElevated ? AppColors.warning : AppColors.success);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${animatedAdc.round()}',
                      style: widget.isCompact
                          ? Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: activeColor,
                                fontWeight: FontWeight.w800,
                              )
                          : Theme.of(context).textTheme.displaySmall?.copyWith(
                                color: activeColor,
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '/ 4095 RAW ADC',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: widget.isCompact ? 9.5 : 11,
                            color: AppColors.darkSecondaryText,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: widget.isCompact ? 26 : 36,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _SegmentedAdcBarPainter(
                      currentAdc: animatedAdc,
                      thresholdAdc: widget.maxAdcThreshold.toDouble(),
                      pulseValue: isDanger ? _dangerPulseCtrl.value : 0.0,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '0 ADC',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(fontSize: 9.5),
                    ),
                    Text(
                      'LIMIT: ${widget.maxAdcThreshold} ADC',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: 9.5,
                            color: isDanger
                                ? AppColors.criticalDanger
                                : AppColors.warning,
                          ),
                    ),
                    Text(
                      '4095',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(fontSize: 9.5),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _SegmentedAdcBarPainter extends CustomPainter {
  final double currentAdc;
  final double thresholdAdc;
  final double pulseValue;

  _SegmentedAdcBarPainter({
    required this.currentAdc,
    required this.thresholdAdc,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const int totalSegments = 20;
    const double spacing = 3.5;
    final double segWidth =
        (size.width - (spacing * (totalSegments - 1))) / totalSegments;

    final double activeRatio =
        (currentAdc / AppConstants.maxGasAdc).clamp(0.0, 1.0);
    final double thresholdRatio =
        (thresholdAdc / AppConstants.maxGasAdc).clamp(0.0, 1.0);

    for (int i = 0; i < totalSegments; i++) {
      final double segNorm = (i + 1) / totalSegments;
      final bool isLit = segNorm <= activeRatio + (0.5 / totalSegments);

      Color segColor;
      if (segNorm >= thresholdRatio) {
        segColor = AppColors.criticalDanger;
      } else if (segNorm >= thresholdRatio * 0.72) {
        segColor = AppColors.warning;
      } else {
        segColor = AppColors.success;
      }

      final Rect rect = Rect.fromLTWH(
        i * (segWidth + spacing),
        4,
        segWidth,
        size.height - 8,
      );
      final RRect rrect =
          RRect.fromRectAndRadius(rect, const Radius.circular(4));

      if (isLit) {
        if (segNorm >= thresholdRatio) {
          canvas.drawRRect(
            rrect.inflate(1.5 + pulseValue * 2.0),
            Paint()
              ..color =
                  AppColors.criticalDanger.withOpacity(0.3 + pulseValue * 0.35)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
          );
        }
        canvas.drawRRect(rrect, Paint()..color = segColor);
      } else {
        canvas.drawRRect(
          rrect,
          Paint()..color = const Color(0xFF1A263B),
        );
      }
    }

    // Draw threshold vertical indicator pin
    final double thresholdX = (size.width * thresholdRatio).clamp(2.0, size.width - 2.0);
    canvas.drawLine(
      Offset(thresholdX, 0),
      Offset(thresholdX, size.height),
      Paint()
        ..color = AppColors.darkMainText
        ..strokeWidth = 2.0,
    );
  }

  @override
  bool shouldRepaint(covariant _SegmentedAdcBarPainter oldDelegate) {
    return oldDelegate.currentAdc != currentAdc ||
        oldDelegate.thresholdAdc != thresholdAdc ||
        oldDelegate.pulseValue != pulseValue;
  }
}
