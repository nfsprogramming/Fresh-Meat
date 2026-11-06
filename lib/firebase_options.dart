// File generated for Fresh Meat Firebase integration.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with Fresh Meat app.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBzbP7HkCxPr8HgvgmF5OVLc9R-ge8AhIc',
    appId: '1:512551262542:web:d345d0bb0ce5207a72661f',
    messagingSenderId: '512551262542',
    projectId: 'fresh-meat-39fbb',
    authDomain: 'fresh-meat-39fbb.firebaseapp.com',
    storageBucket: 'fresh-meat-39fbb.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAbmkcPdlRJysvLYqav6oHJAHybEcFnkD8',
    appId: '1:512551262542:android:2852c6f6299a386372661f',
    messagingSenderId: '512551262542',
    projectId: 'fresh-meat-39fbb',
    storageBucket: 'fresh-meat-39fbb.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAbmkcPdlRJysvLYqav6oHJAHybEcFnkD8',
    appId: '1:512551262542:android:2852c6f6299a386372661f',
    messagingSenderId: '512551262542',
    projectId: 'fresh-meat-39fbb',
    storageBucket: 'fresh-meat-39fbb.firebasestorage.app',
    iosBundleId: 'com.fresh.meat',
  );
}
