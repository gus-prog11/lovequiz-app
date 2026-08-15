import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para perfiles de pareja enlazados
// Modelo que representa un perfil de pareja con datos de ambos miembros.
class CoupleProfile {
  final String coupleId; // ID único de la pareja
  final String user1Id;
  final String user2Id;
  final String user1Name;
  final String user2Name;
  final String user1Photo;
  final String user2Photo;
  final Timestamp startDate; // Fecha en que empezaron
  final String status; // 'connected', 'pending', 'rejected'
  final Timestamp createdAt;

  // Constructor con los datos de ambos miembros de la pareja.
  CoupleProfile({
    required this.coupleId,
    required this.user1Id,
    required this.user2Id,
    required this.user1Name,
    required this.user2Name,
    this.user1Photo = '',
    this.user2Photo = '',
    required this.startDate,
    this.status = 'connected',
    required this.createdAt,
  });

  // Convierte el perfil de pareja a un mapa para Firestore.
  Map<String, dynamic> toMap() => {
    'coupleId': coupleId,
    'user1Id': user1Id,
    'user2Id': user2Id,
    'user1Name': user1Name,
    'user2Name': user2Name,
    'user1Photo': user1Photo,
    'user2Photo': user2Photo,
    'startDate': startDate,
    'status': status,
    'createdAt': createdAt,
  };

  // Crea un CoupleProfile a partir de un mapa de Firestore.
  factory CoupleProfile.fromMap(Map<String, dynamic> map) => CoupleProfile(
    coupleId: map['coupleId'] ?? '',
    user1Id: map['user1Id'] ?? '',
    user2Id: map['user2Id'] ?? '',
    user1Name: map['user1Name'] ?? 'Usuario',
    user2Name: map['user2Name'] ?? 'Pareja',
    user1Photo: map['user1Photo'] ?? '',
    user2Photo: map['user2Photo'] ?? '',
    startDate: map['startDate'] ?? Timestamp.now(),
    status: map['status'] ?? 'connected',
    createdAt: map['createdAt'] ?? Timestamp.now(),
  );

  // Crea una copia del perfil con campos actualizados opcionalmente.
  CoupleProfile copyWith({
    String? coupleId,
    String? user1Id,
    String? user2Id,
    String? user1Name,
    String? user2Name,
    String? user1Photo,
    String? user2Photo,
    Timestamp? startDate,
    String? status,
    Timestamp? createdAt,
  }) => CoupleProfile(
    coupleId: coupleId ?? this.coupleId,
    user1Id: user1Id ?? this.user1Id,
    user2Id: user2Id ?? this.user2Id,
    user1Name: user1Name ?? this.user1Name,
    user2Name: user2Name ?? this.user2Name,
    user1Photo: user1Photo ?? this.user1Photo,
    user2Photo: user2Photo ?? this.user2Photo,
    startDate: startDate ?? this.startDate,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
  );
}

/// Modelo para recuerdos con fotos
// Modelo que representa un recuerdo compartido por la pareja.
class Memory {
  final String id;
  final String coupleId;
  final String uploadedBy;
  final String title;
  final String description;
  final List<String> photoUrls;
  final String category; // 'photo', 'moment', 'trip', etc.
  final Timestamp createdAt;

  // Constructor del modelo de recuerdo.
  Memory({
    required this.id,
    required this.coupleId,
    required this.uploadedBy,
    required this.title,
    this.description = '',
    this.photoUrls = const [],
    this.category = 'moment',
    required this.createdAt,
  });

  // Convierte el recuerdo a un mapa para Firestore.
  Map<String, dynamic> toMap() => {
    'id': id,
    'coupleId': coupleId,
    'uploadedBy': uploadedBy,
    'title': title,
    'description': description,
    'photoUrls': photoUrls,
    'category': category,
    'createdAt': createdAt,
  };

  // Crea una instancia de Memory desde un mapa de Firestore.
  factory Memory.fromMap(Map<String, dynamic> map) => Memory(
    id: map['id'] ?? '',
    coupleId: map['coupleId'] ?? '',
    uploadedBy: map['uploadedBy'] ?? '',
    title: map['title'] ?? '',
    description: map['description'] ?? '',
    photoUrls: List<String>.from(map['photoUrls'] ?? []),
    category: map['category'] ?? 'moment',
    createdAt: map['createdAt'] ?? Timestamp.now(),
  );

  // Crea una copia del recuerdo con campos actualizados opcionalmente.
  Memory copyWith({
    String? id,
    String? coupleId,
    String? uploadedBy,
    String? title,
    String? description,
    List<String>? photoUrls,
    String? category,
    Timestamp? createdAt,
  }) => Memory(
    id: id ?? this.id,
    coupleId: coupleId ?? this.coupleId,
    uploadedBy: uploadedBy ?? this.uploadedBy,
    title: title ?? this.title,
    description: description ?? this.description,
    photoUrls: photoUrls ?? this.photoUrls,
    category: category ?? this.category,
    createdAt: createdAt ?? this.createdAt,
  );
}

