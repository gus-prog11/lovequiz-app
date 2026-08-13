import 'package:LoveQuiz/models/achievement_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AchievementService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String get _uid => FirebaseAuth.instance.currentUser!.uid;

  // Caché en memoria para evitar parpadeos al navegar.
  static StreakData? _cachedStreak;
  static Map<String, dynamic>? _cachedStats;

  // Inicializa todos los logros desbloqueables para el usuario.
  static Future<void> initAchievements() async {
    final doc = await _db.collection('users').doc(_uid).get();
    if (!doc.exists || doc.data()!.containsKey('achievements')) return;
    final batch = _db.batch();
    for (final a in AchievementModel.allAchievements) {
      final ref = _db
          .collection('users')
          .doc(_uid)
          .collection('achievements')
          .doc(a.id);
      batch.set(ref, UserAchievement(achievementId: a.id).toMap());
    }
    await batch.commit();
  }

  // Escucha los logros del usuario en tiempo real.
  static Stream<QuerySnapshot> achievementsStream() {
    return _db
        .collection('users')
        .doc(_uid)
        .collection('achievements')
        .snapshots();
  }

  // Actualiza el progreso de un logro y lo desbloquea si se alcanza.
  static Future<void> updateProgress(String achievementId, int progress) async {
    final ref = _db
        .collection('users')
        .doc(_uid)
        .collection('achievements')
        .doc(achievementId);
    final doc = await ref.get();
    if (!doc.exists) return;
    final current = UserAchievement.fromMap(doc.data()!);
    if (current.unlocked) return;
    final achievement = AchievementModel.allAchievements.firstWhere(
      (a) => a.id == achievementId,
    );
    final newProgress = current.progress + progress;
    final unlocked = newProgress >= achievement.targetProgress;
    await ref.update({
      'progress': newProgress,
      'unlocked': unlocked,
      'unlockedAt': unlocked ? DateTime.now().toIso8601String() : null,
    });
  }

  // Verifica y actualiza la racha diaria de juego del usuario.
  static Future<void> checkAndUpdateStreak() async {
    final ref = _db.collection('users').doc(_uid);
    final doc = await ref.get();
    if (!doc.exists) return;
    final data = doc.data()!;
    StreakData streak;
    if (data.containsKey('streak')) {
      streak = StreakData.fromMap(data['streak'] as Map<String, dynamic>);
    } else {
      streak = StreakData();
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (streak.lastPlayDate == null) {
      streak.currentStreak = 1;
    } else {
      final last = DateTime(
        streak.lastPlayDate!.year,
        streak.lastPlayDate!.month,
        streak.lastPlayDate!.day,
      );
      final diff = today.difference(last).inDays;
      if (diff == 1) {
        streak.currentStreak++;
      } else if (diff > 1) {
        streak.currentStreak = 1;
      }
    }
    if (streak.currentStreak > streak.longestStreak) {
      streak.longestStreak = streak.currentStreak;
    }
    streak.lastPlayDate = now;
    await ref.update({'streak': streak.toMap()});
    final streakIds = ['7_days_streak', '30_days_streak', '100_days_streak'];
    for (final id in streakIds) {
      await updateProgress(id, streak.currentStreak);
    }
  }

  // Obtiene los datos de racha actual del usuario.
  static Future<StreakData> getStreak() async {
    if (_cachedStreak != null) return _cachedStreak!;
    final doc = await _db.collection('users').doc(_uid).get();
    if (!doc.exists || !doc.data()!.containsKey('streak')) {
      _cachedStreak = StreakData();
      return _cachedStreak!;
    }
    _cachedStreak = StreakData.fromMap(
      doc.data()!['streak'] as Map<String, dynamic>,
    );
    return _cachedStreak!;
  }

  // Refresca la caché de racha desde Firestore.
  static Future<StreakData> refreshStreak() async {
    final doc = await _db.collection('users').doc(_uid).get();
    if (!doc.exists || !doc.data()!.containsKey('streak')) {
      _cachedStreak = StreakData();
    } else {
      _cachedStreak = StreakData.fromMap(
        doc.data()!['streak'] as Map<String, dynamic>,
      );
    }
    return _cachedStreak!;
  }

  // Obtiene las estadísticas generales del usuario con caché.
  static Future<Map<String, dynamic>?> getUserStats() async {
    if (_cachedStats != null) return _cachedStats;
    final doc = await _db.collection('users').doc(_uid).get();
    if (!doc.exists) return null;
    _cachedStats = doc.data();
    return _cachedStats;
  }

  // Refresca la caché de estadísticas desde Firestore.
  static Future<Map<String, dynamic>?> refreshUserStats() async {
    final doc = await _db.collection('users').doc(_uid).get();
    _cachedStats = doc.data();
    return _cachedStats;
  }

  // Invalida la caché para forzar recarga en la próxima lectura.
  static void invalidateCache() {
    _cachedStreak = null;
    _cachedStats = null;
  }

  // Actualiza las estadísticas de juego y progresos de logros.
  static Future<void> updateGameStats(int questions, int minutes) async {
    invalidateCache();
    final ref = _db.collection('users').doc(_uid);
    await ref.update({
      'totalGames': FieldValue.increment(1),
      'totalQuestions': FieldValue.increment(questions),
      'totalMinutes': FieldValue.increment(minutes),
    });
    await updateProgress('first_game', 1);
    await updateProgress('100_questions', questions);
    await updateProgress('500_questions', questions);
    await updateProgress('50_games', 1);
    await updateProgress('10_hours', minutes);
    await checkAndUpdateStreak();
  }

  // Actualiza el progreso de logros relacionados con recuerdos.
  static Future<void> updateMemoryStats(String type) async {
    await updateProgress('first_memory', 1);
    switch (type) {
      case 'dream':
        await updateProgress('first_dream', 1);
        break;
      case 'goal':
        await updateProgress('first_goal', 1);
        break;
      case 'promise':
        await updateProgress('first_promise', 1);
        break;
    }
  }

  // Actualiza el progreso del logro de primera confesión.
  static Future<void> updateConfessionStats() async {
    await updateProgress('first_confession', 1);
  }

  // Actualiza el progreso del logro de amigos sociales.
  static Future<void> updateFriendStats(int count) async {
    await updateProgress('social_butterfly', count);
  }
}
