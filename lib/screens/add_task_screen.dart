import 'package:flutter/material.dart';
import '../models/task.dart';
import '../database/database_helper.dart';

class AddTaskScreen extends StatefulWidget {
  @override
  _AddTaskScreenState createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  TaskDifficulty _selectedDifficulty = TaskDifficulty.easy;
  final List<String> _subTasks = [];
  final _subTaskController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Добавить задачу'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
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
            SizedBox(height: 16.0),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Описание',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 16.0),
            ListTile(
              title: Text('Выберите дату'),
              subtitle: Text(_selectedDate == null
                  ? 'Дата не выбрана'
                  : '${_selectedDate!.day}.${_selectedDate!.month}.${_selectedDate!.year}'),
              trailing: Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(Duration(days: 365)),
                );
                if (date != null) {
                  setState(() {
                    _selectedDate = date;
                  });
                }
              },
            ),
            SizedBox(height: 16.0),
            Card(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Сложность задачи',
                        style: Theme.of(context).textTheme.titleMedium),
                    RadioListTile<TaskDifficulty>(
                      title: Text('Легкая'),
                      value: TaskDifficulty.easy,
                      groupValue: _selectedDifficulty,
                      onChanged: (TaskDifficulty? value) {
                        setState(() {
                          _selectedDifficulty = value!;
                        });
                      },
                    ),
                    RadioListTile<TaskDifficulty>(
                      title: Text('Средняя'),
                      value: TaskDifficulty.medium,
                      groupValue: _selectedDifficulty,
                      onChanged: (TaskDifficulty? value) {
                        setState(() {
                          _selectedDifficulty = value!;
                        });
                      },
                    ),
                    RadioListTile<TaskDifficulty>(
                      title: Text('Сложная'),
                      value: TaskDifficulty.hard,
                      groupValue: _selectedDifficulty,
                      onChanged: (TaskDifficulty? value) {
                        setState(() {
                          _selectedDifficulty = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.0),
            Card(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Подзадачи',
                        style: Theme.of(context).textTheme.titleMedium),
                    SizedBox(height: 8.0),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _subTaskController,
                            decoration: InputDecoration(
                              hintText: 'Добавить подзадачу',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () {
                            if (_subTaskController.text.isNotEmpty) {
                              setState(() {
                                _subTasks.add(_subTaskController.text);
                                _subTaskController.clear();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 8.0),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _subTasks.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(_subTasks[index]),
                          trailing: IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                _subTasks.removeAt(index);
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (_formKey.currentState!.validate() && _selectedDate != null) {
            final task = Task(
              title: _titleController.text,
              description: _descriptionController.text,
              dueDate: _selectedDate!,
              difficulty: _selectedDifficulty,
              subTasks: _subTasks,
            );

            Navigator.pop(context);
          }
        },
        child: Icon(Icons.save),
      ),
    );
  }
}