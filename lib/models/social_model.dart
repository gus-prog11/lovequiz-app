// Modelo que representa un amigo en la red social de la app.
class FriendModel {
  final String uid;
  final String alias;
  final String? photoUrl;
  final String status;
  final DateTime? since;

  // Constructor de un modelo de amigo con su estado.
  FriendModel({
    required this.uid,
    required this.alias,
    this.photoUrl,
    this.status = 'pending',
    this.since,
  });

  // Convierte el amigo a un mapa para Firestore.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'alias': alias,
      'photoUrl': photoUrl,
      'status': status,
      'since': since?.toIso8601String(),
    };
  }

  // Crea un FriendModel desde un mapa de Firestore.
  factory FriendModel.fromMap(Map<String, dynamic> map) {
    return FriendModel(
      uid: map['uid'] ?? '',
      alias: map['alias'] ?? '',
      photoUrl: map['photoUrl'],
      status: map['status'] ?? 'pending',
      since: map['since'] != null ? DateTime.parse(map['since']) : null,
    );
  }
}

// Modelo que representa una invitación de amistad enviada o recibida.
class InvitationModel {
  final String id;
  final String fromUid;
  final String fromAlias;
  final String toUid;
  final String status;
  final DateTime createdAt;

  // Constructor de una invitación con remitente y destinatario.
  InvitationModel({
    required this.id,
    required this.fromUid,
    required this.fromAlias,
    required this.toUid,
    this.status = 'pending',
    required this.createdAt,
  });

  // Convierte la invitación a un mapa para Firestore.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fromUid': fromUid,
      'fromAlias': fromAlias,
      'toUid': toUid,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Crea un InvitationModel desde un mapa de Firestore.
  factory InvitationModel.fromMap(Map<String, dynamic> map) {
    return InvitationModel(
      id: map['id'] ?? '',
      fromUid: map['fromUid'] ?? '',
      fromAlias: map['fromAlias'] ?? '',
      toUid: map['toUid'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }
}

// Modelo que almacena las estadísticas globales de juego del usuario.
class GameStats {
  int totalGames;
  int totalQuestions;
  int totalMinutes;
  int totalConfessions;
  int totalMemories;
  int totalFriends;
  int currentStreak;
  int longestStreak;

  // Constructor de estadísticas con valores por defecto en cero.
  GameStats({
    this.totalGames = 0,
    this.totalQuestions = 0,
    this.totalMinutes = 0,
    this.totalConfessions = 0,
    this.totalMemories = 0,
    this.totalFriends = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
  });

  // Convierte las estadísticas a un mapa para Firestore.
  Map<String, dynamic> toMap() {
    return {
      'totalGames': totalGames,
      'totalQuestions': totalQuestions,
      'totalMinutes': totalMinutes,
      'totalConfessions': totalConfessions,
      'totalMemories': totalMemories,
      'totalFriends': totalFriends,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
    };
  }

  // Crea un GameStats desde un mapa de Firestore.
  factory GameStats.fromMap(Map<String, dynamic> map) {
    return GameStats(
      totalGames: map['totalGames'] ?? 0,
      totalQuestions: map['totalQuestions'] ?? 0,
      totalMinutes: map['totalMinutes'] ?? 0,
      totalConfessions: map['totalConfessions'] ?? 0,
      totalMemories: map['totalMemories'] ?? 0,
      totalFriends: map['totalFriends'] ?? 0,
      currentStreak: map['currentStreak'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
    );
  }
}
