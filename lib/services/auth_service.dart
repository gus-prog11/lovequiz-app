import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  // Inicia sesión con email y contraseña.
  static Future<UserCredential> login(String email, String password) async {
    return await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Registra un nuevo usuario con email y contraseña.
  static Future<UserCredential> register(String email, String password) async {
    return await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Inicia sesión con Google.
  static Future<UserCredential?> signInWithGoogle() async {
    debugPrint('[Auth] Iniciando Google Sign-In...');
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    debugPrint('[Auth] Google Sign-In result: $googleUser');
    if (googleUser == null) {
      debugPrint('[Auth] User cancelled the operation');
      return null;
    }
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    debugPrint('[Auth] Auth obtenida');
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    debugPrint('[Auth] Credential creada');
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  // Cierra la sesión de Google y Firebase.
  static Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
  }
}
