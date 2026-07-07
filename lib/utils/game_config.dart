List<String> normalizeCategories(
  dynamic categories, {
  List<String> fallback = const [],
}) {
  if (categories is List) {
    return categories
        .map((value) => value.toString())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  return List<String>.from(fallback);
}

int normalizeTotalQuestions(dynamic value, {int fallback = 30}) {
  if (value is int) return value;
  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }
  return fallback;
}

int normalizeTimerSeconds(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }
  return fallback;
}
