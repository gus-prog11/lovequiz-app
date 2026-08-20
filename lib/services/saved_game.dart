import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistencia ligera del juego en curso para ofrecer reanudación al volver
/// a la app después de un cierre forzado. Solo se guarda el código de sala y
/// los parámetros mínimos necesarios para reconstruir la ruta `/play`.
class SavedGame {
  static const _key = 'saved_game';

  final String roomCode;
  final String mode;
  final String p1;
  final String p2;
  final List<String> categories;
  final int timerSeconds;
  final String? playerName;
  final bool isHost;
  final int totalQuestions;

  SavedGame({
    required this.roomCode,
    required this.mode,
    required this.p1,
    required this.p2,
    required this.categories,
    required this.timerSeconds,
    this.playerName,
    required this.isHost,
    required this.totalQuestions,
  });

  Map<String, dynamic> toJson() => {
        'roomCode': roomCode,
        'mode': mode,
        'p1': p1,
        'p2': p2,
        'categories': categories,
        'timerSeconds': timerSeconds,
        'playerName': playerName,
        'isHost': isHost,
        'totalQuestions': totalQuestions,
      };

  factory SavedGame.fromJson(Map<String, dynamic> json) => SavedGame(
        roomCode: json['roomCode'] as String,
        mode: json['mode'] as String? ?? 'online',
        p1: json['p1'] as String? ?? 'Jugador 1',
        p2: json['p2'] as String? ?? 'Jugador 2',
        categories: (json['categories'] as List?)?.cast<String>() ?? [],
        timerSeconds: json['timerSeconds'] as int? ?? 0,
        playerName: json['playerName'] as String?,
        isHost: json['isHost'] as bool? ?? false,
        totalQuestions: json['totalQuestions'] as int? ?? 10,
      );

  static Future<void> save(SavedGame game) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(game.toJson()));
  }

  static Future<SavedGame?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return SavedGame.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      await prefs.remove(_key);
      return null;
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
