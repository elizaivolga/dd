import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../database/database_helper.dart';

class TaskCard extends StatefulWidget {
  final Task task;
  final Function(Task) onTaskUpdated;
  final Function(String) onTaskDeleted;
  final bool isExpanded;

  const TaskCard({
    Key? key,
    required this.task,
    required this.onTaskUpdated,
    required this.onTaskDeleted,
    this.isExpanded = false,
  }) : super(key: key);

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  final DatabaseHelper _db = DatabaseHelper();
  bool _isExpanded = false;
  final TextEditingController _subTaskController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpanded;
  }

  Color _getDifficultyColor(TaskDifficulty difficulty) {
    switch (difficulty) {
      case TaskDifficulty.hard:
        return Colors.red.shade100;
      case TaskDifficulty.medium:
        return Colors.orange.shade100;
      case TaskDifficulty.easy:
        return Colors.green.shade100;
    }
  }

  Color _getDifficultyIconColor(TaskDifficulty difficulty) {
    switch (difficulty) {
      case TaskDifficulty.hard:
        return Colors.red;
      case TaskDifficulty.medium:
        return Colors.orange;
      case TaskDifficulty.easy:
        return Colors.green;
    }
  }

  Future<void> _addSubTask() async {
    if (_subTaskController.text.trim().isEmpty) return;

    final updatedTask = widget.task.copyWith(
      subTasks: [...widget.task.subTasks, _subTaskController.text.trim()],
    );

    await _db.updateTask(updatedTask);
    _subTaskController.clear();
    widget.onTaskUpdated(updatedTask);
  }

  Future<void> _toggleSubTask(int index) async {
    final subTasks = List<String>.from(widget.task.subTasks);
    final taskTitle = subTasks[index];

    // Добавляем или убираем символ выполнения
    if (taskTitle.startsWith('✓ ')) {
      subTasks[index] = taskTitle.substring(2);
    } else {
      subTasks[index] = '✓ $taskTitle';
    }

    final updatedTask = widget.task.copyWith(
      subTasks: subTasks,
      isCompleted: subTasks.every((task) => task.startsWith('✓ ')),
    );

    await _db.updateTask(updatedTask);
    widget.onTaskUpdated(updatedTask);
  }

  Future<void> _deleteSubTask(int index) async {
    final subTasks = List<String>.from(widget.task.subTasks)..removeAt(index);

    final updatedTask = widget.task.copyWith(
      subTasks: subTasks,
      isCompleted: subTasks.every((task) => task.startsWith('✓ ')),
    );

    await _db.updateTask(updatedTask);
    widget.onTaskUpdated(updatedTask);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat('HH:mm');
    final dateFormat = DateFormat('dd MMM', 'ru');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: _isExpanded ? 2 : 1,
      color: widget.task.isCompleted ? Colors.grey.shade100 : Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getDifficultyColor(widget.task.difficulty),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                widget.task.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                color: _getDifficultyIconColor(widget.task.difficulty),
              ),
            ),
            title: Text(
              widget.task.title,
              style: TextStyle(
                decoration: widget.task.isCompleted ? TextDecoration.lineThrough : null,
                color: widget.task.isCompleted ? Colors.grey : Colors.black87,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.task.description?.isNotEmpty ?? false)
                  Text(
                    widget.task.description!,
                    maxLines: _isExpanded ? null : 1,
                    overflow: _isExpanded ? null : TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${dateFormat.format(widget.task.dueDate)} ${timeFormat.format(widget.task.dueDate)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.task.dueDate.isBefore(DateTime.now()) && !widget.task.isCompleted
                            ? Colors.red
                            : Colors.grey[600],
                      ),
                    ),
                    if (widget.task.subTasks.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Icon(
                        Icons.checklist,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.task.subTasks.where((task) => task.startsWith('✓ ')).length}/${widget.task.subTasks.length}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[600],
                  ),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                ),
                IconButton(
                  icon: Icon(
                    widget.task.isCompleted ? Icons.check_box : Icons.check_box_outline_blank,
                    color: widget.task.isCompleted ? theme.colorScheme.primary : Colors.grey,
                  ),
                  onPressed: () {
                    final updatedTask = widget.task.copyWith(
                      isCompleted: !widget.task.isCompleted,
                    );
                    widget.onTaskUpdated(updatedTask);
                  },
                ),
              ],
            ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _subTaskController,
                          decoration: InputDecoration(
                            hintText: 'Добавить подзадачу',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          onSubmitted: (_) => _addSubTask(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _addSubTask,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.task.subTasks.length,
                    itemBuilder: (context, index) {
                      final subTask = widget.task.subTasks[index];
                      final isCompleted = subTask.startsWith('✓ ');
                      final title = isCompleted ? subTask.substring(2) : subTask;

                      return Dismissible(
                        key: Key('$index'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          color: Colors.red,
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                        ),
                        onDismissed: (_) => _deleteSubTask(index),
                        child: CheckboxListTile(
                          value: isCompleted,
                          onChanged: (_) => _toggleSubTask(index),
                          title: Text(
                            title,
                            style: TextStyle(
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: isCompleted
                                  ? Colors.grey
                                  : Colors.black87,
                            ),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _subTaskController.dispose();
    super.dispose();
  }
}