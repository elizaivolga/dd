import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../database/database_helper.dart';

class StatisticsScreen extends StatefulWidget {
  @override
  _StatisticsScreenState createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  List<Task> _tasks = [];
  String _selectedPeriod = 'week'; // 'week', 'month', 'year'
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final tasks = await DatabaseHelper.instance.getTasks();
    setState(() {
      _tasks = tasks;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Статистика'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String value) {
              setState(() {
                _selectedPeriod = value;
              });
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'week',
                child: Text('За неделю'),
              ),
              const PopupMenuItem(
                value: 'month',
                child: Text('За месяц'),
              ),
              const PopupMenuItem(
                value: 'year',
                child: Text('За год'),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildSummaryCards(),
              _buildCompletionChart(),
              _buildDifficultyDistribution(),
              _buildProductivityTrend(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final totalTasks = _tasks.length;
    final completedTasks = _tasks.where((task) => task.isCompleted).length;
    final completionRate = totalTasks > 0
        ? (completedTasks / totalTasks * 100).toStringAsFixed(1)
        : '0';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Всего задач',
              totalTasks.toString(),
              Icons.assignment,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              'Выполнено',
              '$completionRate%',
              Icons.check_circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionChart() {
    final completedTasksByDate = <DateTime, int>{};
    final now = DateTime.now();
    final daysToShow = _selectedPeriod == 'week' ? 7 : _selectedPeriod == 'month' ? 30 : 365;

    // Инициализируем все даты нулевыми значениями
    for (var i = 0; i < daysToShow; i++) {
      final date = DateTime(now.year, now.month, now.day - i);
      completedTasksByDate[date] = 0;
    }

    // Подсчитываем выполненные задачи по датам
    for (final task in _tasks) {
      if (task.isCompleted && task.completedAt != null) {
        final date = DateTime(
          task.completedAt!.year,
          task.completedAt!.month,
          task.completedAt!.day,
        );
        completedTasksByDate[date] = (completedTasksByDate[date] ?? 0) + 1;
      }
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Выполненные задачи',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: completedTasksByDate.values.isEmpty
                      ? 1
                      : (completedTasksByDate.values.reduce((a, b) => a > b ? a : b) + 1).toDouble(),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.blueGrey,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${rod.toY.toInt()} задач\n${DateFormat('dd.MM').format(DateTime.now().subtract(Duration(days: groupIndex)))}',
                          const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value % 2 == 0) {
                            final date = DateTime.now().subtract(Duration(days: value.toInt()));
                            return Text(
                              DateFormat('dd.MM').format(date),
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                  ),
                  borderData: FlBorderData(
                    show: false,
                  ),
                  barGroups: List.generate(daysToShow, (index) {
                    final date = DateTime.now().subtract(Duration(days: index));
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: (completedTasksByDate[date] ?? 0).toDouble(),
                          color: Theme.of(context).primaryColor,
                          width: 16,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyDistribution() {
    final difficultyCount = {
      TaskDifficulty.easy: 0,
      TaskDifficulty.medium: 0,
      TaskDifficulty.hard: 0,
    };

    for (final task in _tasks) {
      difficultyCount[task.difficulty] = (difficultyCount[task.difficulty] ?? 0) + 1;
    }

    final total = difficultyCount.values.reduce((a, b) => a + b);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Распределение по сложности',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(
                      value: difficultyCount[TaskDifficulty.easy]!.toDouble(),
                      title: 'Легкие\n${((difficultyCount[TaskDifficulty.easy]! / total) * 100).toStringAsFixed(1)}%',
                      color: Colors.green,
                      radius: 100,
                    ),
                    PieChartSectionData(
                      value: difficultyCount[TaskDifficulty.medium]!.toDouble(),
                      title: 'Средние\n${((difficultyCount[TaskDifficulty.medium]! / total) * 100).toStringAsFixed(1)}%',
                      color: Colors.orange,
                      radius: 100,
                    ),
                    PieChartSectionData(
                      value: difficultyCount[TaskDifficulty.hard]!.toDouble(),
                      title: 'Сложные\n${((difficultyCount[TaskDifficulty.hard]! / total) * 100).toStringAsFixed(1)}%',
                      color: Colors.red,
                      radius: 100,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductivityTrend() {
    final productivityData = <DateTime, double>{};
    final now = DateTime.now();
    final daysToShow = _selectedPeriod == 'week' ? 7 : _selectedPeriod == 'month' ? 30 : 365;

    // Вычисляем процент выполненных задач по дням
    for (var i = 0; i < daysToShow; i++) {
      final date = DateTime(now.year, now.month, now.day - i);
      final tasksForDay = _tasks.where((task) =>
      task.dueDate.year == date.year &&
          task.dueDate.month == date.month &&
          task.dueDate.day == date.day
      ).toList();

      if (tasksForDay.isNotEmpty) {
        final completedTasks = tasksForDay.where((task) => task.isCompleted).length;
        productivityData[date] = (completedTasks / tasksForDay.length) * 100;
      } else {
        productivityData[date] = 0;
      }
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Тренд продуктивности',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: Colors.blueGrey,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((LineBarSpot spot) {
                          final date = DateTime.now().subtract(Duration(days: spot.x.toInt()));
                          return LineTooltipItem(
                            '${spot.y.toStringAsFixed(1)}%\n${DateFormat('dd.MM').format(date)}',
                            const TextStyle(color: Colors.white),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value % 2 == 0) {
                            final date = DateTime.now().subtract(Duration(days: value.toInt()));
                            return Text(
                              DateFormat('dd.MM').format(date),
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}%',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (daysToShow - 1).toDouble(),
                  minY: 0,
                  maxY: 100,
                  lineBarsData: [
                    LineChartBarData(
                      spots: productivityData.entries.map((entry) {
                        final days = entry.key.difference(DateTime.now()).abs().inDays;
                        return FlSpot(days.toDouble(), entry.value);
                      }).toList(),
                      isCurved: true,
                      color: Theme.of(context).primaryColor,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).primaryColor.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}