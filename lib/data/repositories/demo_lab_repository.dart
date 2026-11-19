import 'dart:async';
import 'dart:math' as math;
import '../../core/constants/app_constants.dart';
import '../models/actuator_state_model.dart';
import '../models/alert_model.dart';
import '../models/device_state_model.dart';
import '../models/lab_data_model.dart';
import '../models/safety_settings_model.dart';
import '../models/sensor_history_point.dart';
import 'lab_repository.dart';

enum DemoScenarioPreset {
  nominalOperation,
  thermalSpikeWarning,
  gasLeakCritical,
  proximityBreach,
  sensorHardwareFault,
  esp32OfflineSimulation;

  String get title {
    switch (this) {
      case DemoScenarioPreset.nominalOperation:
        return 'Nominal Lab Conditions';
      case DemoScenarioPreset.thermalSpikeWarning:
        return 'Thermal Anomaly (>36.5°C)';
      case DemoScenarioPreset.gasLeakCritical:
        return 'Fume Hood Gas Surge (ADC >1850)';
      case DemoScenarioPreset.proximityBreach:
        return 'Restricted Zone Proximity (<14cm)';
      case DemoScenarioPreset.sensorHardwareFault:
        return 'DHT22 / ADC Sensor Fault';
      case DemoScenarioPreset.esp32OfflineSimulation:
        return 'ESP32 Node Heartbeat Lost';
    }
  }
}

class DemoLabRepository implements LabRepository {
  Timer? _tickTimer;
  double _phase = 0.0;
  DemoScenarioPreset _activePreset = DemoScenarioPreset.nominalOperation;

  late LabData _currentLabData;
  late SafetySettings _currentSettings;
  late ActuatorState _currentActuators;
  late DeviceState _currentDevice;
  final List<LabAlert> _alerts = [];
  final List<SensorHistoryPoint> _history = [];

  final _labDataCtrl = StreamController<LabData>.broadcast();
  final _settingsCtrl = StreamController<SafetySettings>.broadcast();
  final _actuatorsCtrl = StreamController<ActuatorState>.broadcast();
  final _deviceCtrl = StreamController<DeviceState>.broadcast();
  final _alertsCtrl = StreamController<List<LabAlert>>.broadcast();
  final _historyCtrl = StreamController<List<SensorHistoryPoint>>.broadcast();

  DemoLabRepository() {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    _currentSettings = SafetySettings.defaults();
    _currentLabData = LabData(
      temperature: 28.4,
      humidity: 58.2,
      gasLevel: 760,
      distanceCm: 48.5,
      motionDetected: false,
      sensorFault: false,
      lastUpdatedEpochMs: nowMs,
    );
    _currentActuators = const ActuatorState(
      requestedWarningLight: false,
      requestedWarningAlarm: false,
      confirmedLightActual: false,
      confirmedAlarmActual: false,
    );
    _currentDevice = DeviceState(
      reportedOnlineFlag: true,
      mode: ControlMode.automatic,
      lastSeenEpochMs: nowMs,
      firmwareVersion: 'v2.4.1-ESP32-SIM',
      relayLightActual: false,
      relayBuzzerActual: false,
    );

    _seedInitialHistoryAndAlerts();
    _startSimulationTimer();
  }

  @override
  bool get isDemoRepository => true;

  DemoScenarioPreset get activePreset => _activePreset;

