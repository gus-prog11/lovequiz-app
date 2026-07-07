import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  //Login con email y password
  static Future<UserCredential> login(String email, String password) async {
    return await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  //Registro con email y password
  static Future<UserCredential> register(String email, String password) async {
    return await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  //Login con Google
  static Future<UserCredential?> signInWithGoogle() async {
    print("Iniciando Google Sign-In...");
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    print("Google Sign-In result: $googleUser");
    if (googleUser == null) {
      print("User cancelled the operation");
      return null;
    }
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    print("Auth obtenida");
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    print("Credential creada");
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  //Cerrar sesión
  static Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
  }
}
