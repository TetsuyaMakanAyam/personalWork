import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Pre-configured Firebase options pointing to the regional Realtime Database:
/// https://smart-laboratory-62d87-default-rtdb.asia-southeast1.firebasedatabase.app/
///
/// NOTE: Since you already connected Firebase in Android Studio, your existing
/// `google-services.json` in `android/app/` will automatically supply native
/// Android credentials when `Firebase.initializeApp()` runs. If you generated
/// your own `firebase_options.dart` via `flutterfire configure`, you can either
/// keep your generated file or ensure `databaseURL` is included as shown below.
class DefaultFirebaseOptions {
  static const String realtimeDatabaseUrl =
      'https://smart-laboratory-62d87-default-rtdb.asia-southeast1.firebasedatabase.app';

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_WITH_YOUR_GOOGLE_SERVICES_API_KEY_OR_USE_DEFAULT_INIT',
    appId: '1:628700000000:android:smartlaboratory62d87',
    messagingSenderId: '628700000000',
    projectId: 'smart-laboratory-62d87',
    databaseURL: realtimeDatabaseUrl,
    storageBucket: 'smart-laboratory-62d87.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_WITH_YOUR_IOS_API_KEY',
    appId: '1:628700000000:ios:smartlaboratory62d87',
    messagingSenderId: '628700000000',
    projectId: 'smart-laboratory-62d87',
    databaseURL: realtimeDatabaseUrl,
    storageBucket: 'smart-laboratory-62d87.appspot.com',
    iosBundleId: 'com.smartlab.safety',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REPLACE_WITH_YOUR_WEB_API_KEY',
    appId: '1:628700000000:web:smartlaboratory62d87',
    messagingSenderId: '628700000000',
    projectId: 'smart-laboratory-62d87',
    databaseURL: realtimeDatabaseUrl,
    storageBucket: 'smart-laboratory-62d87.appspot.com',
  );
}
