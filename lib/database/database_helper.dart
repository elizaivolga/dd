import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';
import '../models/sub_task.dart';
import '../models/note.dart';
import '../models/achievement.dart';
import '../models/experience.dart';

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
    String path = join(await getDatabasesPath(), 'plana.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Таблица задач
    await db.execute('''
      CREATE TABLE tasks(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        dueDate TEXT NOT NULL,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        priority TEXT,
        reminderTime TEXT,
        experiencePoints INTEGER DEFAULT 0
      )
    ''');

    // Таблица подзадач
    await db.execute('''
      CREATE TABLE sub_tasks(
        id TEXT PRIMARY KEY,
        taskId TEXT NOT NULL,
        title TEXT NOT NULL,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        completedAt TEXT,
        FOREIGN KEY (taskId) REFERENCES tasks (id) ON DELETE CASCADE
      )
    ''');

    // Таблица заметок
    await db.execute('''
      CREATE TABLE notes(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        color TEXT
      )
    ''');

    // Таблица достижений
    await db.execute('''
      CREATE TABLE achievements(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        type TEXT NOT NULL,
        progress INTEGER NOT NULL DEFAULT 0,
        target INTEGER NOT NULL,
        isUnlocked INTEGER NOT NULL DEFAULT 0,
        unlockedAt TEXT,
        icon TEXT
      )
    ''');

    // Таблица опыта
    await db.execute('''
      CREATE TABLE experience(
        id TEXT PRIMARY KEY,
        points INTEGER NOT NULL DEFAULT 0,
        level INTEGER NOT NULL DEFAULT 1,
        lastUpdated TEXT NOT NULL
      )
    ''');

    // Создание индексов
    await db.execute('CREATE INDEX idx_tasks_dueDate ON tasks(dueDate)');
    await db.execute('CREATE INDEX idx_tasks_isCompleted ON tasks(isCompleted)');
    await db.execute('CREATE INDEX idx_subtasks_taskId ON sub_tasks(taskId)');
    await db.execute('CREATE INDEX idx_notes_createdAt ON notes(createdAt)');
    await db.execute('CREATE INDEX idx_achievements_type ON achievements(type)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Здесь будет код миграции при обновлении схемы БД
  }

  // Общие CRUD операции
  Future<void> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> query(
      String table, {
        String? where,
        List<dynamic>? whereArgs,
        String? orderBy,
      }) async {
    final db = await database;
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
    );
  }

  Future<void> update(
      String table,
      Map<String, dynamic> data, {
        String? where,
        List<dynamic>? whereArgs,
      }) async {
    final db = await database;
    await db.update(
      table,
      data,
      where: where,
      whereArgs: whereArgs,
    );
  }

  Future<void> delete(
      String table, {
        String? where,
        List<dynamic>? whereArgs,
      }) async {
    final db = await database;
    await db.delete(
      table,
      where: where,
      whereArgs: whereArgs,
    );
  }

  // Операции с задачами
  Future<void> insertTask(Task task) async {
    await insert('tasks', task.toMap());
  }

  Future<List<Task>> getTasks() async {
    final maps = await query('tasks', orderBy: 'dueDate ASC');
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  Future<List<Task>> getTasksByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final maps = await query(
      'tasks',
      where: 'dueDate >= ? AND dueDate < ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'dueDate ASC',
    );
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  // Операции с подзадачами
  Future<void> insertSubTask(SubTask subTask) async {
    await insert('sub_tasks', subTask.toMap());
  }

  Future<List<SubTask>> getSubTasks(String taskId) async {
    final maps = await query(
      'sub_tasks',
      where: 'taskId = ?',
      whereArgs: [taskId],
      orderBy: 'createdAt ASC',
    );
    return List.generate(maps.length, (i) => SubTask.fromMap(maps[i]));
  }

  // Операции с заметками
  Future<void> insertNote(Note note) async {
    await insert('notes', note.toMap());
  }

  Future<List<Note>> getNotes() async {
    final maps = await query('notes', orderBy: 'createdAt DESC');
    return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
  }

  // Операции с достижениями
  Future<void> insertAchievement(Achievement achievement) async {
    await insert('achievements', achievement.toMap());
  }

  Future<List<Achievement>> getAchievements() async {
    final maps = await query('achievements');
    return List.generate(maps.length, (i) => Achievement.fromMap(maps[i]));
  }

  // Операции с опытом
  Future<void> updateExperience(Experience experience) async {
    await update(
      'experience',
      experience.toMap(),
      where: 'id = ?',
      whereArgs: [experience.id],
    );
  }

  Future<Experience?> getExperience() async {
    final maps = await query('experience');
    if (maps.isEmpty) return null;
    return Experience.fromMap(maps.first);
  }

  // Транзакционные операции
  Future<void> completeTaskWithRewards(String taskId) async {
    final db = await database;
    await db.transaction((txn) async {
      // Обновляем статус задачи
      await txn.update(
        'tasks',
        {'isCompleted': 1},
        where: 'id = ?',
        whereArgs: [taskId],
      );

      // Получаем опыт пользователя
      final expMaps = await txn.query('experience');
      if (expMaps.isNotEmpty) {
        final exp = Experience.fromMap(expMaps.first);
        final updatedExp = exp.copyWith(
          points: exp.points + 10,
          lastUpdated: DateTime.now(),
        );
        await txn.update(
          'experience',
          updatedExp.toMap(),
          where: 'id = ?',
          whereArgs: [exp.id],
        );
      }
    });
  }

  // Методы очистки и обслуживания
  Future<void> deleteCompletedTasks() async {
    await delete('tasks', where: 'isCompleted = ?', whereArgs: [1]);
  }

  Future<void> vacuum() async {
    final db = await database;
    await db.execute('VACUUM');
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}