/// Modelo para frases que los definen
// Modelo que representa una frase que define a la pareja.
class DefiningPhrase {
  final String id;
  final String coupleId;
  final String createdBy;
  final String phrase;
  final String author; // A quién se refiere
  final Timestamp createdAt;

  // Constructor de frase definitoria de pareja.
  DefiningPhrase({
    required this.id,
    required this.coupleId,
    required this.createdBy,
    required this.phrase,
    required this.author,
    required this.createdAt,
  });

  // Convierte la frase a un mapa para Firestore.
  Map<String, dynamic> toMap() => {
    'id': id,
    'coupleId': coupleId,
    'createdBy': createdBy,
    'phrase': phrase,
    'author': author,
    'createdAt': createdAt,
  };

  // Crea una DefiningPhrase desde un mapa de Firestore.
  factory DefiningPhrase.fromMap(Map<String, dynamic> map) => DefiningPhrase(
    id: map['id'] ?? '',
    coupleId: map['coupleId'] ?? '',
    createdBy: map['createdBy'] ?? '',
    phrase: map['phrase'] ?? '',
    author: map['author'] ?? '',
    createdAt: map['createdAt'] ?? Timestamp.now(),
  );
}

/// Modelo para promesas
// Modelo que representa una promesa hecha entre los miembros de la pareja.
class Promise {
  final String id;
  final String coupleId;
  final String createdBy;
  final String promise;
  final bool completed;
  final Timestamp createdAt;
  final Timestamp? completedAt;

  // Constructor de una promesa de pareja.
  Promise({
    required this.id,
    required this.coupleId,
    required this.createdBy,
    required this.promise,
    this.completed = false,
    required this.createdAt,
    this.completedAt,
  });

  // Convierte la promesa a un mapa para Firestore.
  Map<String, dynamic> toMap() => {
    'id': id,
    'coupleId': coupleId,
    'createdBy': createdBy,
    'promise': promise,
    'completed': completed,
    'createdAt': createdAt,
    'completedAt': completedAt,
  };

  // Crea una Promise desde un mapa de Firestore.
  factory Promise.fromMap(Map<String, dynamic> map) => Promise(
    id: map['id'] ?? '',
    coupleId: map['coupleId'] ?? '',
    createdBy: map['createdBy'] ?? '',
    promise: map['promise'] ?? '',
    completed: map['completed'] ?? false,
    createdAt: map['createdAt'] ?? Timestamp.now(),
    completedAt: map['completedAt'],
  );
}

/// Modelo para eventos emocionalmente especiales
// Modelo que representa un evento especial en la relación.
class SpecialEvent {  final String id;
  final String coupleId;
  final String title;
  final String description;
  final String emoji; // Para representación visual
  final Timestamp eventDate;
  final String? photoUrl;
  final Timestamp createdAt;

  // Constructor de un evento especial de la pareja.
  SpecialEvent({
    required this.id,
    required this.coupleId,
    required this.title,
    required this.description,
    this.emoji = '💕',
    required this.eventDate,
    this.photoUrl,
    required this.createdAt,
  });

  // Convierte el evento a un mapa para Firestore.
  Map<String, dynamic> toMap() => {
    'id': id,
    'coupleId': coupleId,
    'title': title,
    'description': description,
    'emoji': emoji,
    'eventDate': eventDate,
    'photoUrl': photoUrl,
    'createdAt': createdAt,
  };

  // Crea un SpecialEvent desde un mapa de Firestore.
  factory SpecialEvent.fromMap(Map<String, dynamic> map) => SpecialEvent(
    id: map['id'] ?? '',
    coupleId: map['coupleId'] ?? '',
    title: map['title'] ?? '',
    description: map['description'] ?? '',
    emoji: map['emoji'] ?? '💕',
    eventDate: map['eventDate'] ?? Timestamp.now(),
    photoUrl: map['photoUrl'],
    createdAt: map['createdAt'] ?? Timestamp.now(),
  );
}

/// Modelo para las respuestas de la "Pregunta del día".
///
/// Un documento por día (identificado por `dateKey` en formato YYYY-MM-DD)
/// guarda la misma pregunta y la respuesta de cada miembro de la pareja
/// (`answer1`/`answer2`, alineadas a `user1`/`user2` del perfil de pareja).
class DailyAnswer {
  final String id;
  final String coupleId;
  final String dateKey; // YYYY-MM-DD
  final String question;
  final String? answer1;
  final String? answer2;
  final Timestamp updatedAt;

  // Constructor de una respuesta diaria de la pareja.
  DailyAnswer({
    required this.id,
    required this.coupleId,
    required this.dateKey,
    required this.question,
    this.answer1,
    this.answer2,
    required this.updatedAt,
  });

