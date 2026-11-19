import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/demo_mode_banner.dart';
import '../../core/widgets/glass_3d_card.dart';
import '../../core/widgets/premium_relay_switch_card.dart';
import '../../data/models/actuator_state_model.dart';
import '../../data/models/device_state_model.dart';
import '../../providers/lab_providers.dart';

class DeviceControlScreen extends ConsumerWidget {
  const DeviceControlScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceState = ref.watch(deviceStateStreamProvider).valueOrNull ??
        DeviceState.initial();
    final actuators = ref.watch(actuatorStateStreamProvider).valueOrNull ??
        ActuatorState.initial();
    final overallStatus = ref.watch(overallLabSafetyStatusProvider);
    final isAutomatic = deviceState.mode == ControlMode.automatic;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Actuator & Relay Control',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Manage ESP32 warning relays, automation policy & hardware feedback',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              const DemoModeBanner(showScenarioSelector: true),

              // 1. Control Mode Selector Card (Automatic vs Manual)
              Glass3DCard(
                accentGlowColor:
                    isAutomatic ? AppColors.primaryAccent : AppColors.warning,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isAutomatic
                              ? Icons.auto_mode_rounded
                              : Icons.pan_tool_alt_rounded,
                          color: isAutomatic
                              ? AppColors.primaryAccent
                              : AppColors.warning,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'CONTROL AUTHORITY MODE',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ModeOptionButton(
                            title: 'Automatic Safety',
                            subtitle: 'ESP32 triggers relays on threshold breach',
                            isSelected: isAutomatic,
                            activeColor: AppColors.primaryAccent,
                            onTap: () => ref
                                .read(activeLabRepositoryProvider)
                                .setControlMode(ControlMode.automatic),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ModeOptionButton(
                            title: 'Manual Override',
                            subtitle: 'Direct operator control via Firebase',
                            isSelected: !isAutomatic,
                            activeColor: AppColors.warning,
                            onTap: () => _confirmSwitchToManual(
                              context: context,
                              ref: ref,
                              overallStatus: overallStatus,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.darkBackground.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.darkGlassBorder),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.security_rounded,
                            size: 18,
                            color: AppColors.primaryAccent,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isAutomatic
                                  ? 'Safety-First Policy Active: In Automatic Mode, the ESP32 firmware evaluates DHT22, Gas ADC, and HC-SR04 thresholds continuously. Toggling a relay below will ask for explicit confirmation before entering Manual Override.'
                                  : 'Manual Override Active: Operator commands write directly to /actuators/warning_light and /actuators/warning_alarm. Re-enable Automatic Mode when testing concludes.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 2. Relay Module 1 & Relay Module 2 Cards
              PremiumRelaySwitchCard(
                title: 'Relay Module 1 • Warning Light Beacon',
                subtitle:
                    'High-visibility strobe indicator mounted at lab entrance (/actuators/warning_light)',
                icon: Icons.light_mode_rounded,
                requestedState: actuators.requestedWarningLight,
                confirmedHardwareState: actuators.confirmedLightActual,
                isLoading: actuators.isLightCommandPending,
                isAutomaticMode: isAutomatic,
                activeColor: AppColors.warning,
                onToggleRequested: (val) => _dispatchRelayCommand(
                  context: context,
                  ref: ref,
                  isLight: true,
                  targetState: val,
                  isAutomatic: isAutomatic,
                  overallStatus: overallStatus,
                ),
              ),
              const SizedBox(height: 14),
              PremiumRelaySwitchCard(
                title: 'Relay Module 2 • Acoustic Warning Buzzer',
                subtitle:
                    '85dB piezo alarm for immediate hazard evacuation alert (/actuators/warning_alarm)',
                icon: Icons.campaign_rounded,
                requestedState: actuators.requestedWarningAlarm,
                confirmedHardwareState: actuators.confirmedAlarmActual,
                isLoading: actuators.isAlarmCommandPending,
                isAutomaticMode: isAutomatic,
                activeColor: AppColors.criticalDanger,
                onToggleRequested: (val) => _dispatchRelayCommand(
                  context: context,
                  ref: ref,
                  isLight: false,
                  targetState: val,
                  isAutomatic: isAutomatic,
                  overallStatus: overallStatus,
                ),
              ),
              const SizedBox(height: 18),

              // 3. Hardware Command Synchronization Telemetry Card
              Glass3DCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RELAY TELEMETRY CONTRACT VERIFICATION',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 10),
                    _TelemetryKeyRow(
                      path: '/actuators/warning_light',
                      requestedValue:
                          actuators.requestedWarningLight ? 'true' : 'false',
                      actualPath: '/device/relay_light_actual',
                      actualValue: actuators.confirmedLightActual == null
                          ? 'unreported'
                          : (actuators.confirmedLightActual! ? 'true' : 'false'),
                    ),
                    const Divider(height: 20),
                    _TelemetryKeyRow(
                      path: '/actuators/warning_alarm',
                      requestedValue:
                          actuators.requestedWarningAlarm ? 'true' : 'false',
                      actualPath: '/device/relay_buzzer_actual',
                      actualValue: actuators.confirmedAlarmActual == null
                          ? 'unreported'
                          : (actuators.confirmedAlarmActual! ? 'true' : 'false'),
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

  Future<void> _confirmSwitchToManual({
    required BuildContext context,
    required WidgetRef ref,
    required OverallLabSafetyStatus overallStatus,
  }) async {
    if (overallStatus == OverallLabSafetyStatus.warningDetected) {
      final bool? proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.darkElevatedCard,
          title: const Text('Active Hazard Warning'),
          content: const Text(
            'A laboratory threshold violation is currently active. Switching to Manual Mode allows manual silencing of warning relays. Confirm operator override?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep Automatic'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.criticalDanger,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm Manual Override'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }
    await ref
        .read(activeLabRepositoryProvider)
        .setControlMode(ControlMode.manual);
  }

  Future<void> _dispatchRelayCommand({
    required BuildContext context,
    required WidgetRef ref,
    required bool isLight,
    required bool targetState,
    required bool isAutomatic,
    required OverallLabSafetyStatus overallStatus,
  }) async {
    final repo = ref.read(activeLabRepositoryProvider);

    if (isAutomatic) {
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.darkElevatedCard,
          title: const Text('Override Automatic Safety Mode?'),
          content: Text(
            !targetState &&
                    overallStatus == OverallLabSafetyStatus.warningDetected
                ? 'CRITICAL WARNING: You are attempting to turn OFF a warning actuator while a laboratory safety threshold is breached. This will switch the system to MANUAL mode.'
                : 'Sending a manual relay command requires switching `/device/mode` from "automatic" to "manual". Proceed?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: AppColors.darkBackground,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Override & Send Command'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
      await repo.setControlMode(ControlMode.manual);
    }

    if (isLight) {
      await repo.setWarningLight(
        targetState,
        reason: 'Operator Device Control Screen',
      );
    } else {
      await repo.setWarningAlarm(
        targetState,
        reason: 'Operator Device Control Screen',
      );
    }
  }
}

class _ModeOptionButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _ModeOptionButton({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withOpacity(0.16)
              : AppColors.darkBackground.withOpacity(0.45),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.darkGlassBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  size: 16,
                  color:
                      isSelected ? activeColor : AppColors.darkSecondaryText,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 13.5,
                          color: isSelected
                              ? activeColor
                              : AppColors.darkMainText,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 11.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TelemetryKeyRow extends StatelessWidget {
  final String path;
  final String requestedValue;
  final String actualPath;
  final String actualValue;

  const _TelemetryKeyRow({
    required this.path,
    required this.requestedValue,
    required this.actualPath,
    required this.actualValue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Requested Firebase Path',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 2),
              Text('$path = $requestedValue',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.primaryAccent,
                      )),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ESP32 Hardware Feedback',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 2),
              Text('$actualPath = $actualValue',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: actualValue == requestedValue
                            ? AppColors.success
                            : AppColors.warning,
                      )),
            ],
          ),
        ),
      ],
    );
  }
}
