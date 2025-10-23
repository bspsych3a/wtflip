// Replace the YOUR_* placeholders below with values from your Firebase project.
// Preferred: run `dart pub global activate flutterfire_cli` then `flutterfire configure`
// to auto-generate this file and add native config files.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    if (Platform.isAndroid) return android;
    if (Platform.isIOS) return ios;
    if (Platform.isMacOS) return macos;
    if (Platform.isWindows) return windows;
    if (Platform.isLinux) return linux;
    return android;
  }

  // --- WEB: open Firebase console > Project settings > Web app (or create a web app) ---
  static const FirebaseOptions web = FirebaseOptions(
   apiKey: "AIzaSyBHtsKHr09THVbSYGoyf9V7mhLiDnGkocA",
   authDomain: "card-flip-f1aea.firebaseapp.com",
   databaseURL: "https://card-flip-f1aea-default-rtdb.asia-southeast1.firebasedatabase.app",
   projectId: "card-flip-f1aea",
   storageBucket: "card-flip-f1aea.firebasestorage.app",
   messagingSenderId: "814251308579",
   appId: "1:814251308579:web:69011bdb4856f60b1a2396",
   measurementId: "G-1LWD44VVC3"
  );

  // --- ANDROID: create Android app in Firebase, then use values from google-services.json ---
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD-EXAMPLE1234567890abcdefgHIJKLMN',
    appId: '1:1234567890:android:abcdef123456',
    messagingSenderId: '1234567890',
    projectId: 'flutterfire-example',
    storageBucket: 'flutterfire-example.appspot.com',
  );

  // --- IOS: create iOS app and use GoogleService-Info.plist values ---
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD-EXAMPLE1234567890abcdefgHIJKLMN',
    appId: '1:1234567890:ios:abcdef123456',
    messagingSenderId: '1234567890',
    projectId: 'flutterfire-example',
    storageBucket: 'flutterfire-example.appspot.com',
    iosClientId: '1234567890-abcdef123456.apps.googleusercontent.com',
    iosBundleId: 'com.example.app',
  );

  // --- macOS / Windows / Linux: fill similarly if you target those platforms ---
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyD-EXAMPLE1234567890abcdefgHIJKLMN',
    appId: 'YOUR_MACOS_APP_ID',
    messagingSenderId: '1234567890',
    projectId: 'flutterfire-example',
    storageBucket: 'flutterfire-example.appspot.com',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyD-EXAMPLE1234567890abcdefgHIJKLMN',
    appId: 'YOUR_WINDOWS_APP_ID',
    messagingSenderId: '1234567890',
    projectId: 'flutterfire-example',
    storageBucket: 'flutterfire-example.appspot.com',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyD-EXAMPLE1234567890abcdefgHIJKLMN',
    appId: 'YOUR_LINUX_APP_ID',
    messagingSenderId: '1234567890',
    projectId: 'flutterfire-example',
    storageBucket: 'flutterfire-example.appspot.com',
  );
}