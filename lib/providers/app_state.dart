import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState extends ChangeNotifier {
  // Состояния приложения
  ThemeMode _themeMode = ThemeMode.system;
  bool _showWelcomeScreen = true;
  bool _isLoading = false;
  String _currentFilter = 'all';
  String _sortOrder = 'dueDate';

  // Геттеры для доступа к состояниям
  ThemeMode get themeMode => _themeMode;
  bool get showWelcomeScreen => _showWelcomeScreen;
  bool get isLoading => _isLoading;
  String get currentFilter => _currentFilter;
  String get sortOrder => _sortOrder;

  // Конструктор
  AppState() {
    _loadSettings();
  }

  // Загрузка сохраненных настроек
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Загружаем тему
      _themeMode = ThemeMode.values[
      prefs.getInt('theme_mode') ?? ThemeMode.system.index
      ];

      // Загружаем статус экрана приветствия
      _showWelcomeScreen = prefs.getBool('show_welcome_screen') ?? true;

      // Загружаем текущий фильтр
      _currentFilter = prefs.getString('current_filter') ?? 'all';

      // Загружаем порядок сортировки
      _sortOrder = prefs.getString('sort_order') ?? 'dueDate';

      notifyListeners();
    } catch (e) {
      debugPrint('Ошибка при загрузке настроек: $e');
    }
  }

  // Установка темы
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('theme_mode', mode.index);
      notifyListeners();
    }
  }

  // Управление экраном приветствия
  Future<void> setShowWelcomeScreen(bool show) async {
    if (_showWelcomeScreen != show) {
      _showWelcomeScreen = show;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('show_welcome_screen', show);
      notifyListeners();
    }
  }

  // Установка состояния загрузки
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  // Установка текущего фильтра
  Future<void> setCurrentFilter(String filter) async {
    if (_currentFilter != filter) {
      _currentFilter = filter;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_filter', filter);
      notifyListeners();
    }
  }

  // Установка порядка сортировки
  Future<void> setSortOrder(String order) async {
    if (_sortOrder != order) {
      _sortOrder = order;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('sort_order', order);
      notifyListeners();
    }
  }

  // Сброс всех настроек
  Future<void> resetSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    _themeMode = ThemeMode.system;
    _showWelcomeScreen = true;
    _currentFilter = 'all';
    _sortOrder = 'dueDate';

    notifyListeners();
  }
}