import 'package:cloud_firestore/cloud_firestore.dart';

// Modelo de datos que representa a un usuario dentro de la aplicación.
class UserModel {
  final String uid;
  final String email;
  final String alias;
  final String photoUrl;
  final String? photoPublicId;
  final int gamesPlayed;
  final Timestamp createdAt;
  final int? age;
  final String? gender;
  final String? city;
  final String? maritalStatus;
  final int totalGames;
  final int totalQuestions;
  final int totalMinutes;
  final String? partnerId;
  final String? coupleId;

  // Constructor con campos requeridos y opcionales del usuario.
  UserModel({
    required this.uid,
    required this.email,
    required this.alias,
    required this.photoUrl,
    required this.gamesPlayed,
    required this.createdAt,
    this.age,
    this.gender,
    this.city,
    this.maritalStatus,
    this.totalGames = 0,
    this.totalQuestions = 0,
    this.totalMinutes = 0,
    this.partnerId,
    this.coupleId,
    this.photoPublicId,
  });

  // Convierte el modelo a un mapa para Firestore.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'alias': alias,
      'photoUrl': photoUrl,
      'photoPublicId': photoPublicId,
      'gamesPlayed': gamesPlayed,
      'createdAt': createdAt,
      'age': age,
      'gender': gender,
      'city': city,
      'maritalStatus': maritalStatus,
      'totalGames': totalGames,
      'totalQuestions': totalQuestions,
      'totalMinutes': totalMinutes,
      if (partnerId != null) 'partnerId': partnerId,
      if (coupleId != null) 'coupleId': coupleId,
    };
  }

  // Crea una instancia de UserModel a partir de un mapa de Firestore.
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      alias: map['alias'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      photoPublicId: map['photoPublicId'],
      gamesPlayed: map['gamesPlayed'] ?? 0,
      createdAt: map['createdAt'] ?? Timestamp.now(),
      age: map['age'],
      gender: map['gender'],
      city: map['city'],
      maritalStatus: map['maritalStatus'],
      totalGames: map['totalGames'] ?? 0,
      totalQuestions: map['totalQuestions'] ?? 0,
      totalMinutes: map['totalMinutes'] ?? 0,
      partnerId: map['partnerId'],
      coupleId: map['coupleId'],
    );
  }

  // Crea una copia del modelo con campos actualizados opcionalmente.
  UserModel copyWith({
    String? photoPublicId,
    String? photoUrl,
    String? partnerId,
    String? coupleId,
  }) {
    return UserModel(
      uid: uid,
      email: email,

      alias: alias,
      photoUrl: photoUrl ?? this.photoUrl,
      photoPublicId: photoPublicId ?? this.photoPublicId,
      gamesPlayed: gamesPlayed,
      createdAt: createdAt,
      age: age,
      gender: gender,
      city: city,
      maritalStatus: maritalStatus,
      totalGames: totalGames,
      totalQuestions: totalQuestions,
      totalMinutes: totalMinutes,
      partnerId: partnerId ?? this.partnerId,
      coupleId: coupleId ?? this.coupleId,
    );
  }
}
