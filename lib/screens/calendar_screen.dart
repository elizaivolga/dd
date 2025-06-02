import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../models/event.dart';
import '../database/database_helper.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  Map<DateTime, List<Event>> _events = {};
  List<Event> _selectedEvents = [];
  bool _isLoading = false;
  final _dateFormat = DateFormat('dd.MM.yyyy', 'ru_RU');
  final _timeFormat = DateFormat('HH:mm', 'ru_RU');

  // Константы для текущей даты и пользователя
  static const String currentUser = 'elizaivolga';
  static final DateTime currentDate = DateTime.parse('2025-06-02 00:08:52');

  @override
  void initState() {
    super.initState();
    _focusedDay = currentDate;
    _selectedDay = currentDate;
    _initializeCalendar();
  }

  Future<void> _initializeCalendar() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      await initializeDateFormatting('ru_RU');
      await _loadEvents();
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Ошибка при инициализации календаря: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadEvents() async {
    if (!mounted) return;

    try {
      final events = await _db.getEvents(
        DateTime(_focusedDay.year, _focusedDay.month, 1),
        DateTime(_focusedDay.year, _focusedDay.month + 1, 0),
      );

      final eventsByDate = <DateTime, List<Event>>{};

      for (final event in events) {
        final date = DateTime(
          event.startTime.year,
          event.startTime.month,
          event.startTime.day,
        );
        eventsByDate[date] ??= [];
        eventsByDate[date]!.add(event);
      }

      if (!mounted) return;

      setState(() {
        _events = eventsByDate;
        _selectedEvents = _getEventsForDay(_selectedDay);
      });
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Ошибка при загрузке событий: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<Event> _getEventsForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    final events = _events[date] ?? [];
    events.sort((a, b) => a.startTime.compareTo(b.startTime));
    return events;
  }

  Future<void> _showEventDialog([Event? event]) async {
    final titleController = TextEditingController(text: event?.title ?? '');
    final descriptionController = TextEditingController(text: event?.description ?? '');
    final locationController = TextEditingController(text: event?.location ?? '');
    DateTime startTime = event?.startTime ?? _selectedDay;
    Color selectedColor = event?.color ?? Colors.blue;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(event == null ? 'Новое событие' : 'Редактировать событие'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Название',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Описание',
                    border: OutlineInputBorder(),
                    hintText: 'Добавьте описание события...',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Место',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on_outlined),
                    hintText: 'Укажите место проведения...',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('Время'),
                    subtitle: Text(
                      '${_dateFormat.format(startTime)} ${_timeFormat.format(startTime)}',
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: startTime,
                        firstDate: DateTime(2024),
                        lastDate: DateTime(2026),
                        locale: const Locale('ru', 'RU'),
                      );
                      if (date != null && mounted) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(startTime),
                        );
                        if (time != null) {
                          setState(() {
                            startTime = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Цвет события',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Colors.blue,
                            Colors.red,
                            Colors.green,
                            Colors.orange,
                            Colors.purple,
                            Colors.teal,
                            Colors.pink,
                            Colors.indigo,
                            Colors.amber,
                            Colors.cyan,
                            Colors.deepOrange,
                            Colors.deepPurple,
                          ].map((color) => GestureDetector(
                            onTap: () => setState(() => selectedColor = color),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: color == selectedColor
                                    ? Border.all(color: Colors.black, width: 2)
                                    : null,
                              ),
                            ),
                          )).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Введите название события'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                Navigator.pop(context, true);
              },
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final newEvent = Event(
        id: event?.id, // null для нового события, существующий id для редактирования
        title: titleController.text,
        description: descriptionController.text.isEmpty
            ? null
            : descriptionController.text,
        startTime: startTime,
        endTime: startTime.add(const Duration(hours: 1)),
        location: locationController.text.isEmpty
            ? null
            : locationController.text,
        color: selectedColor,
      );

      try {
        if (event == null) {
          await _db.insertEvent(newEvent);
        } else {
          await _db.updateEvent(newEvent);
        }
        await _loadEvents();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(event == null ? 'Событие создано' : 'Событие обновлено'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar(
              event == null
                  ? 'Ошибка при сохранении события: $e'
                  : 'Ошибка при обновлении события: $e'
          );
        }
      }
    }
  }

  Future<void> _deleteEvent(Event event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить событие?'),
        content: Text('Вы уверены, что хотите удалить "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _db.deleteEvent(event.id);
        await _loadEvents();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Событие удалено'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('Ошибка при удалении события: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          TableCalendar<Event>(
            locale: 'ru_RU',
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2026, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getEventsForDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const {
              CalendarFormat.month: 'Месяц',
            },
            calendarStyle: CalendarStyle(
              markersMaxCount: 4,
              markerSize: 8,
              markersAlignment: Alignment.bottomCenter,
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              weekendTextStyle: const TextStyle(color: Colors.red),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekendStyle: TextStyle(color: Colors.red),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return null;

                return Positioned(
                  bottom: 1,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: events.take(4).map((event) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (event as Event).color ?? Theme.of(context).primaryColor,
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
                _selectedEvents = _getEventsForDay(selectedDay);
              });
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
              _loadEvents();
            },
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _selectedEvents.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_available,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Нет событий на ${_dateFormat.format(_selectedDay)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _selectedEvents.length,
              padding: const EdgeInsets.all(8),
              itemBuilder: (context, index) {
                final event = _selectedEvents[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: event.color ?? Theme.of(context).primaryColor,
                      child: const Icon(Icons.event, color: Colors.white),
                    ),
                    title: Text(event.title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (event.description?.isNotEmpty ?? false)
                          Text(
                            event.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        Text(
                          _timeFormat.format(event.startTime),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        if (event.location != null)
                          Text(
                            event.location!,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteEvent(event),
                    ),
                    onTap: () => _showEventDialog(event),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEventDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}