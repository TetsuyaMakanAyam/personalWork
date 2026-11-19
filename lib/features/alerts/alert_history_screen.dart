import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_colors.dart';
import '../../core/utils/date_time_formatter.dart';
import '../../core/widgets/demo_mode_banner.dart';
import '../../core/widgets/glass_3d_card.dart';
import '../../data/models/alert_model.dart';
import '../../providers/lab_providers.dart';

class AlertHistoryScreen extends ConsumerWidget {
  const AlertHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(alertsStreamProvider);
    final repo = ref.watch(activeLabRepositoryProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Safety Alert Timeline',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Chronological audit log of anomalies & system events',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Mark all read',
                    onPressed: () => repo.markAllAlertsAsRead(),
                    icon: const Icon(Icons.done_all_rounded),
                  ),
                  IconButton(
                    tooltip: 'Clear log',
                    onPressed: () => repo.clearAlerts(),
                    icon: const Icon(Icons.delete_sweep_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const DemoModeBanner(showScenarioSelector: true),
              Expanded(
                child: alertsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (e, _) => Center(
                    child: Text('Error loading alert history: $e'),
                  ),
                  data: (alerts) {
                    if (alerts.isEmpty) {
                      return Center(
                        child: Glass3DCard(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.verified_user_outlined,
                                size: 46,
                                color: AppColors.success,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No Safety Alerts Recorded',
                                style:
                                    Theme.of(context).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Real alerts are never fabricated. When a threshold violation or device disconnect occurs, it will appear in this timeline.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 110),
                      itemCount: alerts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final alert = alerts[index];
                        return _AlertTimelineTile(
                          alert: alert,
                          onTap: () => repo.markAlertAsRead(alert.id),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertTimelineTile extends StatelessWidget {
  final LabAlert alert;
  final VoidCallback onTap;

  const _AlertTimelineTile({
    required this.alert,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color severityColor;
    IconData icon;
    switch (alert.severity) {
      case AlertSeverity.critical:
        severityColor = AppColors.criticalDanger;
        icon = Icons.gpp_bad_rounded;
        break;
      case AlertSeverity.warning:
        severityColor = AppColors.warning;
        icon = Icons.warning_amber_rounded;
        break;
      case AlertSeverity.info:
        severityColor = AppColors.primaryAccent;
        icon = Icons.info_outline_rounded;
        break;
    }

    return Glass3DCard(
      onTap: onTap,
      accentGlowColor: alert.isRead ? null : severityColor,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: severityColor.withOpacity(0.16),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: severityColor.withOpacity(0.5)),
            ),
            child: Icon(icon, color: severityColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: severityColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        alert.severity.name.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: severityColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    if (alert.isSimulatedDemo) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'DEMO SIMULATED',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.secondaryAccent,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (!alert.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: severityColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  alert.type.displayName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  alert.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  DateTimeFormatter.formatAlertTimestamp(alert.timestamp),
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
