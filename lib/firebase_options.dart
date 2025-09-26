// File generated manually for new Firebase project
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// Default [FirebaseOptions] for your new Firebase project.
/// Use with:
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions have only been configured for Web. '
      'Run FlutterFire CLI again if you need other platforms.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC4HA74LsAO8RAXq_DHAOOPzlRkqVvfJX8',
    appId: '1:848777637127:web:02e5e704257e1a0e31e9a2',
    messagingSenderId: '848777637127',
    projectId: 'global-care-mc',
    authDomain: 'global-care-mc.firebaseapp.com',
    storageBucket: 'global-care-mc.firebasestorage.app',
    measurementId: 'G-9CWJ4BTYP7',
  );

}