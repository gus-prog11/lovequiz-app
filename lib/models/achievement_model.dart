class AchievementModel {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int targetProgress;
  final String type;
  final bool isPremium;

  const AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.targetProgress,
    required this.type,
    this.isPremium = false,
  });

  static const List<AchievementModel> allAchievements = [
    AchievementModel(
      id: 'first_game',
      title: 'Primera Partida',
      description: 'Completa tu primera partida',
      icon: '🎮',
      targetProgress: 1,
      type: 'games',
    ),
    AchievementModel(
      id: '100_questions',
      title: '100 Preguntas',
      description: 'Responde 100 preguntas en total',
      icon: '💯',
      targetProgress: 100,
      type: 'questions',
    ),
    AchievementModel(
      id: '10_hours',
      title: '10 Horas',
      description: 'Juega 10 horas acumuladas',
      icon: '⏰',
      targetProgress: 600,
      type: 'minutes',
    ),
    AchievementModel(
      id: 'first_confession',
      title: 'Primera Confesión',
      description: 'Comparte tu primera confesión',
      icon: '💌',
      targetProgress: 1,
      type: 'confessions',
    ),
    AchievementModel(
      id: '30_days_streak',
      title: '30 Días Seguidos',
      description: 'Mantén una racha de 30 días',
      icon: '🔥',
      targetProgress: 30,
      type: 'streak',
    ),
    AchievementModel(
      id: '50_games',
      title: '50 Partidas',
      description: 'Completa 50 partidas',
      icon: '🏆',
      targetProgress: 50,
      type: 'games',
    ),
    AchievementModel(
      id: '500_questions',
      title: '500 Preguntas',
      description: 'Responde 500 preguntas',
      icon: '📚',
      targetProgress: 500,
      type: 'questions',
      isPremium: true,
    ),
    AchievementModel(
      id: 'first_memory',
      title: 'Primer Recuerdo',
      description: 'Guarda tu primer recuerdo importante',
      icon: '📸',
      targetProgress: 1,
      type: 'memories',
    ),
    AchievementModel(
      id: 'first_dream',
      title: 'Soñadores',
      description: 'Comparte tu primer sueño',
      icon: '🌙',
      targetProgress: 1,
      type: 'dreams',
    ),
    AchievementModel(
      id: 'first_goal',
      title: 'Metas Claras',
      description: 'Establece tu primera meta',
      icon: '🎯',
      targetProgress: 1,
      type: 'goals',
    ),
    AchievementModel(
      id: 'first_promise',
      title: 'Promesa Cumplida',
      description: 'Haz tu primera promesa',
      icon: '🤝',
      targetProgress: 1,
      type: 'promises',
    ),
    AchievementModel(
      id: '7_days_streak',
      title: 'Una Semana',
      description: 'Mantén una racha de 7 días',
      icon: '📅',
      targetProgress: 7,
      type: 'streak',
    ),
    AchievementModel(
      id: 'social_butterfly',
      title: 'Mariposa Social',
      description: 'Agrega 3 amigos',
      icon: '🦋',
      targetProgress: 3,
      type: 'friends',
    ),
    AchievementModel(
      id: '100_days_streak',
      title: 'Legendario',
      description: 'Mantén una racha de 100 días',
      icon: '👑',
      targetProgress: 100,
      type: 'streak',
      isPremium: true,
    ),
  ];
}

class UserAchievement {
  final String achievementId;
  final bool unlocked;
  final int progress;
  final DateTime? unlockedAt;

  UserAchievement({
    required this.achievementId,
    this.unlocked = false,
    this.progress = 0,
    this.unlockedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'achievementId': achievementId,
      'unlocked': unlocked,
      'progress': progress,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }

  factory UserAchievement.fromMap(Map<String, dynamic> map) {
    return UserAchievement(
      achievementId: map['achievementId'] ?? '',
      unlocked: map['unlocked'] ?? false,
      progress: map['progress'] ?? 0,
      unlockedAt: map['unlockedAt'] != null
          ? DateTime.parse(map['unlockedAt'])
          : null,
    );
  }
}

class StreakData {
  int currentStreak;
  int longestStreak;
  DateTime? lastPlayDate;

  StreakData({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastPlayDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastPlayDate': lastPlayDate?.toIso8601String(),
    };
  }

  factory StreakData.fromMap(Map<String, dynamic> map) {
    return StreakData(
      currentStreak: map['currentStreak'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
      lastPlayDate: map['lastPlayDate'] != null
          ? DateTime.parse(map['lastPlayDate'])
          : null,
    );
  }
}
