import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_colors.dart';
import '../../core/animations/animated_gas_adc_meter.dart';
import '../../core/animations/animated_humidity_wave.dart';
import '../../core/animations/animated_proximity_radar.dart';
import '../../core/animations/animated_temperature_gauge.dart';
import '../../core/utils/date_time_formatter.dart';
import '../../core/widgets/demo_mode_banner.dart';
import '../../core/widgets/glass_3d_card.dart';
import '../../core/widgets/premium_relay_switch_card.dart';
import '../../data/models/actuator_state_model.dart';
import '../../data/models/device_state_model.dart';
import '../../data/models/lab_data_model.dart';
import '../../data/models/safety_settings_model.dart';
import '../../providers/lab_providers.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockTickerProvider).valueOrNull ?? DateTime.now();
    final labData =
        ref.watch(labDataStreamProvider).valueOrNull ?? LabData.initial();
    final settings = ref.watch(safetySettingsStreamProvider).valueOrNull ??
        SafetySettings.defaults();
    final actuators = ref.watch(actuatorStateStreamProvider).valueOrNull ??
        ActuatorState.initial();
    final deviceState = ref.watch(deviceStateStreamProvider).valueOrNull ??
        DeviceState.initial();
    final overallStatus = ref.watch(overallLabSafetyStatusProvider);
    final isNodeOnline = ref.watch(effectiveDeviceOnlineProvider);
    final unreadAlerts = ref.watch(unreadAlertsCountProvider);
    final alerts = ref.watch(alertsStreamProvider).valueOrNull ?? const [];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primaryAccent,
          backgroundColor: AppColors.darkElevatedCard,
          onRefresh: () async {
            ref.invalidate(labDataStreamProvider);
            ref.invalidate(deviceStateStreamProvider);
            await Future<void>.delayed(const Duration(milliseconds: 350));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Dashboard Header
                _DashboardHeader(
                  now: now,
                  isNodeOnline: isNodeOnline,
                  unreadAlerts: unreadAlerts,
                  onTapAlerts: () =>
                      ref.read(selectedNavIndexProvider.notifier).state = 4,
                ),
                const SizedBox(height: 14),

                // 2. Interactive Demo / Live Mode Switcher Banner
                const DemoModeBanner(showScenarioSelector: true),

                // 3. Laboratory Status Hero Card
                _LaboratoryStatusHeroCard(
                  status: overallStatus,
                  deviceState: deviceState,
                  lastUpdated: labData.lastUpdatedDateTime,
                  now: now,
                ),
                const SizedBox(height: 20),

                // 4. Section Title: Real-time Telemetry Grid
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ENVIRONMENTAL TELEMETRY',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.darkSecondaryText,
                          ),
                    ),
                    Text(
                      'Updated ${DateTimeFormatter.formatRelativeAge(labData.lastUpdatedDateTime, now)}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.primaryAccent,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 5. Four Interactive Sensor Cards (2x2 Grid)
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.78,
                  children: [
                    // Card 1: Temperature (DHT22)
                    _TemperatureOverviewCard(
                      labData: labData,
                      settings: settings,
                      now: now,
                      onTap: () =>
                          ref.read(selectedNavIndexProvider.notifier).state = 1,
                    ),

                    // Card 2: Humidity (DHT22)
                    _HumidityOverviewCard(
                      labData: labData,
                      now: now,
                      onTap: () =>
                          ref.read(selectedNavIndexProvider.notifier).state = 1,
                    ),

                    // Card 3: Raw Gas ADC Sensor (0..4095)
                    _GasOverviewCard(
                      labData: labData,
                      settings: settings,
                      now: now,
                      onTap: () =>
                          ref.read(selectedNavIndexProvider.notifier).state = 1,
                    ),

                    // Card 4: Ultrasonic Object Distance (HC-SR04)
                    _DistanceOverviewCard(
                      labData: labData,
                      settings: settings,
                      now: now,
                      onTap: () =>
                          ref.read(selectedNavIndexProvider.notifier).state = 1,
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // 6. Quick Relay Controls Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'QUICK ACTUATOR CONTROLS',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.darkSecondaryText,
                          ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: deviceState.mode == ControlMode.automatic
                            ? AppColors.primaryAccent.withOpacity(0.14)
                            : AppColors.warning.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'MODE: ${deviceState.mode.name.toUpperCase()}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: deviceState.mode == ControlMode.automatic
                                  ? AppColors.primaryAccent
                                  : AppColors.warning,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: PremiumRelaySwitchCard(
                        title: 'Warning Light',
                        subtitle: 'Relay Module 1 Beacon',
                        icon: Icons.light_mode_rounded,
                        requestedState: actuators.requestedWarningLight,
                        confirmedHardwareState: actuators.confirmedLightActual,
                        isLoading: actuators.isLightCommandPending,
                        isAutomaticMode:
                            deviceState.mode == ControlMode.automatic,
                        activeColor: AppColors.warning,
                        onToggleRequested: (val) => _handleQuickRelayToggle(
                          context: context,
                          ref: ref,
                          isLight: true,
                          targetState: val,
                          currentMode: deviceState.mode,
                          overallStatus: overallStatus,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PremiumRelaySwitchCard(
                        title: 'Warning Buzzer',
                        subtitle: 'Relay Module 2 Siren',
                        icon: Icons.campaign_rounded,
                        requestedState: actuators.requestedWarningAlarm,
                        confirmedHardwareState: actuators.confirmedAlarmActual,
                        isLoading: actuators.isAlarmCommandPending,
                        isAutomaticMode:
                            deviceState.mode == ControlMode.automatic,
                        activeColor: AppColors.criticalDanger,
                        onToggleRequested: (val) => _handleQuickRelayToggle(
                          context: context,
                          ref: ref,
                          isLight: false,
                          targetState: val,
                          currentMode: deviceState.mode,
                          overallStatus: overallStatus,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 7. Latest Safety Event Preview Card
                if (alerts.isNotEmpty)
                  Glass3DCard(
                    onTap: () =>
                        ref.read(selectedNavIndexProvider.notifier).state = 4,
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryAccent.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.history_edu_rounded,
                            color: AppColors.secondaryAccent,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LATEST EVENT • ${DateTimeFormatter.formatAlertTimestamp(alerts.first.timestamp)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: AppColors.secondaryAccent,
                                    ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                alerts.first.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppColors.darkMainText,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.darkSecondaryText,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleQuickRelayToggle({
    required BuildContext context,
    required WidgetRef ref,
    required bool isLight,
    required bool targetState,
    required ControlMode currentMode,
    required OverallLabSafetyStatus overallStatus,
  }) async {
    final repo = ref.read(activeLabRepositoryProvider);

    // Safety-First Policy: Warn operator if disabling an active warning during a hazard
    if (currentMode == ControlMode.automatic) {
      final bool? confirmSwitch = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.darkElevatedCard,
          title: const Text('Switch to Manual Control?'),
          content: Text(
            overallStatus == OverallLabSafetyStatus.warningDetected &&
                    !targetState
                ? 'WARNING: An active laboratory threshold breach is currently detected. Overriding automatic safety control will switch the ESP32 node to MANUAL mode.'
                : 'Actuators are currently governed by Automatic Safety Automation. Do you want to switch to Manual Mode and apply this relay command?',
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
              child: const Text('Switch to Manual & Apply'),
            ),
          ],
        ),
      );
      if (confirmSwitch != true) return;
      await repo.setControlMode(ControlMode.manual);
    }

    try {
      if (isLight) {
        await repo.setWarningLight(
          targetState,
          reason: 'Dashboard quick toggle',
        );
      } else {
        await repo.setWarningAlarm(
          targetState,
          reason: 'Dashboard quick toggle',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to dispatch relay command: $e')),
        );
      }
    }
  }
}

class _DashboardHeader extends StatelessWidget {
  final DateTime now;
  final bool isNodeOnline;
  final int unreadAlerts;
  final VoidCallback onTapAlerts;

  const _DashboardHeader({
    required this.now,
    required this.isNodeOnline,
    required this.unreadAlerts,
    required this.onTapAlerts,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Smart Lab Safety',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isNodeOnline
                          ? AppColors.success.withOpacity(0.16)
                          : AppColors.criticalDanger.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isNodeOnline
                            ? AppColors.success.withOpacity(0.6)
                            : AppColors.criticalDanger.withOpacity(0.6),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6.5,
                          height: 6.5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isNodeOnline
                                ? AppColors.success
                                : AppColors.criticalDanger,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isNodeOnline ? 'ESP32 ONLINE' : 'OFFLINE',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontSize: 9.5,
                                    color: isNodeOnline
                                        ? AppColors.success
                                        : AppColors.criticalDanger,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Lab Operator Console • ${DateTimeFormatter.formatFullHeader(now)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                    ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onTapAlerts,
          style: IconButton.styleFrom(
            backgroundColor: AppColors.darkSecondarySurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.darkGlassBorder),
            ),
          ),
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_none_rounded),
              if (unreadAlerts > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: AppColors.criticalDanger,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LaboratoryStatusHeroCard extends StatelessWidget {
  final OverallLabSafetyStatus status;
  final DeviceState deviceState;
  final DateTime? lastUpdated;
  final DateTime now;

  const _LaboratoryStatusHeroCard({
    required this.status,
    required this.deviceState,
    required this.lastUpdated,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    Gradient cardGradient;
    IconData statusIcon;

    switch (status) {
      case OverallLabSafetyStatus.laboratorySecure:
        badgeColor = AppColors.success;
        cardGradient = AppColors.heroSecureGradient;
        statusIcon = Icons.verified_user_rounded;
        break;
      case OverallLabSafetyStatus.warningDetected:
        badgeColor = AppColors.warning;
        cardGradient = AppColors.heroWarningGradient;
        statusIcon = Icons.warning_amber_rounded;
        break;
      case OverallLabSafetyStatus.sensorFault:
        badgeColor = AppColors.criticalDanger;
        cardGradient = AppColors.heroCriticalGradient;
        statusIcon = Icons.error_outline_rounded;
        break;
      case OverallLabSafetyStatus.deviceOffline:
        badgeColor = AppColors.offlineNeutral;
        cardGradient = AppColors.heroOfflineGradient;
        statusIcon = Icons.cloud_off_rounded;
        break;
    }

    return Glass3DCard(
      gradient: cardGradient,
      accentGlowColor: badgeColor,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: badgeColor.withOpacity(0.55)),
                ),
                child: Icon(statusIcon, color: badgeColor, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SYSTEM TELEMETRY STATUS',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: badgeColor,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      status.bannerTitle,
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            status.subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.darkMainText.withOpacity(0.88),
                ),
          ),
          const SizedBox(height: 14),
          Divider(color: Colors.white.withOpacity(0.1), height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SYNC: ${DateTimeFormatter.formatTimeWithSeconds(lastUpdated)}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              Text(
                'CONTROL: ${deviceState.mode.name.toUpperCase()}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.primaryAccent,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TemperatureOverviewCard extends StatelessWidget {
  final LabData labData;
  final SafetySettings settings;
  final DateTime now;
  final VoidCallback onTap;

  const _TemperatureOverviewCard({
    required this.labData,
    required this.settings,
    required this.now,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isHigh = labData.temperature >= settings.maxTemp;
    return Glass3DCard(
      onTap: onTap,
      accentGlowColor: isHigh ? AppColors.criticalDanger : null,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.thermostat_rounded,
                size: 18,
                color: AppColors.primaryAccent,
              ),
              const SizedBox(width: 6),
              Text(
                'Temperature',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const Spacer(),
          Center(
            child: AnimatedTemperatureGauge(
              temperature: labData.temperature,
              maxThreshold: settings.maxTemp,
              size: 118,
              isCompact: true,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isHigh ? 'THERMAL ALERT' : 'Nominal Range',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 9.5,
                      color:
                          isHigh ? AppColors.criticalDanger : AppColors.success,
                    ),
              ),
              Text(
                DateTimeFormatter.formatRelativeAge(
                  labData.lastUpdatedDateTime,
                  now,
                ),
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HumidityOverviewCard extends StatelessWidget {
  final LabData labData;
  final DateTime now;
  final VoidCallback onTap;

  const _HumidityOverviewCard({
    required this.labData,
    required this.now,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Glass3DCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.water_drop_outlined,
                size: 18,
                color: AppColors.cyanGlow,
              ),
              const SizedBox(width: 6),
              Text(
                'Humidity',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const Spacer(),
          AnimatedHumidityWave(
            humidityPercent: labData.humidity,
            height: 112,
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DHT22 RH%',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 9.5,
                      color: AppColors.primaryAccent,
                    ),
              ),
              Text(
                DateTimeFormatter.formatRelativeAge(
                  labData.lastUpdatedDateTime,
                  now,
                ),
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GasOverviewCard extends StatelessWidget {
  final LabData labData;
  final SafetySettings settings;
  final DateTime now;
  final VoidCallback onTap;

  const _GasOverviewCard({
    required this.labData,
    required this.settings,
    required this.now,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isHigh = labData.gasLevel >= settings.maxGas;
    return Glass3DCard(
      onTap: onTap,
      accentGlowColor: isHigh ? AppColors.criticalDanger : null,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.air_rounded,
                size: 18,
                color: AppColors.secondaryAccent,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Gas Level (ADC)',
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          AnimatedGasAdcMeter(
            gasAdcValue: labData.gasLevel,
            maxAdcThreshold: settings.maxGas,
            isCompact: true,
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isHigh ? 'ADC THRESHOLD' : 'Un-calibrated ADC',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 9.5,
                      color:
                          isHigh ? AppColors.criticalDanger : AppColors.success,
                    ),
              ),
              Text(
                DateTimeFormatter.formatRelativeAge(
                  labData.lastUpdatedDateTime,
                  now,
                ),
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DistanceOverviewCard extends StatelessWidget {
  final LabData labData;
  final SafetySettings settings;
  final DateTime now;
  final VoidCallback onTap;

  const _DistanceOverviewCard({
    required this.labData,
    required this.settings,
    required this.now,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isClose =
        labData.distanceCm > 0 && labData.distanceCm <= settings.maxDistance;
    return Glass3DCard(
      onTap: onTap,
      accentGlowColor: isClose ? AppColors.warning : null,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.radar_rounded,
                size: 18,
                color: AppColors.primaryAccent,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Object Distance',
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Center(
            child: AnimatedProximityRadar(
              distanceCm: labData.distanceCm,
              thresholdCm: settings.maxDistance,
              size: 112,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isClose ? 'OBJECT NEARBY' : 'HC-SR04 Clear',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 9.5,
                      color: isClose ? AppColors.warning : AppColors.success,
                    ),
              ),
              Text(
                DateTimeFormatter.formatRelativeAge(
                  labData.lastUpdatedDateTime,
                  now,
                ),
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