  // Indica si ambos miembros ya respondieron la pregunta de ese día.
  bool get bothAnswered => answer1 != null && answer2 != null;

  // Convierte la respuesta diaria a un mapa para Firestore.
  Map<String, dynamic> toMap() => {
    'id': id,
    'coupleId': coupleId,
    'dateKey': dateKey,
    'question': question,
    'answer1': answer1,
    'answer2': answer2,
    'updatedAt': updatedAt,
  };

  // Crea un DailyAnswer desde un mapa de Firestore.
  factory DailyAnswer.fromMap(Map<String, dynamic> map) => DailyAnswer(
    id: map['id'] ?? '',
    coupleId: map['coupleId'] ?? '',
    dateKey: map['dateKey'] ?? '',
    question: map['question'] ?? '',
    answer1: map['answer1'] as String?,
    answer2: map['answer2'] as String?,
    updatedAt: map['updatedAt'] ?? Timestamp.now(),
  );
}

// Modelo que almacena las URLs de los momentos destacados de la pareja.
class MomentosDestacados {
  String fotoFavoritaUrl;
  String lugarEspecialUrl;
  String cancionUrl;

  // Constructor con URLs vacías por defecto.
  MomentosDestacados({
    this.fotoFavoritaUrl = '',
    this.lugarEspecialUrl = '',
    this.cancionUrl = '',
  });

  // Convierte los momentos destacados a un mapa para Firestore.
  Map<String, dynamic> toMap() => {
    'fotoFavoritaUrl': fotoFavoritaUrl,
    'lugarEspecialUrl': lugarEspecialUrl,
    'cancionUrl': cancionUrl,
  };

  // Crea MomentosDestacados desde un mapa de Firestore.
  factory MomentosDestacados.fromMap(Map<String, dynamic> map) =>
      MomentosDestacados(
        fotoFavoritaUrl: map['fotoFavoritaUrl'] ?? '',
        lugarEspecialUrl: map['lugarEspecialUrl'] ?? '',
        cancionUrl: map['cancionUrl'] ?? '',
      );

  // Crea una copia con campos actualizados opcionalmente.
  MomentosDestacados copyWith({
    String? fotoFavoritaUrl,
    String? lugarEspecialUrl,
    String? cancionUrl,
  }) => MomentosDestacados(
    fotoFavoritaUrl: fotoFavoritaUrl ?? this.fotoFavoritaUrl,
    lugarEspecialUrl: lugarEspecialUrl ?? this.lugarEspecialUrl,
    cancionUrl: cancionUrl ?? this.cancionUrl,
  );
}

// Modelo que agrega datos generales de la relación de la pareja.
class CoupleData {
  final int recuerdosCount;
  final int suenosCount;
  final int promesasCount;
  final int rachaJuntos;
  final List<TimelineItem> timeline;
  final MomentosDestacados momentos;

  // Constructor con valores por defecto para cada campo.
  CoupleData({
    this.recuerdosCount = 0,
    this.suenosCount = 0,
    this.promesasCount = 0,
    this.rachaJuntos = 0,
    this.timeline = const [],
    MomentosDestacados? momentos,
  }) : momentos = momentos ?? MomentosDestacados();

  // Crea una copia de CoupleData con campos actualizados.
  CoupleData copyWith({
    int? recuerdosCount,
    int? suenosCount,
    int? promesasCount,
    int? rachaJuntos,
    List<TimelineItem>? timeline,
    MomentosDestacados? momentos,
  }) => CoupleData(
    recuerdosCount: recuerdosCount ?? this.recuerdosCount,
    suenosCount: suenosCount ?? this.suenosCount,
    promesasCount: promesasCount ?? this.promesasCount,
    rachaJuntos: rachaJuntos ?? this.rachaJuntos,
    timeline: timeline ?? this.timeline,
    momentos: momentos ?? this.momentos,
  );
}

// Modelo que representa un elemento de la línea de tiempo de la pareja.
class TimelineItem {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String type;
  final Timestamp createdAt;

  // Constructor de un elemento de la línea de tiempo.
  TimelineItem({
    required this.id,
    required this.title,
    this.description = '',
    this.imageUrl = '',
    required this.type,
    required this.createdAt,
  });

  // Convierte el elemento a un mapa para Firestore.
  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'imageUrl': imageUrl,
    'type': type,
    'createdAt': createdAt,
  };

  // Crea un TimelineItem desde un mapa de Firestore.
  factory TimelineItem.fromMap(Map<String, dynamic> map) => TimelineItem(
    id: map['id'] ?? '',
    title: map['title'] ?? '',
    description: map['description'] ?? '',
    imageUrl: map['imageUrl'] ?? '',
    type: map['type'] ?? 'memory',
    createdAt: map['createdAt'] ?? Timestamp.now(),
  );
}
