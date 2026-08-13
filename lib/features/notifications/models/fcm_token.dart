import 'package:cloud_firestore/cloud_firestore.dart';

/// Token FCM registrado para un dispositivo del usuario.
/// Se guarda en users/{uid}/fcmTokens/{token}.
class FcmToken {
  final String token;
  final Timestamp? createdAt;
  final Timestamp? lastSeen;

  const FcmToken({
    required this.token,
    this.createdAt,
    this.lastSeen,
  });

  factory FcmToken.fromMap(Map<String, dynamic> map, String id) => FcmToken(
        token: map['token'] as String? ?? id,
        createdAt: map['createdAt'] as Timestamp?,
        lastSeen: map['lastSeen'] as Timestamp?,
      );
}
