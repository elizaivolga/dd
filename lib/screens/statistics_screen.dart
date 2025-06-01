import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'package:fl_chart/fl_chart.dart';

class StatisticsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Статистика'),
      ),
      body: FutureBuilder<Map<String, int>>(
        future: DatabaseHelper().getStatistics(DateTime.now()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final stats = snapshot.data ?? {'tasksCompleted': 0, 'totalTasks': 0};
          final completionRate = stats['totalTasks'] != 0
              ? (stats['tasksCompleted']! / stats['totalTasks']! * 100)
              : 0.0;

          return ListView(
            padding: EdgeInsets.all(16.0),
            children: [
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Сегодняшняя статистика',
                        style: Theme.of(context).textTheme.headline6,
                      ),
                      SizedBox(height: 16.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatisticItem(
                            title: 'Выполнено',
                            value: '${stats['tasksCompleted']}',
                            icon: Icons.check_circle,
                            color: Colors.green,
                          ),
                          _StatisticItem(
                            title: 'Всего',
                            value: '${stats['totalTasks']}',
                            icon: Icons.assignment,
                            color: Colors.blue,
                          ),
                        ],
                      ),
                      SizedBox(height: 16.0),
                      Text(
                        'Процент выполнения',
                        style: Theme.of(context).textTheme.subtitle1,
                      ),
                      SizedBox(height: 8.0),
                      LinearProgressIndicator(
                        value: completionRate / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        '${completionRate.toStringAsFixed(1)}%',
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

class _StatisticItem extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatisticItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: 48.0,
          color: color,
        ),
        SizedBox(height: 8.0),
        Text(
          value,
          style: Theme.of(context).textTheme.headline5,
        ),
        Text(
          title,
          style: Theme.of(context).textTheme.subtitle2,
        ),
      ],
    );
  }
}