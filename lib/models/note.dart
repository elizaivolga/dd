import 'package:uuid/uuid.dart';

class Note {
  final String id;
  final String title;
  final String content;
  final String category;
  final String? imagePath;
  final DateTime createdAt;
  final DateTime? updatedAt;

  static const List<String> defaultCategories = [
    'Личное',
    'Работа',
    'Учеба',
    'Идеи',
    'Другое',
  ];

  Note({
    String? id,
    required this.title,
    String? content, // Сделали необязательным
    required this.category,
    this.imagePath,
    DateTime? createdAt,
    this.updatedAt,
  })  : id = id ?? const Uuid().v4(),
        content = content ?? '', // Значение по умолчанию
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      category: map['category'],
      imagePath: map['imagePath'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }
}