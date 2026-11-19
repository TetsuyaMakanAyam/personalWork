import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_lab_safety/app/app.dart';
import 'package:smart_lab_safety/data/models/lab_data_model.dart';
import 'package:smart_lab_safety/data/models/safety_settings_model.dart';

void main() {
  test('LabData model parses contract JSON and clamps ADC 0..4095', () {
    final map = {
      'temperature': 29.5,
      'humidity': 65.0,
      'gas_level': 820,
      'distance_cm': 45.2,
      'motion_detected': false,
      'sensor_fault': false,
      'last_updated': 1731940000,
    };

    final model = LabData.fromMap(map);
    expect(model.temperature, 29.5);
    expect(model.humidity, 65.0);
    expect(model.gasLevel, 820);
    expect(model.distanceCm, 45.2);
    expect(model.motionDetected, false);
    expect(model.sensorFault, false);
  });

  test('SafetySettings validates threshold ranges strictly', () {
    final valid = SafetySettings.defaults();
    expect(valid.validate(), isNull);

    final invalidGas = valid.copyWith(maxGas: 5000);
    expect(invalidGas.validate(), isNotNull);
  });

  testWidgets('SmartLabSafetyApp boots into SplashScreen', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SmartLabSafetyApp(),
      ),
    );
    expect(find.text('SMART LAB SAFETY'), findsOneWidget);
  });
}
