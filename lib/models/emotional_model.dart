import 'package:cloud_firestore/cloud_firestore.dart';

// Modelo que representa un recuerdo emocional guardado por el usuario.
class MemoryModel {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String description;
  final String? imageUrl;
  final String? partnerId;
  final bool isFavorite;
  final Timestamp createdAt;
  final Timestamp? date;

  // Constructor del modelo de recuerdo emocional.
  MemoryModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.description,
    this.imageUrl,
    this.partnerId,
    this.isFavorite = false,
    required this.createdAt,
    this.date,
  });

  // Convierte el recuerdo a un mapa para Firestore.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'partnerId': partnerId,
      'isFavorite': isFavorite,
      'createdAt': createdAt,
      'date': date,
    };
  }

  // Crea un MemoryModel desde un mapa de Firestore.
  factory MemoryModel.fromMap(Map<String, dynamic> map) {
    return MemoryModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      type: map['type'] ?? 'memory',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'],
      partnerId: map['partnerId'],
      isFavorite: map['isFavorite'] ?? false,
      createdAt: map['createdAt'] ?? Timestamp.now(),
      date: map['date'],
    );
  }

  // Crea una copia del recuerdo con campos actualizados opcionalmente.
  MemoryModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? description,
    String? imageUrl,
    String? partnerId,
    bool? isFavorite,
    Timestamp? createdAt,
    Timestamp? date,
  }) {
    return MemoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      partnerId: partnerId ?? this.partnerId,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      date: date ?? this.date,
    );
  }
}

// Modelo que representa una respuesta favorita guardada del usuario.
class FavoriteAnswer {
  final String id;
  final String userId;
  final String coupleId;
  final String question;
  final String answer;
  final String category;
  final String? partnerName;
  final Timestamp createdAt;

  // Constructor de una respuesta favorita.
  FavoriteAnswer({
    required this.id,
    required this.userId,
    required this.coupleId,
    required this.question,
    required this.answer,
    required this.category,
    this.partnerName,
    required this.createdAt,
  });

  // Convierte la respuesta favorita a un mapa para Firestore.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'coupleId': coupleId,
      'question': question,
      'answer': answer,
      'category': category,
      'partnerName': partnerName,
      'createdAt': createdAt,
    };
  }

  // Crea un FavoriteAnswer desde un mapa de Firestore.
  factory FavoriteAnswer.fromMap(Map<String, dynamic> map) {
    return FavoriteAnswer(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      coupleId: map['coupleId'] ?? '',
      question: map['question'] ?? '',
      answer: map['answer'] ?? '',
      category: map['category'] ?? '',
      partnerName: map['partnerName'],
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }
}
