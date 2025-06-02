import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/experience.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Experience?>(
        future: DatabaseHelper().getExperience(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final experience = snapshot.data ?? Experience(
            points: 0,
            level: 1,
            lastUpdated: DateTime.now(),
          );

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Отображение текущего уровня и опыта
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Уровень ${experience.level}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8.0),
                      LinearProgressIndicator(
                        value: experience.getLevelProgress(),
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'XP: ${experience.points}/${experience.calculateXPForNextLevel()}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              // Достижения
              if (experience.points >= 100)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/1lvl.png',
                          height: 48.0,
                          width: 48.0,
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          'Начало работы',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          'Взят первый уровень!',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              if (experience.points >= 10)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/1lvl.png',
                          height: 48.0, // Set the same size as the previous icon
                          width: 48.0,
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          'Знакомство',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          'Выполнена первая задача',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}