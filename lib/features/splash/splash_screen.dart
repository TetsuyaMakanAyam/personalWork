import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/navigation/main_navigation_shell.dart';
import '../../app/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _introController;
  late AnimationController _ambientController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _fadeAnimation = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOutCubic,
    );
    _scaleAnimation = Tween<double>(begin: 0.86, end: 1.0).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeOutBack),
    );

    _introController.forward();

    // Restrained, responsive splash duration (1.75 seconds)
    _navTimer = Timer(const Duration(milliseconds: 1750), _navigateToDashboard);
  }

  void _navigateToDashboard() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 520),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: const MainNavigationShell(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _introController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Stack(
        children: [
          // Subtle animated ambient particle & lighting canvas
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _ambientController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _SplashAmbientPainter(
                    progress: _ambientController.value,
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Custom 3D-inspired Shield & Telemetry Crest Logo
                      Container(
                        width: 108,
                        height: 108,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF1E324E),
                              Color(0xFF101929),
                            ],
                          ),
                          border: Border.all(
                            color: AppColors.primaryAccent.withOpacity(0.65),
                            width: 1.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryAccent.withOpacity(0.28),
                              blurRadius: 34,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              size: 62,
                              color: AppColors.primaryAccent.withOpacity(0.95),
                            ),
                            const Icon(
                              Icons.sensors_rounded,
                              size: 28,
                              color: AppColors.secondaryAccent,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 26),
                      Text(
                        AppConstants.appName.toUpperCase(),
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              letterSpacing: 2.2,
                              fontWeight: FontWeight.w800,
                              color: AppColors.darkMainText,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppConstants.appTagline,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.darkSecondaryText,
                              letterSpacing: 0.4,
                            ),
                      ),
                      const SizedBox(height: 36),
                      SizedBox(
                        width: 140,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: const LinearProgressIndicator(
                            minHeight: 3.5,
                            backgroundColor: AppColors.darkElevatedCard,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryAccent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'INITIALIZING ESP32 TELEMETRY BUS',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              color: AppColors.primaryAccent.withOpacity(0.85),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashAmbientPainter extends CustomPainter {
  final double progress;

  _SplashAmbientPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2 - 40);

    // Soft ambient radial lighting
    final Paint radialGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primaryAccent.withOpacity(0.14),
          AppColors.secondaryAccent.withOpacity(0.06),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.65));
    canvas.drawCircle(center, size.width * 0.65, radialGlow);

    // Subtle orbiting telemetry nodes
    for (int i = 0; i < 12; i++) {
      final double angle = (i * math.pi / 6) + (progress * 2 * math.pi);
      final double orbitRadius = 85.0 + (i % 3) * 38.0;
      final Offset pos = Offset(
        center.dx + orbitRadius * math.cos(angle),
        center.dy + orbitRadius * math.sin(angle),
      );
      canvas.drawCircle(
        pos,
        (i % 2 == 0) ? 2.2 : 1.4,
        Paint()
          ..color = (i % 2 == 0
                  ? AppColors.primaryAccent
                  : AppColors.secondaryAccent)
              .withOpacity(0.32),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SplashAmbientPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
