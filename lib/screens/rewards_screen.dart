import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/experience.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Награды'),
      ),
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
                        const Icon(
                          Icons.star,
                          size: 48.0,
                          color: Colors.amber,
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          'Начало работы',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          'Выполнено первых 100 XP!',
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