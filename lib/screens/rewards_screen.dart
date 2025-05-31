import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/experience.dart';
import '../models/achievement.dart';
import '../providers/experience_provider.dart';
import '../widgets/achievement_card.dart';
import '../widgets/experience_bar.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Достижения'),
        elevation: 0,
      ),
      body: Consumer<ExperienceProvider>(
        builder: (context, expProvider, _) {
          return FutureBuilder<UserExperience>(
            future: expProvider.getCurrentExperience(),
            builder: (context, expSnapshot) {
              if (expSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (expSnapshot.hasError) {
                return Center(
                  child: Text('Ошибка: ${expSnapshot.error}'),
                );
              }

              final experience = expSnapshot.data!;

              return FutureBuilder<List<UserAchievement>>(
                future: expProvider.getAchievements(),
                builder: (context, achSnapshot) {
                  if (achSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (achSnapshot.hasError) {
                    return Center(
                      child: Text('Ошибка: ${achSnapshot.error}'),
                    );
                  }

                  final achievements = achSnapshot.data!;

                  return CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Уровень ${experience.level}',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              ExperienceBar(
                                currentXP: experience.currentXP,
                                maxXP: experience.calculateXPForNextLevel(),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Достижения',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.all(16.0),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16.0,
                            crossAxisSpacing: 16.0,
                            childAspectRatio: 0.85,
                          ),
                          delegate: SliverChildBuilderDelegate(
                                (context, index) {
                              final achievement = achievements[index];
                              return AchievementCard(
                                achievement: achievement,
                                currentXP: experience.currentXP +
                                    (experience.level - 1) * experience.calculateXPForNextLevel(),
                              );
                            },
                            childCount: achievements.length,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}