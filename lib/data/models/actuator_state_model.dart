class ActuatorState {
  /// Target state written to `/actuators/warning_light`
  final bool requestedWarningLight;

  /// Target state written to `/actuators/warning_alarm`
  final bool requestedWarningAlarm;

  /// Hardware-confirmed state reported by ESP32 via `/device/relay_light_actual`
  final bool? confirmedLightActual;

  /// Hardware-confirmed state reported by ESP32 via `/device/relay_buzzer_actual`
  final bool? confirmedAlarmActual;

  /// UI loading / synchronisation flags
  final bool isLightCommandPending;
  final bool isAlarmCommandPending;

  const ActuatorState({
    required this.requestedWarningLight,
    required this.requestedWarningAlarm,
    this.confirmedLightActual,
    this.confirmedAlarmActual,
    this.isLightCommandPending = false,
    this.isAlarmCommandPending = false,
  });

  factory ActuatorState.initial() {
    return const ActuatorState(
      requestedWarningLight: false,
      requestedWarningAlarm: false,
      confirmedLightActual: null,
      confirmedAlarmActual: null,
    );
  }

  factory ActuatorState.fromMaps({
    required Map<dynamic, dynamic>? actuatorsMap,
    required Map<dynamic, dynamic>? deviceMap,
  }) {
    final bool reqLight = actuatorsMap?['warning_light'] == true;
    final bool reqAlarm = actuatorsMap?['warning_alarm'] == true;

    final bool? actualLight = deviceMap != null &&
            deviceMap.containsKey('relay_light_actual')
        ? deviceMap['relay_light_actual'] == true
        : null;

    final bool? actualAlarm = deviceMap != null &&
            deviceMap.containsKey('relay_buzzer_actual')
        ? deviceMap['relay_buzzer_actual'] == true
        : null;

    return ActuatorState(
      requestedWarningLight: reqLight,
      requestedWarningAlarm: reqAlarm,
      confirmedLightActual: actualLight,
      confirmedAlarmActual: actualAlarm,
    );
  }

  bool get isLightSynchronized =>
      confirmedLightActual != null &&
      confirmedLightActual == requestedWarningLight;

  bool get isAlarmSynchronized =>
      confirmedAlarmActual != null &&
      confirmedAlarmActual == requestedWarningAlarm;

  ActuatorState copyWith({
    bool? requestedWarningLight,
    bool? requestedWarningAlarm,
    bool? confirmedLightActual,
    bool? confirmedAlarmActual,
    bool? isLightCommandPending,
    bool? isAlarmCommandPending,
  }) {
    return ActuatorState(
      requestedWarningLight:
          requestedWarningLight ?? this.requestedWarningLight,
      requestedWarningAlarm:
          requestedWarningAlarm ?? this.requestedWarningAlarm,
      confirmedLightActual: confirmedLightActual ?? this.confirmedLightActual,
      confirmedAlarmActual: confirmedAlarmActual ?? this.confirmedAlarmActual,
      isLightCommandPending:
          isLightCommandPending ?? this.isLightCommandPending,
      isAlarmCommandPending:
          isAlarmCommandPending ?? this.isAlarmCommandPending,
    );
  }
}
