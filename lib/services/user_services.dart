import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Crea un nuevo usuario en Firestore.
  static Future<void> createUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  // Obtiene los datos de un usuario por su UID.
  static Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();

    if (!doc.exists) return null;

    return UserModel.fromMap(doc.data()!);
  }

  // Verifica si existe el perfil de un usuario.
  static Future<bool> userProfileExists(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists;
  }

  // Actualiza el alias de un usuario.
  static Future<void> updateAlias(String uid, String alias) async {
    await _db.collection('users').doc(uid).update({'alias': alias});
  }

  // Actualiza los campos del usuario sin borrar datos existentes.
  static Future<void> updateUser(String uid, UserModel user) async {
    await _db.collection('users').doc(uid).set(
      user.toMap(),
      SetOptions(merge: true),
    );
  }

  // Actualiza solo la URL de la foto del usuario.
  static Future<void> updatePhotoUrl(String uid, String photoUrl) async {
    await _db.collection('users').doc(uid).set({
      'photoUrl': photoUrl,
    }, SetOptions(merge: true));
  }

  // Actualiza la URL y el ID público de la foto del usuario.
  static Future<void> updatePhoto(
    String uid,
    String photoUrl,
    String photoPublicId,
  ) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'photoUrl': photoUrl,
      'photoPublicId': photoPublicId,
    });
  }
}
