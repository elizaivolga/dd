import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../database/database_helper.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  static const String currentUser = 'elizaivolga';
  static final DateTime currentDate = DateTime.parse('2025-06-02 00:50:48');

  void _showThemeDialog(BuildContext context, AppState appState) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выберите тему'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Системная'),
              value: ThemeMode.system,
              groupValue: appState.themeMode,
              onChanged: (value) {
                appState.setThemeMode(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Светлая'),
              value: ThemeMode.light,
              groupValue: appState.themeMode,
              onChanged: (value) {
                appState.setThemeMode(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Темная'),
              value: ThemeMode.dark,
              groupValue: appState.themeMode,
              onChanged: (value) {
                appState.setThemeMode(value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resetAllData(BuildContext context) async {
    try {
      final appState = context.read<AppState>();
      final db = DatabaseHelper();

      // Показываем индикатор загрузки
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Очищаем базу данных
      await db.clearDatabase();

      // Сбрасываем настройки приложения
      appState.resetSettings();

      // Закрываем индикатор загрузки
      Navigator.pop(context);

      // Показываем уведомление об успешном сбросе
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Все данные успешно очищены'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      // В случае ошибки показываем сообщение
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при очистке данных: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showResetDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сбросить все данные?'),
        content: const Text(
          'Это действие приведет к удалению:\n\n'
              '• Всех задач и подзадач\n'
              '• Всех заметок\n'
              '• Статистики и достижений\n'
              '• Настроек приложения\n\n'
              'Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetAllData(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Удалить все'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
      ),
      body: ListView(
        children: [
          Consumer<AppState>(
            builder: (context, appState, child) {
              final isDarkMode = appState.themeMode == ThemeMode.dark;
              return ListTile(
                title: const Text('Тема приложения'),
                subtitle: Text(
                  isDarkMode ? 'Темная тема' : 'Светлая тема',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                leading: Icon(
                  isDarkMode ? Icons.dark_mode : Icons.light_mode,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showThemeDialog(context, appState),
              );
            },
          ),
          const Divider(),
          Consumer<AppState>(
            builder: (context, appState, child) {
              return SwitchListTile(
                title: const Text('Экран приветствия'),
                subtitle: Text(
                  appState.showWelcomeScreen ? 'Показывать' : 'Не показывать',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                secondary: const Icon(Icons.slideshow),
                value: appState.showWelcomeScreen,
                onChanged: (value) => appState.setShowWelcomeScreen(value),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Очистить данные'),
            subtitle: const Text('Удалить все задачи и настройки'),
            onTap: () => _showResetDialog(context),
          ),
        ],
      ),
    );
  }
}