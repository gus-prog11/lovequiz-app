// Convierte various tipos de entrada a una lista válida de IDs de categorías.
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

// Convierte various tipos de entrada a un entero válido para el total de preguntas.
int normalizeTotalQuestions(dynamic value, {int fallback = 30}) {
  if (value is int) return value;
  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }
  return fallback;
}

// Convierte various tipos de entrada a un entero válido para los segundos del temporizador.
int normalizeTimerSeconds(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }
  return fallback;
}
