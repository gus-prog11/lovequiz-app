import 'package:cloud_firestore/cloud_firestore.dart';

class VoiceMemory {
  final String id;
  final String gameId;
  final String coupleId;
  final String displayTitle;
  final String question;
  final String player1Id;
  final String player2Id;
  final String player1AudioUrl;
  final String player2AudioUrl;
  final String? player1PublicId;
  final String? player2PublicId;
  final Timestamp? answeredAtPlayer1;
  final Timestamp? answeredAtPlayer2;
  final Timestamp createdAt;
  final Timestamp expiresAt;
  final bool savedByPlayer1;
  final bool savedByPlayer2;
  final bool dayReminderSent;
  final bool finalReminderSent;

  const VoiceMemory({
    required this.id,
    required this.gameId,
    required this.coupleId,
    required this.displayTitle,
    required this.question,
    required this.player1Id,
    required this.player2Id,
    required this.player1AudioUrl,
    required this.player2AudioUrl,
    this.player1PublicId,
    this.player2PublicId,
    this.answeredAtPlayer1,
    this.answeredAtPlayer2,
    required this.createdAt,
    required this.expiresAt,
    this.savedByPlayer1 = false,
    this.savedByPlayer2 = false,
    this.dayReminderSent = false,
    this.finalReminderSent = false,
  });

  bool get isPermanent => savedByPlayer1 && savedByPlayer2;

  Map<String, dynamic> toMap() => {
    'gameId': gameId,
    'coupleId': coupleId,
    'displayTitle': displayTitle,
    'question': question,
    'player1Id': player1Id,
    'player2Id': player2Id,
    'player1AudioUrl': player1AudioUrl,
    'player2AudioUrl': player2AudioUrl,
    'player1PublicId': player1PublicId ?? '',
    'player2PublicId': player2PublicId ?? '',
    'answeredAtPlayer1': answeredAtPlayer1,
    'answeredAtPlayer2': answeredAtPlayer2,
    'createdAt': createdAt,
    'expiresAt': expiresAt,
    'savedByPlayer1': savedByPlayer1,
    'savedByPlayer2': savedByPlayer2,
    'dayReminderSent': dayReminderSent,
    'finalReminderSent': finalReminderSent,
  };

  factory VoiceMemory.fromMap(Map<String, dynamic> map, String id) =>
      VoiceMemory(
        id: id,
        gameId: map['gameId'] as String? ?? '',
        coupleId: map['coupleId'] as String? ?? '',
        displayTitle: map['displayTitle'] as String? ?? 'Recuerdo de voz',
        question: map['question'] as String? ?? '',
        player1Id: map['player1Id'] as String? ?? '',
        player2Id: map['player2Id'] as String? ?? '',
        player1AudioUrl: map['player1AudioUrl'] as String? ?? '',
        player2AudioUrl: map['player2AudioUrl'] as String? ?? '',
        player1PublicId: map['player1PublicId'] as String? ?? '',
        player2PublicId: map['player2PublicId'] as String? ?? '',
        answeredAtPlayer1: map['answeredAtPlayer1'] as Timestamp?,
        answeredAtPlayer2: map['answeredAtPlayer2'] as Timestamp?,
        createdAt: map['createdAt'] as Timestamp? ?? Timestamp.now(),
        expiresAt: map['expiresAt'] as Timestamp? ?? Timestamp.now(),
        savedByPlayer1: map['savedByPlayer1'] as bool? ?? false,
        savedByPlayer2: map['savedByPlayer2'] as bool? ?? false,
        dayReminderSent: map['dayReminderSent'] as bool? ?? false,
        finalReminderSent: map['finalReminderSent'] as bool? ?? false,
      );
}
