import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String alias;
  final String photoUrl;
  final int gamesPlayed;
  final Timestamp createdAt;
  final int? age;
  final String? gender;
  final String? city;
  final String? maritalStatus;
  final int totalGames;
  final int totalQuestions;
  final int totalMinutes;

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
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'alias': alias,
      'photoUrl': photoUrl,
      'gamesPlayed': gamesPlayed,
      'createdAt': createdAt,
      'age': age,
      'gender': gender,
      'city': city,
      'maritalStatus': maritalStatus,
      'totalGames': totalGames,
      'totalQuestions': totalQuestions,
      'totalMinutes': totalMinutes,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      alias: map['alias'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      gamesPlayed: map['gamesPlayed'] ?? 0,
      createdAt: map['createdAt'] ?? Timestamp.now(),
      age: map['age'],
      gender: map['gender'],
      city: map['city'],
      maritalStatus: map['maritalStatus'],
      totalGames: map['totalGames'] ?? 0,
      totalQuestions: map['totalQuestions'] ?? 0,
      totalMinutes: map['totalMinutes'] ?? 0,
    );
  }
}
