class SafetySettings {
  final double maxTemp;
  final int maxGas; // Raw ADC threshold 0..4095
  final double maxDistance; // Proximity alert distance threshold in cm
  final bool autoLed;
  final bool autoBuzzer;

  const SafetySettings({
    required this.maxTemp,
    required this.maxGas,
    required this.maxDistance,
    required this.autoLed,
    required this.autoBuzzer,
  });

  factory SafetySettings.defaults() {
    return const SafetySettings(
      maxTemp: 35.0,
      maxGas: 1500,
      maxDistance: 20.0,
      autoLed: true,
      autoBuzzer: true,
    );
  }

  factory SafetySettings.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) return SafetySettings.defaults();

    double parseDouble(dynamic val, double fallback) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? fallback;
      return fallback;
    }

    int parseInt(dynamic val, int fallback) {
      if (val is int) return val;
      if (val is num) return val.round();
      if (val is String) return int.tryParse(val) ?? fallback;
      return fallback;
    }

    return SafetySettings(
      maxTemp: parseDouble(map['max_temp'], 35.0),
      maxGas: parseInt(map['max_gas'], 1500).clamp(0, 4095),
      maxDistance: parseDouble(map['max_distance'], 20.0),
      autoLed: map['auto_led'] != false,
      autoBuzzer: map['auto_buzzer'] != false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'max_temp': double.parse(maxTemp.toStringAsFixed(1)),
      'max_gas': maxGas,
      'max_distance': double.parse(maxDistance.toStringAsFixed(1)),
      'auto_led': autoLed,
      'auto_buzzer': autoBuzzer,
    };
  }

  String? validate() {
    if (maxTemp < 15.0 || maxTemp > 85.0) {
      return 'Maximum temperature must be between 15.0°C and 85.0°C.';
    }
    if (maxGas < 200 || maxGas > 4095) {
      return 'Gas ADC threshold must be between 200 and 4095 (12-bit ADC).';
    }
    if (maxDistance < 5.0 || maxDistance > 300.0) {
      return 'Proximity threshold must be between 5.0 cm and 300.0 cm.';
    }
    return null;
  }

  SafetySettings copyWith({
    double? maxTemp,
    int? maxGas,
    double? maxDistance,
    bool? autoLed,
    bool? autoBuzzer,
  }) {
    return SafetySettings(
      maxTemp: maxTemp ?? this.maxTemp,
      maxGas: maxGas ?? this.maxGas,
      maxDistance: maxDistance ?? this.maxDistance,
      autoLed: autoLed ?? this.autoLed,
      autoBuzzer: autoBuzzer ?? this.autoBuzzer,
    );
  }
}
