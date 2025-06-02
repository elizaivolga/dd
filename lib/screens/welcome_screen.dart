import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'home_screen.dart';

class WelcomeScreen extends StatefulWidget {
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Добро пожаловать в Plana',
      'description': 'Ваш личный помощник в планировании и достижении целей',
      'icon': Icons.task_alt,
    },
    {
      'title': 'Умное планирование',
      'description': 'Создавайте задачи, подзадачи и отслеживайте их выполнение',
      'icon': Icons.note_alt_outlined,
    },
    {
      'title': 'Система достижений',
      'description': 'Получайте опыт и награды за выполненные задачи',
      'icon': Icons.emoji_events,
    },
    {
      'title': 'Анализ и статистика',
      'description': 'Отслеживайте свой прогресс и эффективность',
      'icon': Icons.analytics,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildPage(
                    title: _pages[index]['title'],
                    description: _pages[index]['description'],
                    icon: _pages[index]['icon'],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                          (index) => _buildDotIndicator(index),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildNavigationButtons(),
                  if (_currentPage == _pages.length - 1) ...[
                    const SizedBox(height: 16),
                    _buildDontShowAgainCheckbox(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 120,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 32),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDotIndicator(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _currentPage == index
            ? Theme.of(context).primaryColor
            : Colors.grey,
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (_currentPage > 0)
          TextButton(
            onPressed: () {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: const Text('Назад'),
          ),
        ElevatedButton(
          onPressed: () {
            if (_currentPage < _pages.length - 1) {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            } else {
              _finishOnboarding();
            }
          },
          child: Text(_currentPage < _pages.length - 1 ? 'Далее' : 'Начать'),
        ),
      ],
    );
  }

  Widget _buildDontShowAgainCheckbox() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Checkbox(
          value: !context.watch<AppState>().showWelcomeScreen,
          onChanged: (value) {
            context.read<AppState>().setShowWelcomeScreen(!value!);
          },
        ),
        const Text('Больше не показывать'),
      ],
    );
  }

  void _finishOnboarding() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );
  }
}