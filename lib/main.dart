import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF080D18),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  try {
    // Uses native google-services.json connected in Android Studio first;
    // falls back to explicit databaseURL options if needed.
    if (Firebase.apps.isEmpty) {
      try {
        await Firebase.initializeApp();
      } catch (_) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
    }
  } catch (e) {
    debugPrint('Firebase initialization warning (Demo Mode remains fully functional): $e');
  }

  runApp(
    const ProviderScope(
      child: SmartLabSafetyApp(),
    ),
  );
}
