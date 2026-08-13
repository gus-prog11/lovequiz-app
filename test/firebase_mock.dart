import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart'
    show FirebaseAuthPlatform, PigeonUserDetails, UserPlatform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart'
    show FirebaseAppPlatform, FirebasePlatform, defaultFirebaseAppName;

/// Inyecta un [FirebasePlatform] falso (con la app por defecto) y un
/// [FirebaseAuthPlatform] sin sesión, para que el arranque de la app
/// (splash -> login) funcione en tests sin canales nativos.
void setUpFirebaseMocks() {
  final app = FirebaseAppPlatform(defaultFirebaseAppName, _fakeOptions);
  Firebase.delegatePackingProperty = _FakeFirebasePlatform(app);
  FirebaseAuthPlatform.instance = _FakeAuthPlatform();
}

final FirebaseOptions _fakeOptions = FirebaseOptions(
  apiKey: 'mock-api-key',
  appId: 'mock-app-id',
  messagingSenderId: 'mock-sender-id',
  projectId: 'mock-project-id',
);

class _FakeFirebasePlatform extends FirebasePlatform {
  _FakeFirebasePlatform(this._app);

  final FirebaseAppPlatform _app;

  @override
  List<FirebaseAppPlatform> get apps => [_app];

  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    if (name != _app.name) {
      throw ArgumentError('No Firebase App "$name" has been created.');
    }
    return _app;
  }

  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    if (name != null && name != defaultFirebaseAppName) {
      throw ArgumentError('Only the default Firebase App is mocked.');
    }
    return _app;
  }
}

class _FakeAuthPlatform extends FirebaseAuthPlatform {
  @override
  UserPlatform? get currentUser => null;

  @override
  Stream<UserPlatform?> authStateChanges() => const Stream.empty();

  @override
  Stream<UserPlatform?> idTokenChanges() => const Stream.empty();

  @override
  Stream<UserPlatform?> userChanges() => const Stream.empty();

  @override
  FirebaseAuthPlatform delegateFor({required FirebaseApp app}) => this;

  @override
  FirebaseAuthPlatform setInitialValues({
    PigeonUserDetails? currentUser,
    String? languageCode,
  }) {
    return this;
  }
}
