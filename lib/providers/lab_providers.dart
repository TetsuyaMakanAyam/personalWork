import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/actuator_state_model.dart';
import '../data/models/alert_model.dart';
import '../data/models/device_state_model.dart';
import '../data/models/lab_data_model.dart';
import '../data/models/safety_settings_model.dart';
import '../data/models/sensor_history_point.dart';
import '../data/repositories/demo_lab_repository.dart';
import '../data/repositories/firebase_lab_repository.dart';
import '../data/repositories/lab_repository.dart';

enum AppTelemetryMode {
  demoSimulation,
  firebaseLive;

  bool get isDemo => this == AppTelemetryMode.demoSimulation;
}

enum OverallLabSafetyStatus {
  laboratorySecure,
  warningDetected,
  sensorFault,
  deviceOffline;

  String get bannerTitle {
    switch (this) {
      case OverallLabSafetyStatus.laboratorySecure:
        return 'LABORATORY SECURE';
      case OverallLabSafetyStatus.warningDetected:
        return 'WARNING DETECTED';
      case OverallLabSafetyStatus.sensorFault:
        return 'SENSOR FAULT';
      case OverallLabSafetyStatus.deviceOffline:
        return 'DEVICE OFFLINE';
    }
  }

  String get subtitle {
    switch (this) {
      case OverallLabSafetyStatus.laboratorySecure:
        return 'All environmental telemetry channels are operating within verified safety thresholds.';
      case OverallLabSafetyStatus.warningDetected:
        return 'One or more laboratory sensors have crossed configured safety thresholds.';
      case OverallLabSafetyStatus.sensorFault:
        return 'ESP32 reported a hardware sensor read or bus fault. Verify sensor wiring immediately.';
      case OverallLabSafetyStatus.deviceOffline:
        return 'ESP32 telemetry heartbeat has timed out or node is disconnected.';
    }
  }
}

/// Defaults to Demo Mode for immediate assignment presentation while allowing
/// instant 1-tap switching to Live Firebase Realtime Database mode.
final telemetryModeProvider = StateProvider<AppTelemetryMode>((ref) {
  return AppTelemetryMode.demoSimulation;
});

final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.dark;
});

final selectedNavIndexProvider = StateProvider<int>((ref) => 0);

final demoRepositoryInstanceProvider = Provider<DemoLabRepository>((ref) {
  final repo = DemoLabRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

final firebaseRepositoryInstanceProvider =
    Provider<FirebaseLabRepository>((ref) {
  final repo = FirebaseLabRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

final activeLabRepositoryProvider = Provider<LabRepository>((ref) {
  final mode = ref.watch(telemetryModeProvider);
  if (mode == AppTelemetryMode.demoSimulation) {
    return ref.watch(demoRepositoryInstanceProvider);
  }
  return ref.watch(firebaseRepositoryInstanceProvider);
});

final demoScenarioPresetProvider = StateProvider<DemoScenarioPreset>((ref) {
  return DemoScenarioPreset.nominalOperation;
});

final clockTickerProvider = StreamProvider<DateTime>((ref) {
  return Stream<DateTime>.periodic(
    const Duration(seconds: 1),
    (_) => DateTime.now(),
  );
});

final backendConnectionProvider = StreamProvider<bool>((ref) {
  final repo = ref.watch(activeLabRepositoryProvider);
  return repo.watchBackendConnectionState();
});

final labDataStreamProvider = StreamProvider<LabData>((ref) {
  final repo = ref.watch(activeLabRepositoryProvider);
  return repo.watchLabData();
});

final safetySettingsStreamProvider = StreamProvider<SafetySettings>((ref) {
  final repo = ref.watch(activeLabRepositoryProvider);
  return repo.watchSafetySettings();
});

final actuatorStateStreamProvider = StreamProvider<ActuatorState>((ref) {
  final repo = ref.watch(activeLabRepositoryProvider);
  return repo.watchActuatorState();
});

final deviceStateStreamProvider = StreamProvider<DeviceState>((ref) {
  final repo = ref.watch(activeLabRepositoryProvider);
  return repo.watchDeviceState();
});

final alertsStreamProvider = StreamProvider<List<LabAlert>>((ref) {
  final repo = ref.watch(activeLabRepositoryProvider);
  return repo.watchAlerts();
});

final sensorHistoryStreamProvider =
    StreamProvider<List<SensorHistoryPoint>>((ref) {
  final repo = ref.watch(activeLabRepositoryProvider);
  return repo.watchSensorHistory();
});

final unreadAlertsCountProvider = Provider<int>((ref) {
  final alertsAsync = ref.watch(alertsStreamProvider);
  return alertsAsync.maybeWhen(
    data: (list) => list.where((a) => !a.isRead).length,
    orElse: () => 0,
  );
});

final effectiveDeviceOnlineProvider = Provider<bool>((ref) {
  final now = ref.watch(clockTickerProvider).valueOrNull ?? DateTime.now();
  final device = ref.watch(deviceStateStreamProvider).valueOrNull;
  final labData = ref.watch(labDataStreamProvider).valueOrNull;
  if (device == null) return false;
  return device.isEffectivelyOnline(
    now,
    latestTelemetryMs: labData?.lastUpdatedEpochMs ?? 0,
  );
});

final overallLabSafetyStatusProvider = Provider<OverallLabSafetyStatus>((ref) {
  final isOnline = ref.watch(effectiveDeviceOnlineProvider);
  final labData = ref.watch(labDataStreamProvider).valueOrNull;
  final settings = ref.watch(safetySettingsStreamProvider).valueOrNull ??
      SafetySettings.defaults();

  if (!isOnline || labData == null || labData.lastUpdatedEpochMs == 0) {
    return OverallLabSafetyStatus.deviceOffline;
  }
  if (labData.sensorFault) {
    return OverallLabSafetyStatus.sensorFault;
  }
  final bool tempBreach = labData.temperature >= settings.maxTemp;
  final bool gasBreach = labData.gasLevel >= settings.maxGas;
  final bool distanceBreach =
      labData.distanceCm > 0 && labData.distanceCm <= settings.maxDistance;

  if (tempBreach || gasBreach || distanceBreach) {
    return OverallLabSafetyStatus.warningDetected;
  }
  return OverallLabSafetyStatus.laboratorySecure;
});
