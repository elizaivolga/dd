import 'package:uuid/uuid.dart';

class SubTask {
  final String id;
  final String taskId;  // ID родительской задачи
  final String title;
  bool isCompleted;
  final DateTime createdAt;
  DateTime? completedAt;

  SubTask({
    String? id,
    required this.taskId,
    required this.title,
    this.isCompleted = false,
    DateTime? createdAt,
    this.completedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskId': taskId,
      'title': title,
      'isCompleted': isCompleted ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory SubTask.fromMap(Map<String, dynamic> map) {
    return SubTask(
      id: map['id'],
      taskId: map['taskId'],
      title: map['title'],
      isCompleted: map['isCompleted'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'])
          : null,
    );
  }

  SubTask copyWith({
    String? id,
    String? taskId,
    String? title,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return SubTask(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is SubTask &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              taskId == other.taskId &&
              title == other.title &&
              isCompleted == other.isCompleted &&
              createdAt == other.createdAt &&
              completedAt == other.completedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      taskId.hashCode ^
      title.hashCode ^
      isCompleted.hashCode ^
      createdAt.hashCode ^
      completedAt.hashCode;
}