import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_time_formatter.dart';
import '../../core/widgets/glass_3d_card.dart';
import '../../data/models/device_state_model.dart';
import '../../providers/lab_providers.dart';

class ProfileAboutScreen extends ConsumerWidget {
  const ProfileAboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final telemetryMode = ref.watch(telemetryModeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final deviceState = ref.watch(deviceStateStreamProvider).valueOrNull ??
        DeviceState.initial();
    final isBackendConnected =
        ref.watch(backendConnectionProvider).valueOrNull ?? false;
    final isNodeOnline = ref.watch(effectiveDeviceOnlineProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'System Profile & Architecture',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'ESP32 node diagnostics, Firebase endpoint & presentation mode',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),

              // 1. Telemetry Mode & Presentation Switch Card
              Glass3DCard(
                accentGlowColor: telemetryMode.isDemo
                    ? AppColors.secondaryAccent
                    : AppColors.primaryAccent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TELEMETRY SOURCE CONFIGURATION',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.secondaryAccent,
                      title: const Text(
                        'Demonstration Mode (Simulated ESP32 Telemetry)',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        telemetryMode.isDemo
                            ? 'Active: Running local physics & threshold wave simulator without polluting production Firebase paths.'
                            : 'Inactive: Streaming live telemetry directly from Firebase Realtime Database.',
                      ),
                      value: telemetryMode.isDemo,
                      onChanged: (enableDemo) {
                        ref.read(telemetryModeProvider.notifier).state =
                            enableDemo
                                ? AppTelemetryMode.demoSimulation
                                : AppTelemetryMode.firebaseLive;
                      },
                    ),
                    const Divider(),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.primaryAccent,
                      title: const Text(
                        'Dark Futuristic Theme',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: const Text(
                        'Toggle between primary dark obsidian lab theme and high-contrast light view',
                      ),
                      value: themeMode == ThemeMode.dark,
                      onChanged: (isDark) {
                        ref.read(themeModeProvider.notifier).state =
                            isDark ? ThemeMode.dark : ThemeMode.light;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. ESP32 Microcontroller & Firmware Diagnostics
              Glass3DCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ESP32 HARDWARE NODE SPECIFICATION',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      label: 'Microcontroller',
                      value: 'ESP32 Dual-Core Wi-Fi/BLE MCU',
                    ),
                    _InfoRow(
                      label: 'Firmware Version',
                      value: deviceState.firmwareVersion ??
                          (telemetryMode.isDemo
                              ? 'v2.4.1-ESP32-SIM'
                              : 'Not reported by node'),
                    ),
                    _InfoRow(
                      label: 'Effective Node Status',
                      value: isNodeOnline ? 'ONLINE (Heartbeat OK)' : 'OFFLINE',
                      valueColor: isNodeOnline
                          ? AppColors.success
                          : AppColors.criticalDanger,
                    ),
                    _InfoRow(
                      label: 'Last Heartbeat Seen',
                      value: DateTimeFormatter.formatTimeWithSeconds(
                        deviceState.lastSeenDateTime,
                      ),
                    ),
                    _InfoRow(
                      label: 'Sensors Attached',
                      value: 'DHT22 • Analog Gas ADC • HC-SR04',
                    ),
                    _InfoRow(
                      label: 'Actuators Attached',
                      value: 'Relay 1 (Light) • Relay 2 (Buzzer)',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Firebase Realtime Database Connection Details
              Glass3DCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FIREBASE REALTIME DATABASE CONTRACT',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      label: 'Firebase Project ID',
                      value: AppConstants.projectId,
                    ),
                    _InfoRow(
                      label: 'Region',
                      value: 'asia-southeast1 (Singapore)',
                    ),
                    _InfoRow(
                      label: 'Database URL',
                      value: AppConstants.firebaseDatabaseUrl,
                    ),
                    _InfoRow(
                      label: 'Socket Connection',
                      value: isBackendConnected ? 'CONNECTED' : 'STANDBY',
                      valueColor: isBackendConnected
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                    _InfoRow(
                      label: 'Contract Root Nodes',
                      value: '/lab_data, /settings, /actuators, /device',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. Application Metadata
              Glass3DCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'APPLICATION METADATA',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      label: 'Application Name',
                      value: AppConstants.appName,
                    ),
                    _InfoRow(
                      label: 'Build Version',
                      value: AppConstants.appVersion,
                    ),
                    _InfoRow(
                      label: 'Architecture',
                      value: 'Feature-First + Riverpod + Repository Pattern',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: valueColor ?? AppColors.darkMainText,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
