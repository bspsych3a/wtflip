import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => const FirebaseOptions(
        // API key is loaded from a compile-time define (use --dart-define)
        apiKey: String.fromEnvironment('FIREBASE_API_KEY', defaultValue: ''),
        authDomain: 'card-flip-f1aea.firebaseapp.com',
        projectId: 'card-flip-f1aea',
        storageBucket: 'card-flip-f1aea.firebasestorage.app',
        messagingSenderId: '814251308579',
        appId: '1:814251308579:web:69011bdb4856f60b1a2396',
        measurementId: 'G-1LWD44VVC3',
      );
}