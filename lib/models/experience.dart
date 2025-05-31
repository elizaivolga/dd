class UserExperience {
  final int? id;
  int currentXP;
  int level;
  DateTime lastUpdated;

  UserExperience({
    this.id,
    required this.currentXP,
    required this.level,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'currentXP': currentXP,
      'level': level,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  static UserExperience fromMap(Map<String, dynamic> map) {
    return UserExperience(
      id: map['id'],
      currentXP: map['currentXP'],
      level: map['level'],
      lastUpdated: DateTime.parse(map['lastUpdated']),
    );
  }

  // Метод для добавления опыта и повышения уровня
  void addXP(int xp) {
    currentXP += xp;
    while (currentXP >= calculateXPForNextLevel()) {
      currentXP -= calculateXPForNextLevel();
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
    return currentXP / xpForNext;
  }
}