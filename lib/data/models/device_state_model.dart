import '../../core/constants/app_constants.dart';

enum ControlMode {
  automatic,
  manual;

  String get toContractString => name;

  static ControlMode fromString(String? value) {
    if (value?.toLowerCase() == 'manual') return ControlMode.manual;
    return ControlMode.automatic;
  }
}

class DeviceState {
  final bool reportedOnlineFlag;
  final ControlMode mode;
  final int lastSeenEpochMs;
  final String? firmwareVersion;
  final bool? relayLightActual;
  final bool? relayBuzzerActual;

  const DeviceState({
    required this.reportedOnlineFlag,
    required this.mode,
    required this.lastSeenEpochMs,
    this.firmwareVersion,
    this.relayLightActual,
    this.relayBuzzerActual,
  });

  factory DeviceState.initial() {
    return const DeviceState(
      reportedOnlineFlag: false,
      mode: ControlMode.automatic,
      lastSeenEpochMs: 0,
      firmwareVersion: null,
    );
  }

  factory DeviceState.fromMap(
    Map<dynamic, dynamic>? map, {
    int fallbackLastUpdatedMs = 0,
  }) {
    if (map == null) {
      return DeviceState.initial();
    }

    int parseInt(dynamic val, int fallback) {
      if (val is int) return val;
      if (val is num) return val.round();
      if (val is String) return int.tryParse(val) ?? fallback;
      return fallback;
    }

    int rawLastSeen = parseInt(map['last_seen'], fallbackLastUpdatedMs);
    if (rawLastSeen > 0 && rawLastSeen < 10000000000) {
      rawLastSeen *= 1000;
    }

    return DeviceState(
      reportedOnlineFlag: map['online'] == true,
      mode: ControlMode.fromString(map['mode']?.toString()),
      lastSeenEpochMs: rawLastSeen,
      firmwareVersion: map['firmware_version']?.toString(),
      relayLightActual: map.containsKey('relay_light_actual')
          ? map['relay_light_actual'] == true
          : null,
      relayBuzzerActual: map.containsKey('relay_buzzer_actual')
          ? map['relay_buzzer_actual'] == true
          : null,
    );
  }

  /// Evaluates true connectivity using both `/device/online` and heartbeat freshness.
  /// An `online: true` boolean alone is not trusted if the last heartbeat or telemetry
  /// timestamp has exceeded the timeout window.
  bool isEffectivelyOnline(DateTime now, {int latestTelemetryMs = 0}) {
    if (!reportedOnlineFlag) return false;
    final int effectiveBeatMs =
        lastSeenEpochMs > latestTelemetryMs ? lastSeenEpochMs : latestTelemetryMs;
    if (effectiveBeatMs <= 0) {
      return reportedOnlineFlag;
    }
    final age = now.difference(
      DateTime.fromMillisecondsSinceEpoch(effectiveBeatMs),
    );
    return age <= AppConstants.heartbeatTimeout;
  }

  DateTime? get lastSeenDateTime => lastSeenEpochMs > 0
      ? DateTime.fromMillisecondsSinceEpoch(lastSeenEpochMs)
      : null;

  DeviceState copyWith({
    bool? reportedOnlineFlag,
    ControlMode? mode,
    int? lastSeenEpochMs,
    String? firmwareVersion,
    bool? relayLightActual,
    bool? relayBuzzerActual,
  }) {
    return DeviceState(
      reportedOnlineFlag: reportedOnlineFlag ?? this.reportedOnlineFlag,
      mode: mode ?? this.mode,
      lastSeenEpochMs: lastSeenEpochMs ?? this.lastSeenEpochMs,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      relayLightActual: relayLightActual ?? this.relayLightActual,
      relayBuzzerActual: relayBuzzerActual ?? this.relayBuzzerActual,
    );
  }
}
