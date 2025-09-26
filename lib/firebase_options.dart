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
    apiKey: "AIzaSyD3ePJjiFT7_ouPwqdjj9Yv6FbyUnhrgfs",
    authDomain: "global-care-medical-cent-ebf7d.firebaseapp.com",
    projectId: "global-care-medical-cent-ebf7d",
    storageBucket: "global-care-medical-cent-ebf7d.firebasestorage.app",
    messagingSenderId: "109312662875",
    appId: "1:109312662875:web:ba8443cc326e9fcfe30e7e",
    measurementId: "G-J99LVFZBCK",
  );
}