  void _seedInitialHistoryAndAlerts() {
    final now = DateTime.now();
    for (int i = 20; i >= 0; i--) {
      final ts = now.subtract(Duration(seconds: i * 3));
      final wave = math.sin(i * 0.35);
      _history.add(
        SensorHistoryPoint(
          timestamp: ts,
          temperature: double.parse((28.2 + wave * 1.1).toStringAsFixed(1)),
          humidity: double.parse((58.0 + math.cos(i * 0.25) * 3.5).toStringAsFixed(1)),
          gasAdc: (760 + (wave * 65).round()).clamp(0, 4095),
          distanceCm: double.parse((46.0 + math.sin(i * 0.4) * 8.0).toStringAsFixed(1)),
        ),
      );
    }

    _alerts.addAll([
      LabAlert(
        id: 'demo_evt_1',
        type: AlertEventType.systemRestored,
        timestampEpochMs:
            now.subtract(const Duration(minutes: 18)).millisecondsSinceEpoch,
        severity: AlertSeverity.info,
        description:
            '[SIMULATED] ESP32 node boot sequence completed. All 4 telemetry channels verified nominal.',
        isRead: true,
        isSimulatedDemo: true,
      ),
      LabAlert(
        id: 'demo_evt_2',
        type: AlertEventType.objectProximity,
        timestampEpochMs:
            now.subtract(const Duration(minutes: 9)).millisecondsSinceEpoch,
        severity: AlertSeverity.warning,
        description:
            '[SIMULATED] HC-SR04 detected object at 16.4 cm (threshold: 20.0 cm) near chemical storage bay.',
        isRead: false,
        isSimulatedDemo: true,
      ),
      LabAlert(
        id: 'demo_evt_3',
        type: AlertEventType.highGasReading,
        timestampEpochMs:
            now.subtract(const Duration(minutes: 4)).millisecondsSinceEpoch,
        severity: AlertSeverity.critical,
        description:
            '[SIMULATED] Analog gas sensor peaked at 1640 ADC counts (threshold: 1500 ADC). Auto-ventilation relay triggered.',
        isRead: false,
        isSimulatedDemo: true,
      ),
    ]);
  }

