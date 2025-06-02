import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  static const String currentUser = 'elizaivolga';
  static final DateTime currentDate = DateTime.parse('2025-06-02 00:50:48');

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
              return SwitchListTile(
                title: const Text('Темная тема'),
                subtitle: Text(
                  isDarkMode ? 'Включена' : 'Выключена',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                secondary: Icon(
                  isDarkMode ? Icons.dark_mode : Icons.light_mode,
                ),
                value: isDarkMode,
                onChanged: (value) {
                  appState.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                },
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
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Очистить данные?'),
                  content: const Text(
                    'Это действие удалит все ваши задачи, заметки и настройки. '
                        'Это действие нельзя отменить.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Отмена'),
                    ),
                    TextButton(
                      onPressed: () {
                        final appState = context.read<AppState>();
                        appState.resetSettings();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Все данные очищены'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Удалить'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

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

  void _showResetDialog(BuildContext context, AppState appState) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сбросить настройки?'),
        content: const Text(
          'Все настройки будут возвращены к значениям по умолчанию. Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              appState.resetSettings();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Настройки сброшены'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
  }
