import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

enum TaskDifficulty { easy, medium, hard }

class SubTask {
  final String text;
  bool isCompleted;

  SubTask({
    required this.text,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isCompleted': isCompleted,
    };
  }

  factory SubTask.fromMap(Map<String, dynamic> map) {
    return SubTask(
      text: map['text'],
      isCompleted: map['isCompleted'] ?? false,
    );
  }
}

class Task {
  final String id;
  final String title;
  final String? description;
  final DateTime dueDate;
  final bool isCompleted;
  final DateTime createdAt;
  final TaskDifficulty difficulty;
  final List<SubTask> subTasks; // Изменено с List<String> на List<SubTask>
  final int experiencePoints;

  Task({
    String? id,
    required this.title,
    this.description,
    required this.dueDate,
    this.isCompleted = false,
    DateTime? createdAt,
    this.difficulty = TaskDifficulty.easy,
    List<SubTask>? subTasks,
    this.experiencePoints = 0,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        subTasks = subTasks ?? [];

  int getExperiencePoints() {
    switch (difficulty) {
      case TaskDifficulty.easy:
        return 10;
      case TaskDifficulty.medium:
        return 20;
      case TaskDifficulty.hard:
        return 30;
    }
  }

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

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isCompleted,
    DateTime? createdAt,
    TaskDifficulty? difficulty,
    List<SubTask>? subTasks,
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'isCompleted': isCompleted ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'difficulty': difficulty.index,
      'subTasks': subTasks.map((st) => st.toMap()).toList(),
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
      difficulty: TaskDifficulty.values[map['difficulty'] ?? 0],
      subTasks: (map['subTasks'] as List?)
          ?.map((st) => SubTask.fromMap(st))
          .toList() ?? [],
      experiencePoints: map['experiencePoints'] ?? 0,
    );
  }
}