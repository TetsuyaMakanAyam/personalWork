import '../models/actuator_state_model.dart';
import '../models/alert_model.dart';
import '../models/device_state_model.dart';
import '../models/lab_data_model.dart';
import '../models/safety_settings_model.dart';
import '../models/sensor_history_point.dart';

abstract class LabRepository {
  bool get isDemoRepository;

  Stream<LabData> watchLabData();
  Stream<SafetySettings> watchSafetySettings();
  Stream<ActuatorState> watchActuatorState();
  Stream<DeviceState> watchDeviceState();
  Stream<List<LabAlert>> watchAlerts();
  Stream<List<SensorHistoryPoint>> watchSensorHistory();
  Stream<bool> watchBackendConnectionState();

  Future<void> updateSafetySettings(SafetySettings settings);
  Future<void> setControlMode(ControlMode mode);
  Future<void> setWarningLight(bool enabled, {required String reason});
  Future<void> setWarningAlarm(bool enabled, {required String reason});
  Future<void> markAlertAsRead(String alertId);
  Future<void> markAllAlertsAsRead();
  Future<void> clearAlerts();

  void dispose();
}
