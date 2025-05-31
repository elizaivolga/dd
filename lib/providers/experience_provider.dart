import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/achievement.dart';
import '../models/experience.dart';

class ExperienceProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<UserExperience> getCurrentExperience() async {
    return await _db.getExperience();
  }

  Future<List<UserAchievement>> getAchievements() async {
    return await _db.getAchievements();
  }

  Future<void> addExperience(int amount) async {
    final exp = await getCurrentExperience();
    exp.addXP(amount);
    await _db.updateExperience(exp);

    // Проверяем достижения
    final achievements = await getAchievements();
    final totalXP = exp.currentXP + (exp.level - 1) * exp.calculateXPForNextLevel();

    for (var achievement in achievements) {
      if (!achievement.isUnlocked && totalXP >= achievement.xpRequired) {
        achievement.unlock();
        await _db.updateAchievement(achievement);
      }
    }

    notifyListeners();
  }
}