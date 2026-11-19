class LabData {
  final double temperature;
  final double humidity;
  final int gasLevel; // Raw 12-bit ADC value: 0..4095
  final double distanceCm; // HC-SR04 proximity distance in cm
  final bool motionDetected; // Compatibility boolean from contract
  final bool sensorFault;
  final int lastUpdatedEpochMs;

  const LabData({
    required this.temperature,
    required this.humidity,
    required this.gasLevel,
    required this.distanceCm,
    required this.motionDetected,
    required this.sensorFault,
    required this.lastUpdatedEpochMs,
  });

  factory LabData.initial() {
    return const LabData(
      temperature: 0.0,
      humidity: 0.0,
      gasLevel: 0,
      distanceCm: 0.0,
      motionDetected: false,
      sensorFault: false,
      lastUpdatedEpochMs: 0,
    );
  }

  factory LabData.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) return LabData.initial();

    double parseDouble(dynamic val, [double fallback = 0.0]) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? fallback;
      return fallback;
    }

    int parseInt(dynamic val, [int fallback = 0]) {
      if (val is int) return val;
      if (val is num) return val.round();
      if (val is String) return int.tryParse(val) ?? fallback;
      return fallback;
    }

    final int rawTs = parseInt(map['last_updated'], 0);
    // Support seconds or milliseconds epoch timestamps from ESP32
    final int normalizedMs = (rawTs > 0 && rawTs < 10000000000)
        ? rawTs * 1000
        : rawTs;

    return LabData(
      temperature: parseDouble(map['temperature'], 0.0),
      humidity: parseDouble(map['humidity'], 0.0),
      gasLevel: parseInt(map['gas_level'], 0).clamp(0, 4095),
      distanceCm: parseDouble(map['distance_cm'], 0.0).clamp(0.0, 500.0),
      motionDetected: map['motion_detected'] == true,
      sensorFault: map['sensor_fault'] == true,
      lastUpdatedEpochMs: normalizedMs,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'temperature': double.parse(temperature.toStringAsFixed(1)),
      'humidity': double.parse(humidity.toStringAsFixed(1)),
      'gas_level': gasLevel,
      'distance_cm': double.parse(distanceCm.toStringAsFixed(1)),
      'motion_detected': motionDetected,
      'sensor_fault': sensorFault,
      'last_updated': lastUpdatedEpochMs,
    };
  }

  DateTime? get lastUpdatedDateTime => lastUpdatedEpochMs > 0
      ? DateTime.fromMillisecondsSinceEpoch(lastUpdatedEpochMs)
      : null;

  bool get hasValidReadings => lastUpdatedEpochMs > 0 && !sensorFault;

  LabData copyWith({
    double? temperature,
    double? humidity,
    int? gasLevel,
    double? distanceCm,
    bool? motionDetected,
    bool? sensorFault,
    int? lastUpdatedEpochMs,
  }) {
    return LabData(
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      gasLevel: gasLevel ?? this.gasLevel,
      distanceCm: distanceCm ?? this.distanceCm,
      motionDetected: motionDetected ?? this.motionDetected,
      sensorFault: sensorFault ?? this.sensorFault,
      lastUpdatedEpochMs: lastUpdatedEpochMs ?? this.lastUpdatedEpochMs,
    );
  }
}
