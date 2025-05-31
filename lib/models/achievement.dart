class UserAchievement {
  final int? id;
  final String title;
  final String description;
  final String iconPath;
  final int xpRequired;
  bool isUnlocked;
  DateTime? unlockedAt;

  UserAchievement({
    this.id,
    required this.title,
    required this.description,
    required this.iconPath,
    required this.xpRequired,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'iconPath': iconPath,
      'xpRequired': xpRequired,
      'isUnlocked': isUnlocked ? 1 : 0,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }

  static UserAchievement fromMap(Map<String, dynamic> map) {
    return UserAchievement(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      iconPath: map['iconPath'],
      xpRequired: map['xpRequired'],
      isUnlocked: map['isUnlocked'] == 1,
      unlockedAt: map['unlockedAt'] != null
          ? DateTime.parse(map['unlockedAt'])
          : null,
    );
  }

  void unlock() {
    if (!isUnlocked) {
      isUnlocked = true;
      unlockedAt = DateTime.now();
    }
  }
}