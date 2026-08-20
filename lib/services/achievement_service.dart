import 'package:LoveQuiz/models/achievement_model.dart';
import 'package:LoveQuiz/services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AchievementService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String get _uid => FirebaseAuth.instance.currentUser!.uid;

  // Caché en memoria para evitar parpadeos al navegar.
  static StreakData? _cachedStreak;
  static Map<String, dynamic>? _cachedStats;

  // Inicializa todos los logros desbloqueables para el usuario.
  //
  // Solo crea los documentos si aún no existen: si ya se inicializaron no
  // toca nada para no resetear el progreso acumulado.
  static Future<void> initAchievements() async {
    final userDoc = await _db.collection('users').doc(_uid).get();
    if (!userDoc.exists) return;
    final existing = await _db
        .collection('users')
        .doc(_uid)
        .collection('achievements')
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return;
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
  //
  // `cumulative` suma al progreso existente (p. ej. preguntas respondidas).
  // Con `cumulative: false` el progreso se toma como el máximo visto (racha
  // de días, número de amigos): acumular ese valor recontaría cada refresco.
  //
  // Usa una transacción (lectura+escritura atómicas) para que dos
  // actualizaciones concurrentes no se pisen la subida, y crea el documento
  // si no existe para que los logros desbloqueen también en cuentas que se
  // registraron antes de la inicialización de logros.
  static Future<void> updateProgress(
    String achievementId,
    int progress, {
    bool cumulative = true,
  }) async {
    final ref = _db
        .collection('users')
        .doc(_uid)
        .collection('achievements')
        .doc(achievementId);
    final achievement = AchievementModel.allAchievements.firstWhere(
      (a) => a.id == achievementId,
    );
    await _db.runTransaction((txn) async {
      final doc = await txn.get(ref);
      final current = doc.exists
          ? UserAchievement.fromMap(doc.data()!)
          : UserAchievement(achievementId: achievementId);
      if (current.unlocked) return;
      final newProgress = cumulative
          ? current.progress + progress
          : (current.progress > progress ? current.progress : progress);
      final unlocked = newProgress >= achievement.targetProgress;
      txn.set(
        ref,
        UserAchievement(
          achievementId: achievementId,
          progress: newProgress,
          unlocked: unlocked,
          unlockedAt: unlocked
              ? (current.unlockedAt ?? DateTime.now())
              : null,
        ).toMap(),
      );
    });

    // Notificación in-app si el logro se acaba de desbloquear.
    try {
      final snap = await ref.get();
      if (snap.exists) {
        final data = snap.data();
        if (data != null && data['unlocked'] == true) {
          NotificationService.achievement(
            achievementId: achievementId,
            achievementName: '${achievement.icon} ${achievement.title}',
          );
        }
      }
    } catch (_) {}
  }

  // Verifica y actualiza la racha diaria de juego del usuario.
  // Otorga 1 corazón por día jugado (máx 3). Si la racha se rompe,
  // guarda la racha anterior para que el usuario pueda recuperarla
  // gastando un corazón.
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
      // Primera vez que juega.
      streak.currentStreak = 1;
      if (streak.hearts < streak.maxHearts) streak.hearts++;
    } else {
      final last = DateTime(
        streak.lastPlayDate!.year,
        streak.lastPlayDate!.month,
        streak.lastPlayDate!.day,
      );
      final diff = today.difference(last).inDays;
      if (diff == 1) {
        // Día consecutivo: avanza racha y da corazón.
        streak.currentStreak++;
        if (streak.hearts < streak.maxHearts) streak.hearts++;
      } else if (diff > 1) {
        // Racha rota: guarda la anterior para recuperación.
        if (streak.currentStreak > streak.previousStreak) {
          streak.previousStreak = streak.currentStreak;
        }
        streak.currentStreak = 1;
      }
      // diff == 0: mismo día, no cambia nada.
    }
    if (streak.currentStreak > streak.longestStreak) {
      streak.longestStreak = streak.currentStreak;
    }
    streak.lastPlayDate = now;
    await ref.update({'streak': streak.toMap()});
    _cachedStreak = streak;
    final streakIds = ['7_days_streak', '30_days_streak', '100_days_streak'];
    for (final id in streakIds) {
      await updateProgress(id, streak.currentStreak, cumulative: false);
    }
  }

  // Recupera la racha gastando 1 corazón.
  // Devuelve true si se recuperó, false si no hay corazones o racha previa.
  static Future<bool> recoverStreak() async {
    final ref = _db.collection('users').doc(_uid);
    final doc = await ref.get();
    if (!doc.exists) return false;
    final data = doc.data()!;
    StreakData streak;
    if (data.containsKey('streak')) {
      streak = StreakData.fromMap(data['streak'] as Map<String, dynamic>);
    } else {
      return false;
    }
    if (streak.hearts <= 0 || streak.previousStreak <= 0) return false;
    streak.hearts--;
    streak.currentStreak = streak.previousStreak;
    streak.previousStreak = 0;
    if (streak.currentStreak > streak.longestStreak) {
      streak.longestStreak = streak.currentStreak;
    }
    await ref.update({'streak': streak.toMap()});
    _cachedStreak = streak;
    final streakIds = ['7_days_streak', '30_days_streak', '100_days_streak'];
    for (final id in streakIds) {
      await updateProgress(id, streak.currentStreak, cumulative: false);
    }
    return true;
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
    await updateProgress('social_butterfly', count, cumulative: false);
  }
}
