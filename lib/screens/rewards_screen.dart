import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/experience.dart';

class RewardsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Награды'),
      ),
      body: FutureBuilder<Experience?>(
        future: DatabaseHelper().getExperience(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final experience = snapshot.data ?? Experience(
            currentXP: 0,
            level: 1,
            lastUpdated: DateTime.now(),
          );

          return ListView(
            padding: EdgeInsets.all(16.0),
            children: [
              // Отображение текущего уровня и опыта
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Уровень ${experience.level}',
                        style: Theme.of(context).textTheme.headline5,
                      ),
                      SizedBox(height: 8.0),
                      LinearProgressIndicator(
                        value: experience.getLevelProgress(),
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        'XP: ${experience.currentXP}/${experience.calculateXPForNextLevel()}',
                        style: Theme.of(context).textTheme.subtitle1,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              // Достижения
              if (experience.currentXP >= 100)
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.star,
                          size: 48.0,
                          color: Colors.amber,
                        ),
                        SizedBox(height: 8.0),
                        Text(
                          'Начало работы',
                          style: Theme.of(context).textTheme.headline6,
                        ),
                        SizedBox(height: 8.0),
                        Text(
                          'Выполнено первых 100 XP!',
                          style: Theme.of(context).textTheme.subtitle1,
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