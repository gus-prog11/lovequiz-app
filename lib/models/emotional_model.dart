import 'package:cloud_firestore/cloud_firestore.dart';

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

class FavoriteAnswer {
  final String id;
  final String userId;
  final String question;
  final String answer;
  final String category;
  final String? partnerName;
  final Timestamp createdAt;

  FavoriteAnswer({
    required this.id,
    required this.userId,
    required this.question,
    required this.answer,
    required this.category,
    this.partnerName,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'question': question,
      'answer': answer,
      'category': category,
      'partnerName': partnerName,
      'createdAt': createdAt,
    };
  }

  factory FavoriteAnswer.fromMap(Map<String, dynamic> map) {
    return FavoriteAnswer(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      question: map['question'] ?? '',
      answer: map['answer'] ?? '',
      category: map['category'] ?? '',
      partnerName: map['partnerName'],
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }
}
