import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/experience.dart';
import '../database/database_helper.dart';
import 'tasks_screen.dart';
import 'calendar_screen.dart';
import 'notes_screen.dart';
import 'rewards_screen.dart';
import 'statistics_screen.dart';
import 'add_task_screen.dart';
import 'settings_screen.dart';
import 'about_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<Task> _tasks = [];
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  DateTime _selectedDate = DateTime.now();
  final DateFormat _dateFormat = DateFormat('dd MMMM yyyy', 'ru');
  late List<Widget> _screens;

  final List<String> _titles = [
    'Задачи',
    'Календарь',
    'Заметки',
    'Награды',
    'Статистика',
  ];

  @override
  void initState() {
    super.initState();
    _updateScreens();
    _loadTasks();
  }

  void _updateScreens() {
    _screens = [
      TasksScreen(
        databaseHelper: _databaseHelper,
        selectedDate: _selectedDate,
      ),
      const CalendarScreen(),
      const NotesScreen(),
      const RewardsScreen(),
      const StatisticsScreen(),
    ];
  }

  Future<void> _loadTasks() async {
    try {
      final tasks = await _databaseHelper.getTasksByDate(_selectedDate);
      if (mounted) {
        setState(() {
          _tasks.clear();
          _tasks.addAll(tasks);
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Ошибка при загрузке задач: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<Experience?> _getCurrentExperience() async {
    return await _databaseHelper.getExperience();
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          FutureBuilder<Experience?>(
            future: _getCurrentExperience(),
            builder: (context, snapshot) {
              return UserAccountsDrawerHeader(
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    snapshot.data?.level.toString() ?? '1',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
                accountName: const Text('Текущий уровень'),
                accountEmail: Text(
                  'Опыт: ${snapshot.data?.points ?? 0} XP',
                  style: const TextStyle(fontSize: 14),
                ),
                decoration: const BoxDecoration(
                  color: Colors.deepPurple,
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Настройки'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('О приложении'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AboutScreen(),
                ),
              );
            },
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Пользователь: elizaivolga',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Создаем актуальный список экранов при каждой перерисовке
    final currentScreens = [
      TasksScreen(
        databaseHelper: _databaseHelper,
        selectedDate: _selectedDate,
      ),
      const CalendarScreen(),
      const NotesScreen(),
      const RewardsScreen(),
      const StatisticsScreen(),
    ];

    return Scaffold(
      drawer: _buildDrawer(),
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          if (_selectedIndex == 0)
            IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2025, 12, 31),
                  locale: const Locale('ru', 'RU'),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: Theme.of(context).primaryColor,
                          onPrimary: Colors.white,
                          surface: Colors.white,
                          onSurface: Colors.black,
                        ),
                        dialogBackgroundColor: Colors.white,
                      ),
                      child: child!,
                    );
                  },
                  selectableDayPredicate: (DateTime date) {
                    // Можно добавить ограничения на выбор дат
                    return true;
                  },
                );

                if (picked != null && picked != _selectedDate) {
                  setState(() {
                    _selectedDate = picked;
                    // Обновляем список экранов с новой датой
                    _screens = [
                      TasksScreen(
                        databaseHelper: _databaseHelper,
                        selectedDate: _selectedDate,
                      ),
                      const CalendarScreen(),
                      const NotesScreen(),
                      const RewardsScreen(),
                      const StatisticsScreen(),
                    ];
                  });
                  // Перезагружаем задачи для выбранной даты
                  await _loadTasks();
                }
              },
              tooltip: 'Выбрать дату',
            ),
        ],
      ),
      body: Column(
        children: [
          if (_selectedIndex == 0)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _dateFormat.format(_selectedDate),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Expanded(
            child: currentScreens[_selectedIndex],
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
            _screens = currentScreens;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.task_alt),
            label: 'Задачи',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Календарь',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.note_alt),
            label: 'Заметки',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: 'Награды',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Статистика',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => AddTaskScreen(
                initialDate: _selectedDate,
              ),
            ),
          );
          if (result == true) {
            await _loadTasks();
          }
        },
        child: const Icon(Icons.add),
      )
          : null,
    );
  }

  @override
  void dispose() {
    _databaseHelper.close();
    super.dispose();
  }
}