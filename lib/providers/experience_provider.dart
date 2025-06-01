import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/experience.dart';
import '../models/achievement.dart';
import '../utils/experience_utils.dart';
import '../utils/constants.dart';

class ExperienceProvider with ChangeNotifier {
  Experience? _currentExperience;
  List<Achievement> _achievements = [];
  final DatabaseHelper _databaseHelper;
  bool _isLoading = false;

  ExperienceProvider({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper();

  // Геттеры
  Experience? get currentExperience => _currentExperience;
  List<Achievement> get achievements => List.unmodifiable(_achievements);
  bool get isLoading => _isLoading;

  // Инициализация данных
  Future<void> initialize() async {
    _setLoading(true);
    try {
      await _loadExperience();
      await _loadAchievements();
    } finally {
      _setLoading(false);
    }
  }

  // Загрузка текущего опыта
  Future<void> _loadExperience() async {
    _currentExperience = await _databaseHelper.getExperience() ??
        Experience(
          points: 0,
          level: 1,
          lastUpdated: DateTime.now(),
        );
    notifyListeners();
  }

  // Загрузка достижений
  Future<void> _loadAchievements() async {
    _achievements = await _databaseHelper.getAchievements();
    notifyListeners();
  }

  // Добавление опыта
  Future<void> addExperience(int amount, {String? source}) async {
    if (_currentExperience == null) await _loadExperience();

    _setLoading(true);
    try {
      // Добавляем опыт
      _currentExperience!.addXP(amount);
      await _databaseHelper.updateExperience(_currentExperience!);

      // Проверяем достижения
      await _checkAchievements();

      // Обновляем UI
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding experience: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Проверка достижений
  Future<void> _checkAchievements() async {
    if (_currentExperience == null) return;

    final totalXP = _calculateTotalXP();
    bool achievementsUpdated = false;

    for (var achievement in _achievements) {
      // Проверяем, достигнут ли необходимый уровень опыта
      if (!achievement.isUnlocked && totalXP >= Constants.xpPerLevel) {
        await _databaseHelper.unlockAchievement(achievement.id);
        achievementsUpdated = true;
      }
    }

    if (achievementsUpdated) {
      await _loadAchievements();
    }
  }

  // Расчет общего опыта
  int _calculateTotalXP() {
    if (_currentExperience == null) return 0;

    return _currentExperience!.points +
        (_currentExperience!.level - 1) * Constants.xpPerLevel;
  }

  // Получение прогресса текущего уровня
  double getCurrentLevelProgress() {
    if (_currentExperience == null) return 0.0;
    return _currentExperience!.getLevelProgress();
  }

  // Получение опыта, необходимого для следующего уровня
  int getXPForNextLevel() {
    if (_currentExperience == null) return Constants.xpPerLevel;
    return _currentExperience!.calculateXPForNextLevel();
  }

  // Получение последних разблокированных достижений
  List<Achievement> getRecentAchievements({int limit = 5}) {
    return _achievements
        .where((achievement) => achievement.isUnlocked)
        .toList()
      ..sort((a, b) =>
          (b.unlockedAt ?? DateTime.now())
              .compareTo(a.unlockedAt ?? DateTime.now()))
      ..take(limit);
  }

  // Получение количества разблокированных достижений
  int getUnlockedAchievementsCount() {
    return _achievements.where((achievement) => achievement.isUnlocked).length;
  }

  // Расчет процента выполнения всех достижений
  double getAchievementsProgress() {
    if (_achievements.isEmpty) return 0.0;
    return getUnlockedAchievementsCount() / _achievements.length;
  }

  // Сброс прогресса (для тестирования)
  Future<void> resetProgress() async {
    _setLoading(true);
    try {
      _currentExperience = Experience(
        points: 0,
        level: 1,
        lastUpdated: DateTime.now(),
      );
      await _databaseHelper.updateExperience(_currentExperience!);

      // Сбрасываем достижения путем их перезагрузки
      await _loadAchievements();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Обработка состояния загрузки
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Освобождение ресурсов
  @override
  void dispose() {
    _currentExperience = null;
    _achievements.clear();
    super.dispose();
  }
}