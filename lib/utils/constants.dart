class Constants {
  // Названия таблиц базы данных
  static const String tasksTable = 'tasks';
  static const String subTasksTable = 'sub_tasks';
  static const String notesTable = 'notes';
  static const String experienceTable = 'experience';
  static const String achievementsTable = 'achievements';

  // Ключи SharedPreferences
  static const String themeKey = 'theme_mode';
  static const String welcomeScreenKey = 'show_welcome_screen';

  // XP за задачи
  static const int easyTaskXP = 10;
  static const int mediumTaskXP = 25;
  static const int hardTaskXP = 50;

  // Уровни достижений
  static const int xpPerLevel = 100;
}