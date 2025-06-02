import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';
import '../models/event.dart';
import '../models/experience.dart';
import '../models/note.dart';
import '../models/achievement.dart';

class DatabaseException implements Exception {
  final String message;
  DatabaseException(this.message);

  @override
  String toString() => message;
}

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
    try {
      final db = await database;
      final taskMap = task.toMap();

      // Преобразуем подзадачи в JSON
      if (task.subTasks.isNotEmpty) {
        final subTasksJson = task.subTasks.map((subTask) => {
          'text': subTask.text,
          'isCompleted': subTask.isCompleted,
        }).toList();
        taskMap['subTasks'] = jsonEncode(subTasksJson);
      } else {
        taskMap['subTasks'] = null;
      }


      final dateStr = task.dueDate.toIso8601String().split('T')[0];

      final List<Map<String, dynamic>> statsData = await db.query(
        'statistics',
        where: 'date = ?',
        whereArgs: [dateStr],
      );

      final completed = (statsData.isEmpty ? 0 : statsData.first['tasksCompleted'] as int);
      final total = (statsData.isEmpty ? 1 : statsData.first['totalTasks'] as int) + 1;

      await db.insert(
        'statistics',
        {
          'date': dateStr,
          'tasksCompleted': completed,
          'totalTasks': total,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return await db.insert(
        'tasks',
        taskMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw DatabaseException('Ошибка при добавлении задачи: $e');
    }
  }

  Future<List<Task>> getTasks() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'tasks',
        orderBy: 'dueDate ASC, isCompleted ASC',
      );

      return maps.map((map) {
        // Парсим подзадачи из JSON
        List<SubTask> subTasks = [];
        if (map['subTasks'] != null) {
          try {
            final List<dynamic> subTasksData = jsonDecode(map['subTasks']);
            subTasks = subTasksData.map((subTaskMap) => SubTask(
              text: subTaskMap['text'] as String,
              isCompleted: subTaskMap['isCompleted'] as bool,
            )).toList();
          } catch (e) {
            print('Ошибка при разборе подзадач: $e');
            // В случае ошибки возвращаем пустой список подзадач
            subTasks = [];
          }
        }

        // Создаем объект Task
        return Task(
          id: map['id'],
          title: map['title'],
          description: map['description'],
          dueDate: DateTime.parse(map['dueDate']),
          isCompleted: map['isCompleted'] == 1,
          createdAt: DateTime.parse(map['createdAt']),
          difficulty: TaskDifficulty.values[map['difficulty'] ?? 0],
          subTasks: subTasks,
          experiencePoints: map['experiencePoints'] ?? 0,
        );
      }).toList();
    } catch (e) {
      throw DatabaseException('Ошибка при получении задач: $e');
    }
  }

  Future<List<Task>> getTasksByDate(DateTime date) async {
    try {
      final db = await database;
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final List<Map<String, dynamic>> maps = await db.query(
        'tasks',
        where: 'dueDate BETWEEN ? AND ?',
        whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
        orderBy: 'dueDate ASC, isCompleted ASC',
      );

      return maps.map((map) {
        List<SubTask> subTasks = [];
        if (map['subTasks'] != null) {
          try {
            final List<dynamic> subTasksJson = jsonDecode(map['subTasks']);
            subTasks = subTasksJson.map((subTaskMap) => SubTask(
              text: subTaskMap['text'] as String,
              isCompleted: subTaskMap['isCompleted'] as bool,
            )).toList();
          } catch (e) {
            print('Ошибка при разборе подзадач: $e');
            subTasks = [];
          }
        }

        return Task(
          id: map['id'],
          title: map['title'],
          description: map['description'],
          dueDate: DateTime.parse(map['dueDate']),
          isCompleted: map['isCompleted'] == 1,
          createdAt: DateTime.parse(map['createdAt']),
          difficulty: TaskDifficulty.values[map['difficulty'] ?? 0],
          subTasks: subTasks,
          experiencePoints: map['experiencePoints'] ?? 0,
        );
      }).toList();
    } catch (e) {
      throw DatabaseException('Ошибка при получении задач по дате: $e');
    }
  }

  Future<int> updateTask(Task task) async {
    try {
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
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw DatabaseException('Ошибка при обновлении задачи: $e');
    }
  }

  Future<void> completeTask(String taskId) async {
    final db = await database;
    await db.transaction((txn) async {
      try {
        // Получаем задачу для определения сложности
        final List<Map<String, dynamic>> taskData = await txn.query(
          'tasks',
          where: 'id = ?',
          whereArgs: [taskId],
        );

        if (taskData.isEmpty) return;

        final taskMap = taskData.first;
        List<SubTask> subTasks = [];

        // Правильно парсим подзадачи из JSON
        if (taskMap['subTasks'] != null) {
          try {
            final List<dynamic> subTasksJson = jsonDecode(taskMap['subTasks']);
            subTasks = subTasksJson.map((subTaskMap) => SubTask(
              text: subTaskMap['text'] as String,
              isCompleted: true, // Помечаем все подзадачи как выполненные
            )).toList();
          } catch (e) {
            print('Ошибка при разборе подзадач: $e');
            subTasks = [];
          }
        }

        final task = Task(
          id: taskMap['id'],
          title: taskMap['title'],
          description: taskMap['description'],
          dueDate: DateTime.parse(taskMap['dueDate']),
          isCompleted: true,
          createdAt: DateTime.parse(taskMap['createdAt']),
          difficulty: TaskDifficulty.values[taskMap['difficulty'] ?? 0],
          subTasks: subTasks,
          experiencePoints: taskMap['experiencePoints'] ?? 0,
        );

        final xpToAdd = task.getExperiencePoints();

        // Обновляем задачу с новыми подзадачами
        final updatedTaskMap = task.toMap();
        if (subTasks.isNotEmpty) {
          final subTasksJson = subTasks.map((subTask) => {
            'text': subTask.text,
            'isCompleted': subTask.isCompleted,
          }).toList();
          updatedTaskMap['subTasks'] = jsonEncode(subTasksJson);
        }

        // Обновляем статус задачи и подзадач
        await txn.update(
          'tasks',
          updatedTaskMap,
          where: 'id = ?',
          whereArgs: [taskId],
        );

        // Получаем текущий опыт внутри транзакции
        final List<Map<String, dynamic>> expData = await txn.query('experience');
        Experience exp;
        if (expData.isEmpty) {
          exp = Experience(
            points: 0,
            level: 1,
            lastUpdated: DateTime.now(),
          );
        } else {
          exp = Experience.fromMap(expData.first);
        }

        // Обновляем опыт
        exp.addXP(xpToAdd);
        await txn.insert(
          'experience',
          exp.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Обновляем статистику
        final today = DateTime.now();
        final dateStr = today.toIso8601String().split('T')[0];

        final List<Map<String, dynamic>> statsData = await txn.query(
          'statistics',
          where: 'date = ?',
          whereArgs: [dateStr],
        );

        final completed = (statsData.isEmpty ? 0 : statsData.first['tasksCompleted'] as int) + 1;
        final total = (statsData.isEmpty ? 1 : statsData.first['totalTasks'] as int) + 1;

        await txn.insert(
          'statistics',
          {
            'date': dateStr,
            'tasksCompleted': completed,
            'totalTasks': total,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } catch (e) {
        throw DatabaseException('Ошибка при выполнении задачи: $e');
      }
    });
  }

  Future<void> uncompleteTask(String taskId) async {
    final db = await database;
    await db.transaction((txn) async {
      try {
        await txn.update(
          'tasks',
          {
            'isCompleted': 0,
            'experiencePoints': 0,
          },
          where: 'id = ?',
          whereArgs: [taskId],
        );

        // Обновляем статистику
        final today = DateTime.now();
        final dateStr = today.toIso8601String().split('T')[0];

        final List<Map<String, dynamic>> statsData = await txn.query(
          'statistics',
          where: 'date = ?',
          whereArgs: [dateStr],
        );

        if (statsData.isNotEmpty) {
          final completed = (statsData.first['tasksCompleted'] as int) - 1;
          await txn.update(
            'statistics',
            {'tasksCompleted': completed > 0 ? completed : 0},
            where: 'date = ?',
            whereArgs: [dateStr],
          );
        }
      } catch (e) {
        throw DatabaseException('Ошибка при отмене выполнения задачи: $e');
      }
    });
  }

  Future<int> deleteTask(String taskId) async {
    try {
      final db = await database;
      return await db.delete(
        'tasks',
        where: 'id = ?',
        whereArgs: [taskId],
      );
    } catch (e) {
      throw DatabaseException('Ошибка при удалении задачи: $e');
    }
  }

  // CRUD операции для событий календаря
  Future<int> insertEvent(Event event) async {
    try {
      final db = await database;
      return await db.insert('events', event.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      throw DatabaseException('Ошибка при добавлении события: $e');
    }
  }

  Future<List<Event>> getEvents(DateTime start, DateTime end) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'events',
        where: 'startTime BETWEEN ? AND ?',
        whereArgs: [start.toIso8601String(), end.toIso8601String()],
        orderBy: 'startTime ASC',
      );

      return maps.map((map) => Event.fromMap(map)).toList();
    } catch (e) {
      throw DatabaseException('Ошибка при получении событий: $e');
    }
  }

  Future<int> deleteEvent(String eventId) async {
    try {
      final db = await database;
      return await db.delete(
        'events',
        where: 'id = ?',
        whereArgs: [eventId],
      );
    } catch (e) {
      throw DatabaseException('Ошибка при удалении события: $e');
    }
  }
  Future<void> updateEvent(Event event) async {
    final db = await database;
    await db.update(
      'events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }
  // Операции с заметками
  Future<int> insertNote(Note note) async {
    try {
      final db = await database;
      return await db.insert('notes', note.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      throw DatabaseException('Ошибка при добавлении заметки: $e');
    }
  }

  Future<List<Note>> getNotes() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'notes',
        orderBy: 'createdAt DESC',
      );

      return maps.map((map) => Note.fromMap(map)).toList();
    } catch (e) {
      throw DatabaseException('Ошибка при получении заметок: $e');
    }
  }

  Future<int> updateNote(Note note) async {
    try {
      final db = await database;
      return await db.update(
        'notes',
        note.toMap(),
        where: 'id = ?',
        whereArgs: [note.id],
      );
    } catch (e) {
      throw DatabaseException('Ошибка при обновлении заметки: $e');
    }
  }

  Future<int> deleteNote(String noteId) async {
    try {
      final db = await database;
      return await db.delete(
        'notes',
        where: 'id = ?',
        whereArgs: [noteId],
      );
    } catch (e) {
      throw DatabaseException('Ошибка при удалении заметки: $e');
    }
  }

  // Операции с опытом
  Future<Experience?> getExperience() async {
    try {
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
    } catch (e) {
      throw DatabaseException('Ошибка при получении опыта: $e');
    }
  }

  Future<void> updateExperience(Experience experience) async {
    try {
      final db = await database;
      await db.insert(
        'experience',
        experience.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw DatabaseException('Ошибка при обновлении опыта: $e');
    }
  }

  // Операции со статистикой
  Future<Map<String, int>> getStatistics(DateTime date) async {
    try {
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
    } catch (e) {
      throw DatabaseException('Ошибка при получении статистики: $e');
    }
  }

  Future<void> updateStatistics(DateTime date, int completed, int total) async {
    try {
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
    } catch (e) {
      throw DatabaseException('Ошибка при обновлении статистики: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getStatisticsForLastDays(int days) async {
    try {
      final db = await database;
      final now = DateTime.now();
      final List<Map<String, dynamic>> result = [];

      // Получаем статистику за каждый день
      for (int i = days - 1; i >= 0; i--) {
        final date = DateTime(now.year, now.month, now.day - i);
        final dateStr = date.toIso8601String().split('T')[0];

        final List<Map<String, dynamic>> dayStats = await db.query(
          'statistics',
          where: 'date = ?',
          whereArgs: [dateStr],
        );

        result.add({
          'date': date,
          'tasksCompleted': dayStats.isEmpty ? 0 : dayStats.first['tasksCompleted'] as int,
        });
      }

      return result;
    } catch (e) {
      throw DatabaseException('Ошибка при получении статистики: $e');
    }
  }

  // Операции с достижениями
  Future<void> unlockAchievement(String achievementId) async {
    try {
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
    } catch (e) {
      throw DatabaseException('Ошибка при разблокировке достижения: $e');
    }
  }

  Future<List<Achievement>> getAchievements() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('achievements');
      return maps.map((map) => Achievement.fromMap(map)).toList();
    } catch (e) {
      throw DatabaseException('Ошибка при получении достижений: $e');
    }
  }

  // Служебные методы
  Future<void> clearDatabase() async {
    try {
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
    } catch (e) {
      throw DatabaseException('Ошибка при очистке базы данных: $e');
    }
  }


  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}