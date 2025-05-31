import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/sub_task.dart';
import '../services/database_service.dart';

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
  final DatabaseService _databaseService = DatabaseService();
  List<SubTask> _subTasks = [];
  bool _isExpanded = false;
  final TextEditingController _subTaskController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpanded;
    _loadSubTasks();
  }

  Future<void> _loadSubTasks() async {
    final subTasks = await _databaseService.getSubTasks(widget.task.id);
    setState(() {
      _subTasks = subTasks;
    });
  }

  Color _getPriorityColor(String? priority) {
    switch (priority) {
      case 'high':
        return Colors.red.shade100;
      case 'medium':
        return Colors.orange.shade100;
      case 'low':
        return Colors.green.shade100;
      default:
        return Colors.blue.shade100;
    }
  }

  Color _getPriorityIconColor(String? priority) {
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

  Future<void> _addSubTask() async {
    if (_subTaskController.text.trim().isEmpty) return;

    final subTask = SubTask(
      taskId: widget.task.id,
      title: _subTaskController.text.trim(),
    );

    await _databaseService.insertSubTask(subTask);
    _subTaskController.clear();
    await _loadSubTasks();
  }

  Future<void> _toggleSubTask(SubTask subTask) async {
    final updatedSubTask = SubTask(
      id: subTask.id,
      taskId: subTask.taskId,
      title: subTask.title,
      isCompleted: !subTask.isCompleted,
      createdAt: subTask.createdAt,
      completedAt: !subTask.isCompleted ? DateTime.now() : null,
    );

    await _databaseService.updateSubTask(updatedSubTask);
    await _loadSubTasks();

    // Проверяем, все ли подзадачи выполнены
    if (_subTasks.isNotEmpty && _subTasks.every((st) => st.isCompleted)) {
      final updatedTask = widget.task.copyWith(isCompleted: true);
      widget.onTaskUpdated(updatedTask);
    }
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
                color: _getPriorityColor(widget.task.priority),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                widget.task.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                color: _getPriorityIconColor(widget.task.priority),
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
                    if (_subTasks.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Icon(
                        Icons.checklist,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_subTasks.where((st) => st.isCompleted).length}/${_subTasks.length}',
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
                    itemCount: _subTasks.length,
                    itemBuilder: (context, index) {
                      final subTask = _subTasks[index];
                      return Dismissible(
                        key: Key(subTask.id),
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
                        onDismissed: (_) async {
                          await _databaseService.deleteSubTask(subTask.id);
                          await _loadSubTasks();
                        },
                        child: CheckboxListTile(
                          value: subTask.isCompleted,
                          onChanged: (_) => _toggleSubTask(subTask),
                          title: Text(
                            subTask.title,
                            style: TextStyle(
                              decoration: subTask.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: subTask.isCompleted
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