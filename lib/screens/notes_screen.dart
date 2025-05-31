import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/note.dart';
import '../database/database_helper.dart';

class NotesScreen extends StatefulWidget {
  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<Note> _notes = [];
  String _selectedCategory = Note.defaultCategories.first;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final notes = await DatabaseHelper.instance.getNotes(
      category: _selectedCategory == 'Все' ? null : _selectedCategory,
    );
    setState(() {
      _notes = notes;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Заметки'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String category) {
              setState(() {
                _selectedCategory = category;
                _loadNotes();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'Все',
                child: Text('Все категории'),
              ),
              ...Note.defaultCategories.map((category) =>
                  PopupMenuItem(
                    value: category,
                    child: Text(category),
                  ),
              ),
            ],
          ),
        ],
      ),
      body: _notes.isEmpty ? _buildEmptyState() : _buildNotesList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNoteDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_add,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text('Нет заметок'),
          Text('Нажмите + чтобы добавить заметку'),
        ],
      ),
    );
  }

  Widget _buildNotesList() {
    return ListView.builder(
      itemCount: _notes.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final note = _notes[index];
        return Card(
          child: ListTile(
            title: Text(note.title),
            subtitle: Text(
              note.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteNote(note),
            ),
            onTap: () => _showNoteDialog(note: note),
          ),
        );
      },
    );
  }

  Future<void> _showNoteDialog({Note? note}) async {
    final titleController = TextEditingController(text: note?.title ?? '');
    final contentController = TextEditingController(text: note?.content ?? '');
    var selectedCategory = note?.category ?? _selectedCategory;
    String? imagePath = note?.imagePath;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(note == null ? 'Новая заметка' : 'Редактировать заметку'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Заголовок'),
              ),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(labelText: 'Содержание'),
                maxLines: 3,
              ),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: Note.defaultCategories.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? value) {
                  if (value != null) {
                    selectedCategory = value;
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (result == true) {
      final newNote = Note(
        id: note?.id,
        title: titleController.text,
        content: contentController.text,
        category: selectedCategory,
        imagePath: imagePath,
      );

      if (note == null) {
        await DatabaseHelper.instance.insertNote(newNote);
      } else {
        await DatabaseHelper.instance.updateNote(newNote);
      }
      _loadNotes();
    }
  }

  Future<void> _deleteNote(Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить заметку?'),
        content: const Text('Это действие нельзя отменить'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseHelper.instance.deleteNote(note.id!);
      _loadNotes();
    }
  }
}