import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class StatisticItem extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatisticItem({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: 48.0,
          color: color,
        ),
        const SizedBox(height: 8.0),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadAllStatistics(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          final data = snapshot.data!;
          final stats = data['today'] as Map<String, int>;
          final weekStats = data['week'] as List<Map<String, dynamic>>;

          final completionRate = stats['totalTasks'] != 0
              ? (stats['tasksCompleted']! / stats['totalTasks']! * 100)
              : 0.0;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Сегодняшняя статистика',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          StatisticItem(
                            title: 'Выполнено',
                            value: '${stats['tasksCompleted']}',
                            icon: Icons.check_circle,
                            color: Colors.green,
                          ),
                          StatisticItem(
                            title: 'Всего',
                            value: '${stats['totalTasks']}',
                            icon: Icons.assignment,
                            color: Colors.blue,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16.0),
                      Text(
                        'Процент выполнения',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8.0),
                      LinearProgressIndicator(
                        value: completionRate / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        '${completionRate.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Статистика за неделю',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16.0),
                      SizedBox(
                        height: 200,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: _getMaxValue(weekStats) * 1.2,
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    if (value < 0 || value >= weekStats.length) {
                                      return const SizedBox.shrink();
                                    }
                                    final date = weekStats[value.toInt()]['date'] as DateTime;
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        DateFormat('dd.MM').format(date),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  getTitlesWidget: (value, meta) {
                                    if (value == value.roundToDouble()) {
                                      return Text(
                                        value.toInt().toString(),
                                        style: const TextStyle(fontSize: 12),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            gridData: const FlGridData(
                              show: false,
                            ),
                            borderData: FlBorderData(
                              show: false,
                            ),
                            barGroups: weekStats.asMap().entries.map((entry) {
                              final index = entry.key;
                              final dayStats = entry.value;
                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: dayStats['tasksCompleted'].toDouble(),
                                    color: Theme.of(context).primaryColor,
                                    width: 16,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
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

  Future<Map<String, dynamic>> _loadAllStatistics() async {
    final db = DatabaseHelper();
    final today = await db.getStatistics(DateTime.now());
    final weekStats = await db.getStatisticsForLastDays(7);
    return {
      'today': today,
      'week': weekStats,
    };
  }

  double _getMaxValue(List<Map<String, dynamic>> stats) {
    double maxValue = 0;
    for (var stat in stats) {
      final value = (stat['tasksCompleted'] as int).toDouble();
      if (value > maxValue) maxValue = value;
    }
    return maxValue == 0 ? 1 : maxValue;
  }
}