import 'package:flutter/material.dart';
import '../models/task.dart';
import '../database/database_helper.dart';
import '../screens/add_task_screen.dart';
import 'package:intl/intl.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({Key? key}) : super(key: key);

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<Task> _tasks = [];
  bool _isLoading = false;
  Set<String> _expandedTasks = {};
  final _dateFormat = DateFormat('dd.MM.yyyy');

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final loadedTasks = await _db.getTasks();
      if (!mounted) return;

      setState(() {
        _tasks = loadedTasks;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorSnackBar('Ошибка при загрузке задач: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _toggleTaskCompletion(Task task) async {
    // Если задача уже выполнена, ничего не делаем
    if (task.isCompleted) return;

    try {
      // Обновляем состояние в UI
      setState(() {
        final index = _tasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          _tasks[index] = task.copyWith(isCompleted: true);
        }
      });

      // Сохраняем в базу данных
      await _db.completeTask(task.id);

      // Перезагружаем задачи для обновления всех данных
      await _loadTasks();
    } catch (e) {
      // В случае ошибки возвращаем предыдущее состояние
      setState(() {
        final index = _tasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          _tasks[index] = task;
        }
      });
      _showErrorSnackBar('Ошибка при обновлении задачи: $e');
    }
  }

  Future<void> _deleteTask(Task task) async {
    try {
      await _db.deleteTask(task.id);
      setState(() {
        _tasks.removeWhere((t) => t.id == task.id);
        _expandedTasks.remove(task.id);
      });
    } catch (e) {
      _showErrorSnackBar('Ошибка при удалении задачи: $e');
    }
  }

  Widget _buildTaskCard(Task task) {
    final isExpanded = _expandedTasks.contains(task.id);
    final hasSubTasks = task.subTasks.isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: task.getDifficultyColor(),
              child: Icon(
                task.isCompleted ? Icons.check : Icons.pending,
                color: Colors.white,
              ),
            ),
            title: Text(
              task.title,
              style: TextStyle(
                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (task.description?.isNotEmpty ?? false)
                  Text(
                    task.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Text(
                  _dateFormat.format(task.dueDate),
                  style: TextStyle(
                    fontSize: 12,
                    color: task.dueDate.isBefore(DateTime(
                      DateTime.now().year,
                      DateTime.now().month,
                      DateTime.now().day,
                    )) && !task.isCompleted
                        ? Colors.red
                        : Colors.grey[600],
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasSubTasks)
                  IconButton(
                    icon: Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.grey[600],
                    ),
                    onPressed: () {
                      setState(() {
                        if (isExpanded) {
                          _expandedTasks.remove(task.id);
                        } else {
                          _expandedTasks.add(task.id);
                        }
                      });
                    },
                  ),
                Checkbox(
                  value: task.isCompleted,
                  onChanged: task.isCompleted ? null : (bool? value) {
                    if (value == true) {
                      _toggleTaskCompletion(task);
                    }
                  },
                  activeColor: Colors.green,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.grey,
                  ),
                  onPressed: () => _deleteTask(task),
                ),
              ],
            ),
            onTap: () async {
              if (!task.isCompleted) {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddTaskScreen(task: task),
                  ),
                );
                if (result == true) {
                  await _loadTasks();
                }
              }
            },
          ),
          if (isExpanded && hasSubTasks)
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: task.subTasks.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    dense: true,
                    leading: const SizedBox(
                      width: 40,
                      child: Icon(
                        Icons.subdirectory_arrow_right,
                        size: 20,
                        color: Colors.grey,
                      ),
                    ),
                    title: Text(
                      task.subTasks[index],
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _tasks.isEmpty
        ? Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Нет активных задач',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    )
        : RefreshIndicator(
      onRefresh: _loadTasks,
      child: ListView.builder(
        itemCount: _tasks.length,
        padding: const EdgeInsets.all(8),
        itemBuilder: (context, index) => _buildTaskCard(_tasks[index]),
      ),
    );
  }
}