  void _startSimulationTimer() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(milliseconds: 1800), (_) {
      _advanceSimulationTick();
    });
  }

  void setScenarioPreset(DemoScenarioPreset preset) {
    _activePreset = preset;
    _advanceSimulationTick(forceAlertOnAnomaly: true);
  }

  void _advanceSimulationTick({bool forceAlertOnAnomaly = false}) {
    _phase += 0.35;
    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;

    if (_activePreset == DemoScenarioPreset.esp32OfflineSimulation) {
      _currentDevice = _currentDevice.copyWith(
        reportedOnlineFlag: false,
        lastSeenEpochMs:
            now.subtract(const Duration(seconds: 45)).millisecondsSinceEpoch,
      );
      _emitAll();
      if (forceAlertOnAnomaly) {
        _pushDemoAlert(
          type: AlertEventType.deviceDisconnected,
          severity: AlertSeverity.critical,
          description:
              '[SIMULATED] ESP32 heartbeat lost (>25s timeout). Telemetry marked stale.',
        );
      }
      return;
    }

    double targetTemp = 28.5 + math.sin(_phase) * 1.15;
    double targetHumidity = 58.0 + math.cos(_phase * 0.7) * 3.8;
    int targetGasAdc = 780 + (math.sin(_phase * 0.9) * 85).round();
    double targetDist = 48.0 + math.cos(_phase * 0.5) * 9.5;
    bool fault = false;

    switch (_activePreset) {
      case DemoScenarioPreset.nominalOperation:
        break;
      case DemoScenarioPreset.thermalSpikeWarning:
        targetTemp = _currentSettings.maxTemp + 3.4 + math.sin(_phase) * 0.8;
        targetHumidity = 44.0 + math.cos(_phase) * 2.0;
        break;
      case DemoScenarioPreset.gasLeakCritical:
        targetGasAdc =
            (_currentSettings.maxGas + 420 + (math.sin(_phase) * 110).round())
                .clamp(0, 4095);
        break;
      case DemoScenarioPreset.proximityBreach:
        targetDist =
            math.max(5.5, _currentSettings.maxDistance - 7.5 + math.sin(_phase) * 1.8);
        break;
      case DemoScenarioPreset.sensorHardwareFault:
        fault = true;
        break;
      case DemoScenarioPreset.esp32OfflineSimulation:
        break;
    }

    final bool proximityDetected = targetDist <= _currentSettings.maxDistance;

    _currentLabData = LabData(
      temperature: double.parse(targetTemp.toStringAsFixed(1)),
      humidity: double.parse(targetHumidity.toStringAsFixed(1)),
      gasLevel: targetGasAdc.clamp(0, 4095),
      distanceCm: double.parse(targetDist.toStringAsFixed(1)),
      motionDetected: proximityDetected,
      sensorFault: fault,
      lastUpdatedEpochMs: nowMs,
    );

    _currentDevice = _currentDevice.copyWith(
      reportedOnlineFlag: true,
      lastSeenEpochMs: nowMs,
    );

    if (!fault) {
      _history.add(
        SensorHistoryPoint(
          timestamp: now,
          temperature: _currentLabData.temperature,
          humidity: _currentLabData.humidity,
          gasAdc: _currentLabData.gasLevel,
          distanceCm: _currentLabData.distanceCm,
        ),
      );
      if (_history.length > AppConstants.maxChartHistoryPoints) {
        _history.removeAt(0);
      }
    }

    // Evaluate automatic safety relay control in Automatic Mode
    final bool hasHazard = !fault &&
        (_currentLabData.temperature >= _currentSettings.maxTemp ||
            _currentLabData.gasLevel >= _currentSettings.maxGas ||
            _currentLabData.distanceCm <= _currentSettings.maxDistance);

    if (_currentDevice.mode == ControlMode.automatic) {
      final bool desiredLight = hasHazard && _currentSettings.autoLed;
      final bool desiredAlarm = hasHazard && _currentSettings.autoBuzzer;
      _currentActuators = _currentActuators.copyWith(
        requestedWarningLight: desiredLight,
        requestedWarningAlarm: desiredAlarm,
        confirmedLightActual: desiredLight,
        confirmedAlarmActual: desiredAlarm,
      );
      _currentDevice = _currentDevice.copyWith(
        relayLightActual: desiredLight,
        relayBuzzerActual: desiredAlarm,
      );
    }

    if (forceAlertOnAnomaly) {
      if (fault) {
        _pushDemoAlert(
          type: AlertEventType.sensorFailure,
          severity: AlertSeverity.critical,
          description:
              '[SIMULATED] Sensor checksum fault reported on DHT22 / ADC bus.',
        );
      } else if (_currentLabData.temperature >= _currentSettings.maxTemp) {
        _pushDemoAlert(
          type: AlertEventType.highTemperature,
          severity: AlertSeverity.warning,
          description:
              '[SIMULATED] Lab temperature reached ${_currentLabData.temperature}°C (Max: ${_currentSettings.maxTemp}°C).',
        );
      } else if (_currentLabData.gasLevel >= _currentSettings.maxGas) {
        _pushDemoAlert(
          type: AlertEventType.highGasReading,
          severity: AlertSeverity.critical,
          description:
              '[SIMULATED] Raw gas ADC reading ${_currentLabData.gasLevel} exceeded limit (${_currentSettings.maxGas}).',
        );
      } else if (_currentLabData.distanceCm <= _currentSettings.maxDistance) {
        _pushDemoAlert(
          type: AlertEventType.objectProximity,
          severity: AlertSeverity.warning,
          description:
              '[SIMULATED] Object detected at ${_currentLabData.distanceCm} cm (Threshold: ${_currentSettings.maxDistance} cm).',
        );
      } else {
        _pushDemoAlert(
          type: AlertEventType.systemRestored,
          severity: AlertSeverity.info,
          description:
              '[SIMULATED] All simulated telemetry channels returned to safe operating bounds.',
        );
      }
    }

    _emitAll();
  }

  void _pushDemoAlert({
    required AlertEventType type,
    required AlertSeverity severity,
    required String description,
  }) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    _alerts.insert(
      0,
      LabAlert(
        id: 'demo_$nowMs',
        type: type,
        timestampEpochMs: nowMs,
        severity: severity,
        description: description,
        isRead: false,
        isSimulatedDemo: true,
      ),
    );
  }

  void _emitAll() {
    if (!_labDataCtrl.isClosed) _labDataCtrl.add(_currentLabData);
    if (!_settingsCtrl.isClosed) _settingsCtrl.add(_currentSettings);
    if (!_actuatorsCtrl.isClosed) _actuatorsCtrl.add(_currentActuators);
    if (!_deviceCtrl.isClosed) _deviceCtrl.add(_currentDevice);
    if (!_alertsCtrl.isClosed) {
      _alertsCtrl.add(List.unmodifiable(_alerts));
    }
    if (!_historyCtrl.isClosed) {
      _historyCtrl.add(List.unmodifiable(_history));
    }
  }

  @override
  Stream<bool> watchBackendConnectionState() async* {
    yield true;
  }

  @override
  Stream<LabData> watchLabData() async* {
    yield _currentLabData;
    yield* _labDataCtrl.stream;
  }

  @override
  Stream<SafetySettings> watchSafetySettings() async* {
    yield _currentSettings;
    yield* _settingsCtrl.stream;
  }

  @override
  Stream<ActuatorState> watchActuatorState() async* {
    yield _currentActuators;
    yield* _actuatorsCtrl.stream;
  }

  @override
  Stream<DeviceState> watchDeviceState() async* {
    yield _currentDevice;
    yield* _deviceCtrl.stream;
  }

  @override
  Stream<List<LabAlert>> watchAlerts() async* {
    yield List.unmodifiable(_alerts);
    yield* _alertsCtrl.stream;
  }

  @override
  Stream<List<SensorHistoryPoint>> watchSensorHistory() async* {
    yield List.unmodifiable(_history);
    yield* _historyCtrl.stream;
  }

  @override
  Future<void> updateSafetySettings(SafetySettings settings) async {
    final err = settings.validate();
    if (err != null) throw ArgumentError(err);
    await Future<void>.delayed(const Duration(milliseconds: 280));
    _currentSettings = settings;
    _advanceSimulationTick();
  }

  @override
  Future<void> setControlMode(ControlMode mode) async {
    await Future<void>.delayed(const Duration(milliseconds: 240));
    _currentDevice = _currentDevice.copyWith(mode: mode);
    _advanceSimulationTick();
  }

  @override
  Future<void> setWarningLight(bool enabled, {required String reason}) async {
    // 1. Write requested state first (pending hardware confirmation)
    _currentActuators = _currentActuators.copyWith(
      requestedWarningLight: enabled,
      isLightCommandPending: true,
    );
    _emitAll();

    // 2. Simulate ESP32 hardware relay acknowledgment delay (550ms)
    await Future<void>.delayed(const Duration(milliseconds: 550));
    _currentActuators = _currentActuators.copyWith(
      confirmedLightActual: enabled,
      isLightCommandPending: false,
    );
    _currentDevice = _currentDevice.copyWith(relayLightActual: enabled);
    _emitAll();
  }

  @override
  Future<void> setWarningAlarm(bool enabled, {required String reason}) async {
    _currentActuators = _currentActuators.copyWith(
      requestedWarningAlarm: enabled,
      isAlarmCommandPending: true,
    );
    _emitAll();

    await Future<void>.delayed(const Duration(milliseconds: 550));
    _currentActuators = _currentActuators.copyWith(
      confirmedAlarmActual: enabled,
      isAlarmCommandPending: false,
    );
    _currentDevice = _currentDevice.copyWith(relayBuzzerActual: enabled);
    _emitAll();
  }

  @override
  Future<void> markAlertAsRead(String alertId) async {
    final idx = _alerts.indexWhere((a) => a.id == alertId);
    if (idx != -1) {
      _alerts[idx] = _alerts[idx].copyWith(isRead: true);
      _emitAll();
    }
  }

  @override
  Future<void> markAllAlertsAsRead() async {
    for (int i = 0; i < _alerts.length; i++) {
      _alerts[i] = _alerts[i].copyWith(isRead: true);
    }
    _emitAll();
  }

  @override
  Future<void> clearAlerts() async {
    _alerts.clear();
    _emitAll();
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _labDataCtrl.close();
    _settingsCtrl.close();
    _actuatorsCtrl.close();
    _deviceCtrl.close();
    _alertsCtrl.close();
    _historyCtrl.close();
  }
}
