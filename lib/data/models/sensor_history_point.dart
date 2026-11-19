class SensorHistoryPoint {
  final DateTime timestamp;
  final double temperature;
  final double humidity;
  final int gasAdc;
  final double distanceCm;

  const SensorHistoryPoint({
    required this.timestamp,
    required this.temperature,
    required this.humidity,
    required this.gasAdc,
    required this.distanceCm,
  });
}
