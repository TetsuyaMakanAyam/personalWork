import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/alerts/alert_history_screen.dart';
import '../../features/controls/device_control_screen.dart';
import '../../features/dashboard/home_dashboard_screen.dart';
import '../../features/monitoring/live_monitoring_screen.dart';
import '../../features/profile/profile_about_screen.dart';
import '../../features/settings/safety_settings_screen.dart';
import '../../providers/lab_providers.dart';
import '../theme/app_colors.dart';

class MainNavigationShell extends ConsumerWidget {
  const MainNavigationShell({super.key});

  static const List<Widget> _screens = [
    HomeDashboardScreen(),
    LiveMonitoringScreen(),
    DeviceControlScreen(),
    SafetySettingsScreen(),
    AlertHistoryScreen(),
    ProfileAboutScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(selectedNavIndexProvider);
    final unreadAlerts = ref.watch(unreadAlertsCountProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: KeyedSubtree(
          key: ValueKey<int>(currentIndex),
          child: _screens[currentIndex],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                height: 68,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSecondarySurface.withOpacity(0.9)
                      : Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkGlassBorder
                        : AppColors.lightGlassBorder,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavBarItem(
                      icon: Icons.space_dashboard_rounded,
                      label: 'Home',
                      isSelected: currentIndex == 0,
                      onTap: () =>
                          ref.read(selectedNavIndexProvider.notifier).state = 0,
                    ),
                    _NavBarItem(
                      icon: Icons.analytics_outlined,
                      fallbackIcon: Icons.show_chart_rounded,
                      label: 'Monitor',
                      isSelected: currentIndex == 1,
                      onTap: () =>
                          ref.read(selectedNavIndexProvider.notifier).state = 1,
                    ),
                    _NavBarItem(
                      icon: Icons.toggle_on_rounded,
                      label: 'Controls',
                      isSelected: currentIndex == 2,
                      onTap: () =>
                          ref.read(selectedNavIndexProvider.notifier).state = 2,
                    ),
                    _NavBarItem(
                      icon: Icons.tune_rounded,
                      label: 'Limits',
                      isSelected: currentIndex == 3,
                      onTap: () =>
                          ref.read(selectedNavIndexProvider.notifier).state = 3,
                    ),
                    _NavBarItem(
                      icon: Icons.notifications_active_outlined,
                      label: 'Alerts',
                      badgeCount: unreadAlerts,
                      isSelected: currentIndex == 4,
                      onTap: () =>
                          ref.read(selectedNavIndexProvider.notifier).state = 4,
                    ),
                    _NavBarItem(
                      icon: Icons.memory_rounded,
                      label: 'System',
                      isSelected: currentIndex == 5,
                      onTap: () =>
                          ref.read(selectedNavIndexProvider.notifier).state = 5,
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

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final IconData? fallbackIcon;
  final String label;
  final bool isSelected;
  final int badgeCount;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    this.fallbackIcon,
    required this.label,
    required this.isSelected,
    this.badgeCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final IconData effectiveIcon = fallbackIcon ?? icon;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryAccent.withOpacity(0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  effectiveIcon,
                  size: 22,
                  color: isSelected
                      ? AppColors.primaryAccent
                      : AppColors.darkSecondaryText,
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4.5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.criticalDanger,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppColors.primaryAccent
                    : AppColors.darkSecondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
