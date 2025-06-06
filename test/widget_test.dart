// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:plana/screens/tasks_screen.dart';
import 'package:plana/models/task.dart';
import 'package:plana/database/database_helper.dart';


import 'widget_test.mocks.dart';

// Генерируем мок классы
@GenerateMocks([DatabaseHelper])
void main() {
  late MockDatabaseHelper mockDb;
  late List<Task> mockTasks;
  late DateTime testDate;

  setUp(() {
    mockDb = MockDatabaseHelper();
    testDate = DateTime(2024, 1, 1);

    // Создаем тестовые данные
    mockTasks = [
      Task(
        id: '1',
        title: 'Тестовая задача 1',
        description: 'Описание задачи 1',
        dueDate: testDate.add(const Duration(days: 1)),
        subTasks: [
          SubTask(text: 'Подзадача 1', isCompleted: false),
          SubTask(text: 'Подзадача 2', isCompleted: true),
        ],
      ),
      Task(
        id: '2',
        title: 'Тестовая задача 2',
        dueDate: testDate.subtract(const Duration(days: 1)),
        isCompleted: true,
        subTasks: [],
      ),
    ];
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: TasksScreen(
        databaseHelper: mockDb,
        selectedDate: testDate,
      ),
    );
  }

  group('TasksScreen Widget Tests', () {
    testWidgets('shows empty state when no tasks',
            (WidgetTester tester) async {
          // Arrange
          when(mockDb.getTasksByDate(any))
              .thenAnswer((_) => Future.value([]));

          // Act
          await tester.pumpWidget(createWidgetUnderTest());
          await tester.pumpAndSettle();

          // Assert
          expect(find.text('Нет активных задач'), findsOneWidget);
          expect(find.byIcon(Icons.task_outlined), findsOneWidget);
        });

    testWidgets('shows list of tasks when tasks exist',
            (WidgetTester tester) async {
          // Arrange
          when(mockDb.getTasksByDate(any))
              .thenAnswer((_) => Future.value(mockTasks));

          // Act
          await tester.pumpWidget(createWidgetUnderTest());
          await tester.pumpAndSettle();

          // Assert
          expect(find.text('Тестовая задача 1'), findsOneWidget);
          expect(find.text('Тестовая задача 2'), findsOneWidget);
        });


  });

  group('Task Completion Tests', () {
    testWidgets('completes task when checkbox is tapped',
            (WidgetTester tester) async {
          // Arrange
          when(mockDb.getTasksByDate(any))
              .thenAnswer((_) => Future.value(mockTasks));
          when(mockDb.completeTask(any)).thenAnswer((_) => Future.value());

          // Act
          await tester.pumpWidget(createWidgetUnderTest());
          await tester.pumpAndSettle();

          // Находим и нажимаем на чекбокс первой задачи
          final checkbox = find.byType(Checkbox).first;
          await tester.tap(checkbox);
          await tester.pumpAndSettle();

          // Assert
          verify(mockDb.completeTask('1')).called(1);
        });
  });

  group('Task Deletion Tests', () {
    testWidgets('deletes task when delete button is tapped',
            (WidgetTester tester) async {
          // Arrange
          when(mockDb.getTasksByDate(any))
              .thenAnswer((_) => Future.value(mockTasks));
          when(mockDb.deleteTask(any)).thenAnswer((_) => Future.value(1));

          // Act
          await tester.pumpWidget(createWidgetUnderTest());
          await tester.pumpAndSettle();

          // Находим и нажимаем кнопку удаления
          final deleteButton = find.byIcon(Icons.delete_outline).first;
          await tester.tap(deleteButton);
          await tester.pumpAndSettle();

          // Assert
          verify(mockDb.deleteTask('1')).called(1);
        });
  });
}