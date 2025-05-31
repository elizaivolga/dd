import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/add_task_dialog.dart';
import '../models/task.dart';
import '../database/database_helper.dart'; // Заменяем DatabaseService на DatabaseHelper
import '../screens/tasks_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/notes_screen.dart';
import '../screens/rewards_screen.dart';
import '../screens/statistics_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<Task> _tasks = [];
  final DatabaseHelper _databaseHelper = DatabaseHelper(); // Используем DatabaseHelper
  DateTime _selectedDate = DateTime.now();
  final DateFormat _dateFormat = DateFormat('dd MMMM yyyy', 'ru');

  final List<Widget> _screens = [
    const TasksTab(),
    const CalendarScreen(),
    const NotesScreen(),
    const RewardsScreen(),
    const StatisticsScreen(),
  ];

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
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final tasks = await _databaseHelper.getTasks();
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

  Future<void> _addTask(Task task) async {
    try {
      await _databaseHelper.insertTask(task);
      await _loadTasks();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Задача успешно добавлена'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Ошибка при добавлении задачи: $e');
      }
    }
  }

  Future<void> _deleteTask(String taskId) async {
    try {
      await _databaseHelper.delete(
        'tasks',
        where: 'id = ?',
        whereArgs: [taskId],
      );
      await _loadTasks();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Задача удалена'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Ошибка при удалении задачи: $e');
      }
    }
  }

  Future<void> _toggleTaskCompletion(Task task) async {
    try {
      task.isCompleted = !task.isCompleted;
      await _databaseHelper.update(
        'tasks',
        task.toMap(),
        where: 'id = ?',
        whereArgs: [task.id],
      );
      await _loadTasks();
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Ошибка при обновлении задачи: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildTaskList() {
    final filteredTasks = _tasks.where((task) {
      return task.dueDate.year == _selectedDate.year &&
          task.dueDate.month == _selectedDate.month &&
          task.dueDate.day == _selectedDate.day;
    }).toList();

    if (filteredTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.task_alt,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Нет задач на ${_dateFormat.format(_selectedDate)}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredTasks.length,
      itemBuilder: (context, index) {
        final task = filteredTasks[index];
        return Dismissible(
          key: Key(task.id ?? ''),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) {
            if (task.id != null) {
              _deleteTask(task.id!);
            }
          },
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _getPriorityColor(task.priority),
                child: Icon(
                  task.isCompleted ? Icons.check : Icons.assignment,
                  color: Colors.white,
                ),
              ),
              title: Text(
                task.title,
                style: TextStyle(
                  decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
              subtitle: task.description?.isNotEmpty == true
                  ? Text(
                task.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
                  : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('HH:mm').format(task.dueDate),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      task.isCompleted
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      color: task.isCompleted ? Colors.green : Colors.grey,
                    ),
                    onPressed: () => _toggleTaskCompletion(task),
                  ),
                ],
              ),
              onTap: () {
                // TODO: Добавить редактирование задачи
              },
            ),
          ),
        );
      },
    );
  }

  Color _getPriorityColor(String? priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  lastDate: DateTime(2025),
                  locale: const Locale('ru', 'RU'),
                );
                if (picked != null) {
                  setState(() {
                    _selectedDate = picked;
                  });
                }
              },
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
            child: _selectedIndex == 0 ? _buildTaskList() : _screens[_selectedIndex],
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
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
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AddTaskDialog(
              onTaskAdded: _addTask,
              selectedDate: _selectedDate,
            ),
          );
        },
        child: const Icon(Icons.add),
      )
          : null,
    );
  }
}