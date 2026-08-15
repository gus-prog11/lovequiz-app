import 'package:firebase_core/firebase_core.dart';

// Future de inicialización de Firebase lanzado en main() antes del primer
// frame, para que el splash no espere plugins nativos. El SplashScreen lo
// espera antes de verificar la sesión. Se deja aquí (no en main.dart) para
// evitar una dependencia circular con la pantalla del splash.
Future<FirebaseApp>? firebaseInitFuture;
