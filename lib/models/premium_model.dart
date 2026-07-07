class PremiumModel {
  final bool isPremium;
  final DateTime? expiresAt;
  final String? themeId;
  final List<String> unlockedCategories;
  final List<String> unlockedChallenges;

  PremiumModel({
    this.isPremium = false,
    this.expiresAt,
    this.themeId,
    this.unlockedCategories = const [],
    this.unlockedChallenges = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'isPremium': isPremium,
      'expiresAt': expiresAt?.toIso8601String(),
      'themeId': themeId,
      'unlockedCategories': unlockedCategories,
      'unlockedChallenges': unlockedChallenges,
    };
  }

  factory PremiumModel.fromMap(Map<String, dynamic> map) {
    return PremiumModel(
      isPremium: map['isPremium'] ?? false,
      expiresAt: map['expiresAt'] != null
          ? DateTime.parse(map['expiresAt'])
          : null,
      themeId: map['themeId'],
      unlockedCategories:
          List<String>.from(map['unlockedCategories'] ?? []),
      unlockedChallenges:
          List<String>.from(map['unlockedChallenges'] ?? []),
    );
  }

  PremiumModel copyWith({
    bool? isPremium,
    DateTime? expiresAt,
    String? themeId,
    List<String>? unlockedCategories,
    List<String>? unlockedChallenges,
  }) {
    return PremiumModel(
      isPremium: isPremium ?? this.isPremium,
      expiresAt: expiresAt ?? this.expiresAt,
      themeId: themeId ?? this.themeId,
      unlockedCategories: unlockedCategories ?? this.unlockedCategories,
      unlockedChallenges: unlockedChallenges ?? this.unlockedChallenges,
    );
  }
}

class AppTheme {
  final String id;
  final String name;
  final String description;
  final bool isPremium;

  const AppTheme({
    required this.id,
    required this.name,
    required this.description,
    this.isPremium = false,
  });

  static const List<AppTheme> availableThemes = [
    AppTheme(id: 'default', name: 'Clásico', description: 'Tema rosado por defecto', isPremium: false),
    AppTheme(id: 'ocean', name: 'Océano', description: 'Tonos azules profundos', isPremium: true),
    AppTheme(id: 'sunset', name: 'Atardecer', description: 'Naranjas y dorados cálidos', isPremium: true),
    AppTheme(id: 'forest', name: 'Bosque', description: 'Verdes naturales', isPremium: true),
    AppTheme(id: 'midnight', name: 'Medianoche', description: 'Púrpuras y negros elegantes', isPremium: true),
    AppTheme(id: 'rosegold', name: 'Rose Gold', description: 'Oro rosado lujoso', isPremium: true),
  ];
}

const List<String> premiumCategories = [
  'viajes',
  'familia',
  'intimidad_profunda',
  'futuro',
  'confesiones',
  'agradecimiento',
];

const List<String> premiumChallenges = [
  'retos_sensoriales',
  'retos_salidas',
  'retos_sorpresa',
  'retos_conexion',
  'retos_aventura',
];
