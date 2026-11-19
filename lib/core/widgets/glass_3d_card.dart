import 'dart:ui';
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class Glass3DCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Gradient? gradient;
  final Color? accentGlowColor;
  final double borderRadius;
  final VoidCallback? onTap;
  final Border? customBorder;

  const Glass3DCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.gradient,
    this.accentGlowColor,
    this.borderRadius = 24,
    this.onTap,
    this.customBorder,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color effectiveAccent = accentGlowColor ?? AppColors.primaryAccent;

    final Gradient defaultGradient = isDark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xE61D2B42),
              Color(0xE6131D2E),
              Color(0xF20E1624),
            ],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFF3F7FC),
            ],
          );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.45)
                : Colors.black.withOpacity(0.06),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
          if (accentGlowColor != null)
            BoxShadow(
              color: effectiveAccent.withOpacity(isDark ? 0.16 : 0.12),
              blurRadius: 24,
              spreadRadius: -2,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(borderRadius),
              splashColor: effectiveAccent.withOpacity(0.1),
              highlightColor: effectiveAccent.withOpacity(0.05),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: gradient ?? defaultGradient,
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: customBorder ??
                      Border.all(
                        color: accentGlowColor != null
                            ? effectiveAccent.withOpacity(0.45)
                            : (isDark
                                ? AppColors.darkGlassBorder
                                : AppColors.lightGlassBorder),
                        width: 1.15,
                      ),
                ),
                child: Stack(
                  children: [
                    // Subtle top specular 3D inner highlight
                    Positioned(
                      top: 0,
                      left: 16,
                      right: 16,
                      child: Container(
                        height: 1.2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.0),
                              Colors.white.withOpacity(isDark ? 0.22 : 0.6),
                              Colors.white.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: padding,
                      child: child,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
