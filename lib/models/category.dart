class Category {
  final String id;
  final String label;
  final String emoji;
  final String color;

  const Category({
    required this.id,
    required this.label,
    required this.emoji,
    required this.color,
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
];

Category? getCategoryById(String id) {
  try {
    return categories.firstWhere((c) => c.id == id);
  } catch (_) {
    return null;
  }
}
