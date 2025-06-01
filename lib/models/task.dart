import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

enum TaskDifficulty {
  easy,    // Легкая
  medium,  // Средняя
  hard     // Сложная
}

class Task {
  final String id;
  final String title;
  final String? description;
  final DateTime dueDate;
  bool isCompleted;
  final DateTime createdAt;
  final TaskDifficulty difficulty;
  final List<String> subTasks;
  int experiencePoints;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.dueDate,
    this.isCompleted = false,
    required this.createdAt,
    this.difficulty = TaskDifficulty.easy,
    this.subTasks = const [],
    this.experiencePoints = 0,
  });

  // Метод для получения очков опыта в зависимости от сложности
  int getExperiencePoints() {
    switch (difficulty) {
      case TaskDifficulty.easy:
        return 10;
      case TaskDifficulty.medium:
        return 15;
      case TaskDifficulty.hard:
        return 20;
      default:
        return 10; // По умолчанию как за легкую задачу
    }
  }

  Color getDifficultyColor() {
    switch (difficulty) {
      case TaskDifficulty.hard:
        return Colors.red.shade100;
      case TaskDifficulty.medium:
        return Colors.orange.shade100;
      case TaskDifficulty.easy:
        return Colors.green.shade100;
    }
  }

  Color getDifficultyIconColor() {
    switch (difficulty) {
      case TaskDifficulty.hard:
        return Colors.red;
      case TaskDifficulty.medium:
        return Colors.orange;
      case TaskDifficulty.easy:
        return Colors.green;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'isCompleted': isCompleted ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'difficulty': difficulty.index,
      'subTasks': subTasks.isNotEmpty ? subTasks : null, // Изменено здесь
      'experiencePoints': experiencePoints,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      dueDate: DateTime.parse(map['dueDate']),
      isCompleted: map['isCompleted'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
      difficulty: TaskDifficulty.values[map['difficulty']],
      subTasks: List<String>.from(map['subTasks'] ?? []),
      experiencePoints: map['experiencePoints'] ?? 0,
    );
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isCompleted,
    DateTime? createdAt,
    TaskDifficulty? difficulty,
    List<String>? subTasks,
    int? experiencePoints,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      difficulty: difficulty ?? this.difficulty,
      subTasks: subTasks ?? this.subTasks,
      experiencePoints: experiencePoints ?? this.experiencePoints,
    );
  }
}