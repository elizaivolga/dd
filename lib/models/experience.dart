class Experience {
  String id;
  int points;
  int level;
  DateTime lastUpdated;

  Experience({
    this.id = 'user_experience',
    this.points = 0,
    this.level = 1,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'points': points,
      'level': level,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory Experience.fromMap(Map<String, dynamic> map) {
    if (map == null) throw ArgumentError('map cannot be null');

    return Experience(
      id: map['id'] ?? 'user_experience',
      points: map['points'] ?? 0,
      level: map['level'] ?? 1,
      lastUpdated: DateTime.parse(map['lastUpdated']),
    );
  }

  double getLevelProgress() {
    final nextLevelXP = calculateXPForNextLevel();
    final currentLevelXP = calculateXPForLevel(level);
    final progress = (points - currentLevelXP) / (nextLevelXP - currentLevelXP);
    return progress.clamp(0.0, 1.0);
  }

  int calculateXPForNextLevel() {
    return calculateXPForLevel(level + 1);
  }

  static int calculateXPForLevel(int level) {
    return (100 * (level * 1.5)).round();
  }

  void addXP(int amount) {
    points += amount;
    while (points >= calculateXPForNextLevel()) {
      level++;
    }
    lastUpdated = DateTime.now();
  }

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

  @override
  String toString() {
    return 'Experience{id: $id, points: $points, level: $level, lastUpdated: $lastUpdated}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Experience &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              points == other.points &&
              level == other.level;

  @override
  int get hashCode => Object.hash(id, points, level);
}