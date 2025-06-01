import 'package:uuid/uuid.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final String type;
  final int progress;
  final int target;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final String? icon;

  Achievement({
    String? id,
    required this.title,
    required this.description,
    required this.type,
    this.progress = 0,
    required this.target,
    this.isUnlocked = false,
    this.unlockedAt,
    this.icon,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'progress': progress,
      'target': target,
      'isUnlocked': isUnlocked ? 1 : 0,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'icon': icon,
    };
  }

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      type: map['type'],
      progress: map['progress'],
      target: map['target'],
      isUnlocked: map['isUnlocked'] == 1,
      unlockedAt: map['unlockedAt'] != null
          ? DateTime.parse(map['unlockedAt'])
          : null,
      icon: map['icon'],
    );
  }

  Achievement copyWith({
    String? title,
    String? description,
    String? type,
    int? progress,
    int? target,
    bool? isUnlocked,
    DateTime? unlockedAt,
    String? icon,
  }) {
    return Achievement(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      progress: progress ?? this.progress,
      target: target ?? this.target,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      icon: icon ?? this.icon,
    );
  }
}