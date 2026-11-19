class AppConstants {
  AppConstants._();

  static const String appName = 'Smart Lab Safety';
  static const String appTagline = 'Autonomous Environmental & Telemetry Control';
  static const String appVersion = '1.2.0 (Build 4)';
  static const String projectId = 'smart-laboratory-62d87';
  static const String firebaseDatabaseUrl =
      'https://smart-laboratory-62d87-default-rtdb.asia-southeast1.firebasedatabase.app';

  // Exact Realtime Database Contract Paths
  static const String pathLabData = 'lab_data';
  static const String pathSettings = 'settings';
  static const String pathActuators = 'actuators';
  static const String pathDevice = 'device';

  // Extended Production Paths
  static const String pathAlerts = 'alerts';
  static const String pathSensorHistory = 'sensor_history';
  static const String pathCommands = 'commands';

  // Hardware & ADC specifications
  static const int minGasAdc = 0;
  static const int maxGasAdc = 4095;
  static const double minTemperatureC = -10.0;
  static const double maxTemperatureC = 80.0;
  static const double minDistanceCm = 2.0;
  static const double maxDistanceCm = 400.0;

  // Heartbeat & Staleness Policy
  static const Duration heartbeatTimeout = Duration(seconds: 25);
  static const Duration commandAckTimeout = Duration(seconds: 6);
  static const int maxChartHistoryPoints = 36;
}
