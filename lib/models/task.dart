import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

enum TaskDifficulty {
  easy,
  medium,
  hard
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

  Task({
    String? id,
    required this.title,
    this.description,
    required this.dueDate,
    this.isCompleted = false,
    DateTime? createdAt,
    required this.difficulty,
    List<String>? subTasks,
  }) :
        id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        subTasks = subTasks ?? [];

  // Get color based on difficulty
  Color getDifficultyColor() {
    switch (difficulty) {
      case TaskDifficulty.easy:
        return Colors.green;
      case TaskDifficulty.medium:
        return Colors.orange;
      case TaskDifficulty.hard:
        return Colors.red;
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
      'subTasks': subTasks,
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
      subTasks: List<String>.from(map['subTasks']),
    );
  }
}