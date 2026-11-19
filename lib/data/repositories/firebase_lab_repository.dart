import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../core/constants/app_constants.dart';
import '../models/actuator_state_model.dart';
import '../models/alert_model.dart';
import '../models/device_state_model.dart';
import '../models/lab_data_model.dart';
import '../models/safety_settings_model.dart';
import '../models/sensor_history_point.dart';
import 'lab_repository.dart';

class FirebaseLabRepository implements LabRepository {
  final FirebaseDatabase _db;
  final List<SensorHistoryPoint> _sessionHistoryBuffer = [];
  final StreamController<List<SensorHistoryPoint>> _historyController =
      StreamController<List<SensorHistoryPoint>>.broadcast();
  StreamSubscription<DatabaseEvent>? _historySub;

  FirebaseLabRepository({FirebaseDatabase? database})
      : _db = database ??
            FirebaseDatabase.instanceFor(
              app: Firebase.app(),
              databaseURL: AppConstants.firebaseDatabaseUrl,
            ) {
    _ensureAuthenticated();
    _initLiveHistoryCollector();
  }

  @override
  bool get isDemoRepository => false;

  Future<void> _ensureAuthenticated() async {
    try {
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) {
        await auth.signInAnonymously();
      }
    } catch (_) {
      // Continues gracefully if anonymous auth is not required by rules during lab testing
    }
  }

  void _initLiveHistoryCollector() {
    _historySub = _db
        .ref(AppConstants.pathLabData)
        .onValue
        .listen((DatabaseEvent event) {
      final raw = event.snapshot.value;
      if (raw is Map) {
        final data = LabData.fromMap(raw);
        if (data.lastUpdatedEpochMs > 0 && !data.sensorFault) {
          final point = SensorHistoryPoint(
            timestamp: data.lastUpdatedDateTime ?? DateTime.now(),
            temperature: data.temperature,
            humidity: data.humidity,
            gasAdc: data.gasLevel,
            distanceCm: data.distanceCm,
          );
          _sessionHistoryBuffer.add(point);
          if (_sessionHistoryBuffer.length > AppConstants.maxChartHistoryPoints) {
            _sessionHistoryBuffer.removeAt(0);
          }
          if (!_historyController.isClosed) {
            _historyController.add(List.unmodifiable(_sessionHistoryBuffer));
          }
        }
      }
    }, onError: (_) {});
  }

  @override
  Stream<bool> watchBackendConnectionState() {
    return _db.ref('.info/connected').onValue.map((event) {
      return event.snapshot.value == true;
    }).handleError((_) => false);
  }

  @override
  Stream<LabData> watchLabData() {
    return _db.ref(AppConstants.pathLabData).onValue.map((event) {
      final raw = event.snapshot.value;
      if (raw is Map) {
        return LabData.fromMap(raw);
      }
      return LabData.initial();
    });
  }

  @override
  Stream<SafetySettings> watchSafetySettings() {
    return _db.ref(AppConstants.pathSettings).onValue.map((event) {
      final raw = event.snapshot.value;
      if (raw is Map) {
        return SafetySettings.fromMap(raw);
      }
      return SafetySettings.defaults();
    });
  }

  @override
  Stream<ActuatorState> watchActuatorState() {
    // Combine `/actuators` and `/device` so we display both requested and confirmed hardware relay state
    final controller = StreamController<ActuatorState>.broadcast();
    Map<dynamic, dynamic>? latestActuators;
    Map<dynamic, dynamic>? latestDevice;

    void emitCombined() {
      if (!controller.isClosed) {
        controller.add(
          ActuatorState.fromMaps(
            actuatorsMap: latestActuators,
            deviceMap: latestDevice,
          ),
        );
      }
    }

    final sub1 = _db.ref(AppConstants.pathActuators).onValue.listen((event) {
      if (event.snapshot.value is Map) {
        latestActuators = event.snapshot.value as Map;
      } else {
        latestActuators = null;
      }
      emitCombined();
    }, onError: controller.addError);

    final sub2 = _db.ref(AppConstants.pathDevice).onValue.listen((event) {
      if (event.snapshot.value is Map) {
        latestDevice = event.snapshot.value as Map;
      } else {
        latestDevice = null;
      }
      emitCombined();
    }, onError: controller.addError);

    controller.onCancel = () {
      sub1.cancel();
      sub2.cancel();
    };

    return controller.stream;
  }

  @override
  Stream<DeviceState> watchDeviceState() {
    final controller = StreamController<DeviceState>.broadcast();
    Map<dynamic, dynamic>? latestDeviceMap;
    int latestLabUpdatedMs = 0;

    void emitState() {
      if (!controller.isClosed) {
        controller.add(
          DeviceState.fromMap(
            latestDeviceMap,
            fallbackLastUpdatedMs: latestLabUpdatedMs,
          ),
        );
      }
    }

    final subDevice = _db.ref(AppConstants.pathDevice).onValue.listen((event) {
      latestDeviceMap =
          event.snapshot.value is Map ? event.snapshot.value as Map : null;
      emitState();
    }, onError: controller.addError);

    final subLab =
        _db.ref('${AppConstants.pathLabData}/last_updated').onValue.listen((e) {
      final val = e.snapshot.value;
      if (val is int) {
        latestLabUpdatedMs = val < 10000000000 ? val * 1000 : val;
      } else if (val is num) {
        final raw = val.round();
        latestLabUpdatedMs = raw < 10000000000 ? raw * 1000 : raw;
      }
      emitState();
    }, onError: (_) {});

    controller.onCancel = () {
      subDevice.cancel();
      subLab.cancel();
    };

    return controller.stream;
  }

  @override
  Stream<List<LabAlert>> watchAlerts() {
    return _db
        .ref(AppConstants.pathAlerts)
        .orderByChild('timestamp')
        .limitToLast(50)
        .onValue
        .map((event) {
      final raw = event.snapshot.value;
      if (raw is! Map) return const <LabAlert>[];

      final List<LabAlert> list = [];
      raw.forEach((key, value) {
        if (value is Map) {
          list.add(LabAlert.fromMap(key.toString(), value, isDemo: false));
        }
      });
      list.sort((a, b) => b.timestampEpochMs.compareTo(a.timestampEpochMs));
      return list;
    });
  }

  @override
  Stream<List<SensorHistoryPoint>> watchSensorHistory() async* {
    yield List.unmodifiable(_sessionHistoryBuffer);
    yield* _historyController.stream;
  }

  @override
  Future<void> updateSafetySettings(SafetySettings settings) async {
    final validationError = settings.validate();
    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    final ref = _db.ref(AppConstants.pathSettings);
    await ref.runTransaction((Object? currentData) {
      return Transaction.success(settings.toMap());
    });
  }

  @override
  Future<void> setControlMode(ControlMode mode) async {
    await _db.ref(AppConstants.pathDevice).update({
      'mode': mode.toContractString,
    });
  }

  @override
  Future<void> setWarningLight(bool enabled, {required String reason}) async {
    await _db.ref(AppConstants.pathActuators).update({
      'warning_light': enabled,
    });
    await _db.ref(AppConstants.pathCommands).push().set({
      'target': 'warning_light',
      'requested_state': enabled,
      'reason': reason,
      'timestamp': ServerValue.timestamp,
    });
  }

  @override
  Future<void> setWarningAlarm(bool enabled, {required String reason}) async {
    await _db.ref(AppConstants.pathActuators).update({
      'warning_alarm': enabled,
    });
    await _db.ref(AppConstants.pathCommands).push().set({
      'target': 'warning_alarm',
      'requested_state': enabled,
      'reason': reason,
      'timestamp': ServerValue.timestamp,
    });
  }

  @override
  Future<void> markAlertAsRead(String alertId) async {
    await _db.ref('${AppConstants.pathAlerts}/$alertId').update({'read': true});
  }

  @override
  Future<void> markAllAlertsAsRead() async {
    final snap = await _db.ref(AppConstants.pathAlerts).get();
    if (snap.value is Map) {
      final Map<String, Object?> updates = {};
      (snap.value as Map).forEach((key, _) {
        updates['$key/read'] = true;
      });
      if (updates.isNotEmpty) {
        await _db.ref(AppConstants.pathAlerts).update(updates);
      }
    }
  }

  @override
  Future<void> clearAlerts() async {
    await _db.ref(AppConstants.pathAlerts).remove();
  }

  @override
  void dispose() {
    _historySub?.cancel();
    _historyController.close();
  }
}
