// firebase_service.dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

class FirebaseService {
  static FirebaseApp? _app;

  static Future<FirebaseApp> get app async {
    if (_app != null) return _app!;

    try {
      _app = await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      return _app!;
    } catch (e) {
      if (Firebase.apps.isNotEmpty) {
        _app = Firebase.app();
        return _app!;
      }
      rethrow;
    }
  }
}