enum AlertSeverity {
  info,
  warning,
  critical;

  static AlertSeverity fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'critical':
        return AlertSeverity.critical;
      case 'warning':
        return AlertSeverity.warning;
      default:
        return AlertSeverity.info;
    }
  }
}

enum AlertEventType {
  highTemperature,
  highGasReading,
  objectProximity,
  sensorFailure,
  deviceDisconnected,
  systemRestored,
  manualOverride;

  String get displayName {
    switch (this) {
      case AlertEventType.highTemperature:
        return 'High Temperature Threshold Exceeded';
      case AlertEventType.highGasReading:
        return 'Elevated Gas ADC Reading';
      case AlertEventType.objectProximity:
        return 'Close Object Proximity Detected';
      case AlertEventType.sensorFailure:
        return 'Hardware Sensor Fault';
      case AlertEventType.deviceDisconnected:
        return 'ESP32 Telemetry Offline';
      case AlertEventType.systemRestored:
        return 'Laboratory Parameters Normalized';
      case AlertEventType.manualOverride:
        return 'Manual Actuator Override';
    }
  }

  static AlertEventType fromString(String? value) {
    for (final t in AlertEventType.values) {
      if (t.name.toLowerCase() == value?.toLowerCase()) return t;
    }
    return AlertEventType.systemRestored;
  }
}

class LabAlert {
  final String id;
  final AlertEventType type;
  final int timestampEpochMs;
  final AlertSeverity severity;
  final String description;
  final bool isRead;
  final bool isSimulatedDemo;

  const LabAlert({
    required this.id,
    required this.type,
    required this.timestampEpochMs,
    required this.severity,
    required this.description,
    required this.isRead,
    this.isSimulatedDemo = false,
  });

  DateTime get timestamp =>
      DateTime.fromMillisecondsSinceEpoch(timestampEpochMs);

  factory LabAlert.fromMap(String id, Map<dynamic, dynamic> map,
      {bool isDemo = false}) {
    int ts = 0;
    final rawTs = map['timestamp'];
    if (rawTs is int) {
      ts = rawTs;
    } else if (rawTs is num) {
      ts = rawTs.round();
    }
    if (ts > 0 && ts < 10000000000) {
      ts *= 1000;
    }

    return LabAlert(
      id: id,
      type: AlertEventType.fromString(map['type']?.toString()),
      timestampEpochMs: ts,
      severity: AlertSeverity.fromString(map['severity']?.toString()),
      description: map['description']?.toString() ?? '',
      isRead: map['read'] == true,
      isSimulatedDemo: isDemo || (map['is_demo'] == true),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'timestamp': timestampEpochMs,
      'severity': severity.name,
      'description': description,
      'read': isRead,
      'is_demo': isSimulatedDemo,
    };
  }

  LabAlert copyWith({bool? isRead}) {
    return LabAlert(
      id: id,
      type: type,
      timestampEpochMs: timestampEpochMs,
      severity: severity,
      description: description,
      isRead: isRead ?? this.isRead,
      isSimulatedDemo: isSimulatedDemo,
    );
  }
}
