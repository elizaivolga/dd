import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';
import '../models/event.dart';
import '../models/experience.dart';
import '../models/note.dart';
import '../models/achievement.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'plana_db.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Таблица задач
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tasks(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        dueDate TEXT NOT NULL,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        difficulty INTEGER NOT NULL DEFAULT 0,
        subTasks TEXT,
        experiencePoints INTEGER DEFAULT 0
      )
    ''');

    // Таблица событий календаря
    await db.execute('''
      CREATE TABLE IF NOT EXISTS events(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        startTime TEXT NOT NULL,
        endTime TEXT NOT NULL,
        location TEXT,
        color TEXT
      )
    ''');

    // Таблица опыта
    await db.execute('''
      CREATE TABLE IF NOT EXISTS experience(
        id TEXT PRIMARY KEY,
        points INTEGER NOT NULL DEFAULT 0,
        level INTEGER NOT NULL DEFAULT 1,
        lastUpdated TEXT NOT NULL
      )
    ''');

    // Таблица статистики
    await db.execute('''
      CREATE TABLE IF NOT EXISTS statistics(
        date TEXT PRIMARY KEY,
        tasksCompleted INTEGER NOT NULL DEFAULT 0,
        totalTasks INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Таблица заметок
    await db.execute('''
      CREATE TABLE IF NOT EXISTS notes(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT,
        category TEXT NOT NULL,
        imagePath TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT
      )
    ''');

    // Таблица достижений
    await db.execute('''
      CREATE TABLE IF NOT EXISTS achievements(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        iconPath TEXT NOT NULL,
        xpRequired INTEGER NOT NULL,
        isUnlocked INTEGER NOT NULL DEFAULT 0,
        unlockedAt TEXT
      )
    ''');

    // Создание индексов
    await db.execute('CREATE INDEX IF NOT EXISTS idx_tasks_dueDate ON tasks(dueDate)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_tasks_completed ON tasks(isCompleted)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_events_startTime ON events(startTime)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE tasks ADD COLUMN difficulty INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE tasks ADD COLUMN subTasks TEXT');
      await db.execute('ALTER TABLE tasks ADD COLUMN experiencePoints INTEGER DEFAULT 0');
    }
  }

  // CRUD операции для задач
  Future<int> insertTask(Task task) async {
    final db = await database;
    final taskMap = task.toMap();
    if (taskMap['subTasks'] != null) {
      taskMap['subTasks'] = jsonEncode(task.subTasks);
    }
    return await db.insert('tasks', taskMap, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Task>> getTasks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('tasks', orderBy: 'dueDate ASC');

    return maps.map((map) {
      List<String> subTasks = [];
      if (map['subTasks'] != null) {
        subTasks = List<String>.from(jsonDecode(map['subTasks']));
      }

      return Task(
        id: map['id'],
        title: map['title'],
        description: map['description'],
        dueDate: DateTime.parse(map['dueDate']),
        isCompleted: map['isCompleted'] == 1,
        createdAt: DateTime.parse(map['createdAt']),
        difficulty: TaskDifficulty.values[map['difficulty']],
        subTasks: subTasks,
      );
    }).toList();
  }

  Future<List<Task>> getTasksByDate(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'dueDate BETWEEN ? AND ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'dueDate ASC',
    );

    return maps.map((map) {
      List<String> subTasks = [];
      if (map['subTasks'] != null) {
        subTasks = List<String>.from(jsonDecode(map['subTasks']));
      }
      return Task(
        id: map['id'],
        title: map['title'],
        description: map['description'],
        dueDate: DateTime.parse(map['dueDate']),
        isCompleted: map['isCompleted'] == 1,
        createdAt: DateTime.parse(map['createdAt']),
        difficulty: TaskDifficulty.values[map['difficulty']],
        subTasks: subTasks,
      );
    }).toList();
  }

  Future<int> updateTask(Task task) async {
    final db = await database;
    final taskMap = task.toMap();
    if (taskMap['subTasks'] != null) {
      taskMap['subTasks'] = jsonEncode(task.subTasks);
    }
    return await db.update(
      'tasks',
      taskMap,
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(String taskId) async {
    final db = await database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  // CRUD операции для событий календаря
  Future<int> insertEvent(Event event) async {
    final db = await database;
    return await db.insert('events', event.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Event>> getEvents(DateTime start, DateTime end) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      where: 'startTime BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'startTime ASC',
    );

    return maps.map((map) => Event.fromMap(map)).toList();
  }

  Future<int> deleteEvent(String eventId) async {
    final db = await database;
    return await db.delete(
      'events',
      where: 'id = ?',
      whereArgs: [eventId],
    );
  }

  // Операции с заметками
  Future<int> insertNote(Note note) async {
    final db = await database;
    return await db.insert('notes', note.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Note>> getNotes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      orderBy: 'createdAt DESC',
    );

    return maps.map((map) => Note.fromMap(map)).toList();
  }

  Future<int> updateNote(Note note) async {
    final db = await database;
    return await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> deleteNote(String noteId) async {
    final db = await database;
    return await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [noteId],
    );
  }

  // Операции с опытом
  Future<Experience?> getExperience() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('experience');

    if (maps.isEmpty) {
      final initialExperience = Experience(
        points: 0,
        level: 1,
        lastUpdated: DateTime.now(),
      );
      await updateExperience(initialExperience);
      return initialExperience;
    }

    return Experience.fromMap(maps.first);
  }

  Future<void> updateExperience(Experience experience) async {
    final db = await database;
    await db.insert(
      'experience',
      experience.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Операции со статистикой
  Future<Map<String, int>> getStatistics(DateTime date) async {
    final db = await database;
    final dateStr = date.toIso8601String().split('T')[0];

    final List<Map<String, dynamic>> result = await db.query(
      'statistics',
      where: 'date = ?',
      whereArgs: [dateStr],
    );

    if (result.isEmpty) {
      return {
        'tasksCompleted': 0,
        'totalTasks': 0,
      };
    }

    return {
      'tasksCompleted': result.first['tasksCompleted'] as int,
      'totalTasks': result.first['totalTasks'] as int,
    };
  }

  Future<void> updateStatistics(DateTime date, int completed, int total) async {
    final db = await database;
    final dateStr = date.toIso8601String().split('T')[0];

    await db.insert(
      'statistics',
      {
        'date': dateStr,
        'tasksCompleted': completed,
        'totalTasks': total,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Операции с достижениями
  Future<void> unlockAchievement(String achievementId) async {
    final db = await database;
    await db.update(
      'achievements',
      {
        'isUnlocked': 1,
        'unlockedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [achievementId],
    );
  }

  Future<List<Achievement>> getAchievements() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('achievements');
    return maps.map((map) => Achievement.fromMap(map)).toList();
  }

  // Комплексные операции
  Future<void> completeTask(String taskId) async {
    final db = await database;
    await db.transaction((txn) async {
      // Обновляем статус задачи
      await txn.update(
        'tasks',
        {
          'isCompleted': 1,
          'experiencePoints': 100,
        },
        where: 'id = ?',
        whereArgs: [taskId],
      );

      // Получаем и обновляем опыт
      final exp = await getExperience() ??
          Experience(points: 0, level: 1, lastUpdated: DateTime.now());
      exp.addXP(100);
      await updateExperience(exp);

      // Обновляем статистику
      final today = DateTime.now();
      final stats = await getStatistics(today);
      await updateStatistics(
        today,
        stats['tasksCompleted']! + 1,
        stats['totalTasks']!,
      );

      // Проверяем достижения
      if (exp.points >= 100) {
        await unlockAchievement('first_hundred_xp');
      }
    });
  }

  // Служебные методы
  Future<void> clearDatabase() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.execute('DROP TABLE IF EXISTS tasks');
      await txn.execute('DROP TABLE IF EXISTS events');
      await txn.execute('DROP TABLE IF EXISTS experience');
      await txn.execute('DROP TABLE IF EXISTS statistics');
      await txn.execute('DROP TABLE IF EXISTS notes');
      await txn.execute('DROP TABLE IF EXISTS achievements');
    });
    await _onCreate(db, 2);
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}