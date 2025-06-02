import 'package:flutter/material.dart';
import '../models/task.dart';
import '../database/database_helper.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class AddTaskScreen extends StatefulWidget {
  final Task? task;
  final DateTime? initialDate;

  const AddTaskScreen({
    Key? key,
    this.task,
    this.initialDate,
  }) : super(key: key);

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _subTaskController = TextEditingController();
  final _db = DatabaseHelper();
  final _dateFormat = DateFormat('dd.MM.yyyy');

  late DateTime _selectedDate;
  late TaskDifficulty _selectedDifficulty;
  final List<SubTask> _subTasks = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.task?.title ?? '';
    _descriptionController.text = widget.task?.description ?? '';
    _selectedDate = widget.task?.dueDate ?? widget.initialDate ?? DateTime.now();
    _selectedDifficulty = widget.task?.difficulty ?? TaskDifficulty.easy;
    if (widget.task?.subTasks != null) {
      _subTasks.addAll(widget.task!.subTasks);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _subTaskController.dispose();
    super.dispose();
  }

  void _addSubTask() {
    if (_subTaskController.text.isEmpty) return;

    setState(() {
      _subTasks.add(SubTask(
        text: _subTaskController.text,
        isCompleted: false,
      ));
      _subTaskController.clear();
    });
  }

  void _removeSubTask(int index) {
    setState(() {
      _subTasks.removeAt(index);
    });
  }


  void _reorderSubTasks(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final SubTask item = _subTasks.removeAt(oldIndex);
      _subTasks.insert(newIndex, item);
    });
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final taskId = widget.task?.id ??
          '${DateTime.now().millisecondsSinceEpoch}_${(1000 + Random().nextInt(9000))}';

      final now = DateTime.now().toUtc();
      final createdAt = widget.task?.createdAt ?? now;

      if (_titleController.text.trim().isEmpty) {
        throw Exception('Название задачи не может быть пустым');
      }

      final task = Task(
        id: taskId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        dueDate: DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          23,
          59,
          59,
        ).toUtc(),
        isCompleted: widget.task?.isCompleted ?? false,
        createdAt: createdAt,
        difficulty: _selectedDifficulty,
        subTasks: List<SubTask>.from(_subTasks),
        experiencePoints: widget.task?.experiencePoints ?? 0,
      );

      if (task.dueDate.isBefore(DateTime.now())) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Дата выполнения не может быть в прошлом'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (widget.task == null) {
        final result = await _db.insertTask(task);
        if (result <= 0) {
          throw Exception('Не удалось создать задачу');
        }
      } else {
        final result = await _db.updateTask(task);
        if (result <= 0) {
          throw Exception('Не удалось обновить задачу');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.task == null
                  ? 'Задача успешно создана'
                  : 'Задача успешно обновлена',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при сохранении задачи: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'Новая задача' : 'Редактировать задачу'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveTask,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Название задачи',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите название задачи';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Описание',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              Card(
                child: ListTile(
                  title: const Text('Дата выполнения'),
                  subtitle: Text(_dateFormat.format(_selectedDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => _selectedDate = date);
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Сложность задачи',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      for (var difficulty in TaskDifficulty.values)
                        RadioListTile<TaskDifficulty>(
                          title: Text(
                            difficulty == TaskDifficulty.easy
                                ? 'Легкая'
                                : difficulty == TaskDifficulty.medium
                                ? 'Средняя'
                                : 'Сложная',
                          ),
                          value: difficulty,
                          groupValue: _selectedDifficulty,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedDifficulty = value);
                            }
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Подзадачи',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _subTaskController,
                              decoration: const InputDecoration(
                                hintText: 'Добавить подзадачу',
                                border: OutlineInputBorder(),
                              ),
                              onSubmitted: (_) => _addSubTask(),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: _addSubTask,
                          ),
                        ],
                      ),
                      if (_subTasks.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ReorderableListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _subTasks.length,
                          onReorder: _reorderSubTasks,
                          itemBuilder: (context, index) {
                            final subTask = _subTasks[index];
                            return ListTile(
                              key: Key('subtask_$index'),
                              leading: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.drag_handle,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                              title: Text(
                                subTask.text,
                                style: TextStyle(
                                  decoration: subTask.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.clear_sharp),
                                onPressed: () => _removeSubTask(index),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: !_isLoading
          ? FloatingActionButton(
        onPressed: _saveTask,
        child: const Icon(Icons.save),
      )
          : null,
    );
  }
}