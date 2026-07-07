class Category {
  final String id;
  final String label;
  final String emoji;
  final String color;
  final bool isPremium;

  const Category({
    required this.id,
    required this.label,
    required this.emoji,
    required this.color,
    this.isPremium = false,
  });
}

const List<Category> categories = [
  Category(id: "romanticas", label: "Románticas", emoji: "💕", color: "pink"),
  Category(id: "calientes", label: "Calientes", emoji: "🔥", color: "red"),
  Category(id: "incomodas", label: "Incómodas", emoji: "😳", color: "orange"),
  Category(id: "divertidas", label: "Divertidas", emoji: "😂", color: "yellow"),
  Category(id: "extremas", label: "Extremas", emoji: "⚡", color: "purple"),
  Category(id: "locas", label: "Locas", emoji: "🤪", color: "cyan"),
  Category(id: "retos", label: "Retos", emoji: "🎯", color: "green"),
  Category(id: "viajes", label: "Viajes", emoji: "✈️", color: "blue", isPremium: true),
  Category(id: "familia", label: "Familia", emoji: "👨‍👩‍👧‍👦", color: "teal", isPremium: true),
  Category(id: "intimidad_profunda", label: "Intimidad Profunda", emoji: "💋", color: "rose", isPremium: true),
  Category(id: "futuro", label: "Futuro", emoji: "🔮", color: "indigo", isPremium: true),
  Category(id: "confesiones", label: "Confesiones", emoji: "🤫", color: "brown", isPremium: true),
  Category(id: "agradecimiento", label: "Agradecimiento", emoji: "🙏", color: "lime", isPremium: true),
];

Category? getCategoryById(String id) {
  try {
    return categories.firstWhere((c) => c.id == id);
  } catch (_) {
    return null;
  }
}
