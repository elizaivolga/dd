class Experience {
  final String? id;
  int points;
  int level;
  DateTime lastUpdated;

  Experience({
    this.id,
    required this.points,
    required this.level,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id ?? DateTime.now().toIso8601String(), // Используем timestamp как id если не задан
      'points': points,
      'level': level,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  static Experience fromMap(Map<String, dynamic> map) {
    return Experience(
      id: map['id'],
      points: map['points'],
      level: map['level'],
      lastUpdated: DateTime.parse(map['lastUpdated']),
    );
  }

  // Метод для добавления опыта и повышения уровня
  void addXP(int xp) {
    points += xp;
    while (points >= calculateXPForNextLevel()) {
      points -= calculateXPForNextLevel();
      level++;
    }
    lastUpdated = DateTime.now();
  }

  // Расчет необходимого опыта для следующего уровня
  int calculateXPForNextLevel() {
    return (level * 100) + ((level - 1) * 50);
  }

  // Процент прогресса до следующего уровня
  double getLevelProgress() {
    final xpForNext = calculateXPForNextLevel();
    return points / xpForNext;
  }

  // Метод для создания копии с обновленными значениями
  Experience copyWith({
    String? id,
    int? points,
    int? level,
    DateTime? lastUpdated,
  }) {
    return Experience(
      id: id ?? this.id,
      points: points ?? this.points,
      level: level ?? this.level,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}