import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../database/database_helper.dart';
import '../providers/experience_provider.dart';
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
  String _sortBy = 'date';
  bool _showCompleted = false;
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
        _sortTasks();
      });
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Ошибка при загрузке задач: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _sortTasks() {
    _tasks.sort((a, b) {
      if (_sortBy == 'date') {
        return a.dueDate.compareTo(b.dueDate);
      } else if (_sortBy == 'difficulty') {
        return b.difficulty.index.compareTo(a.difficulty.index);
      } else {
        return a.title.compareTo(b.title);
      }
    });

    if (!_showCompleted) {
      _tasks = _tasks.where((task) => !task.isCompleted).toList();
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
    try {
      task.isCompleted = !task.isCompleted;
      await _db.updateTask(task);

      if (task.isCompleted) {
        await _db.completeTask(task.id);
      }

      await _loadTasks();
    } catch (e) {
      _showErrorSnackBar('Ошибка при обновлении задачи: $e');
    }
  }

  Future<void> _deleteTask(Task task) async {
    try {
      await _db.deleteTask(task.id);
      setState(() {
        _expandedTasks.remove(task.id);
      });
      await _loadTasks();
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
                    color: task.dueDate.isBefore(DateTime.now()) && !task.isCompleted
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
                IconButton(
                  icon: Icon(
                    task.isCompleted
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    color: task.isCompleted ? Colors.green : Colors.grey,
                  ),
                  onPressed: () => _toggleTaskCompletion(task),
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
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => AddTaskScreen(task: task),
                ),
              );
              if (result == true) {
                await _loadTasks();
              }
            },
          ),
          if (isExpanded && hasSubTasks)
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(
                  top: BorderSide(
                    color: Colors.grey[300]!,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Задачи'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => StatefulBuilder(
                  builder: (context, setState) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: const Text('Сортировать по'),
                        trailing: DropdownButton<String>(
                          value: _sortBy,
                          items: const [
                            DropdownMenuItem(
                              value: 'date',
                              child: Text('Дате'),
                            ),
                            DropdownMenuItem(
                              value: 'difficulty',
                              child: Text('Сложности'),
                            ),
                            DropdownMenuItem(
                              value: 'title',
                              child: Text('Названию'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _sortBy = value);
                              _sortTasks();
                              if (mounted) {
                                this.setState(() {});
                              }
                            }
                          },
                        ),
                      ),
                      SwitchListTile(
                        title: const Text('Показывать выполненные'),
                        value: _showCompleted,
                        onChanged: (value) {
                          setState(() => _showCompleted = value);
                          _sortTasks();
                          if (mounted) {
                            this.setState(() {});
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTaskScreen(),
            ),
          );
          if (result == true) {
            await _loadTasks();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}