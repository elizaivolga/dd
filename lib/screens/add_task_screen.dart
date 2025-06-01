import 'package:flutter/material.dart';
import '../models/task.dart';
import '../database/database_helper.dart';
import 'package:intl/intl.dart';

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
  final List<String> _subTasks = [];
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
      _subTasks.add(_subTaskController.text);
      _subTaskController.clear();
    });
  }

  void _removeSubTask(int index) {
    setState(() {
      _subTasks.removeAt(index);
    });
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final task = Task(
        id: widget.task?.id,
        title: _titleController.text,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        dueDate: _selectedDate,
        difficulty: _selectedDifficulty,
        isCompleted: widget.task?.isCompleted ?? false,
        subTasks: _subTasks,
        createdAt: widget.task?.createdAt,
      );

      if (widget.task == null) {
        await _db.insertTask(task);
      } else {
        await _db.updateTask(task);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при сохранении задачи: $e'),
            backgroundColor: Colors.red,
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
                            difficulty == TaskDifficulty.easy ? 'Легкая' :
                            difficulty == TaskDifficulty.medium ? 'Средняя' : 'Сложная',
                          ),
                          subtitle: Text(
                            difficulty == TaskDifficulty.easy ? '+5 XP' :
                            difficulty == TaskDifficulty.medium ? '+10 XP' : '+15 XP',
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
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _subTasks.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(_subTasks[index]),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
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