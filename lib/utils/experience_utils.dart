class ExperienceUtils {
  static int calculateXPForTask(int difficulty) {
    switch (difficulty) {
      case 0: // Легкая
        return 10;
      case 1: // Средняя
        return 25;
      case 2: // Сложная
        return 50;
      default:
        return 10;
    }
  }

  static int calculateXPForNextLevel(int currentLevel) {
    return (currentLevel * 100) + ((currentLevel - 1) * 50);
  }

  static double calculateLevelProgress(int currentXP, int nextLevelXP) {
    return currentXP / nextLevelXP;
  }

  static String formatXP(int xp) {
    return '$xp XP';
  }
}