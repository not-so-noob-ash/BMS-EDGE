import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

// Import all your models and the CalendarService
import '../../data/models/class_model.dart';
import '../../data/models/event_model.dart';
import '../../data/models/holiday_model.dart';
import '../../data/models/leave_application_model.dart';
import '../../data/models/task_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/calendar_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final ValueNotifier<List<dynamic>> _selectedEvents;
  final CalendarService _calendarService = CalendarService();
  final String _userId = AuthService().currentUser!.uid;

  LinkedHashMap<DateTime, List<dynamic>> _eventsByDate = LinkedHashMap(
    equals: isSameDay,
    hashCode: (key) => key.day * 1000000 + key.month * 10000 + key.year,
  );

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));

    // Fetch static holiday data ONLY ONCE
    _calendarService.getHolidays().then((holidays) {
      for (final holiday in holidays) {
        final date = DateTime.utc(holiday.date.year, holiday.date.month, holiday.date.day);
        _addEvent(date, holiday);
      }
      if (mounted) {
        setState(() {});
        _selectedEvents.value = _getEventsForDay(_selectedDay!);
      }
    });

    // Subscribe to dynamic data streams
    _subscribeToDataStreams();
  }
  
  // This function now only handles dynamic stream data.
  void _subscribeToDataStreams() {
    _calendarService.getAllCalendarData(_userId).listen((data) {
      if (mounted) _processStreamData(data);
    });
  }

  void _processStreamData(Map<String, List<dynamic>> data) {
    // Clear previous dynamic data, but KEEP the holidays.
    _eventsByDate.removeWhere((key, value) => value.any((item) => item is! HolidayModel));

    (data['events'] as List<EventModel>).forEach((item) => _addEvent(item.eventDate, item));
    (data['tasks'] as List<TaskModel>).forEach((item) => _addEvent(item.date, item));
    (data['leaves'] as List<LeaveApplicationModel>).forEach((item) {
      for (var day = 0; day <= item.endDate.difference(item.startDate).inDays; day++) {
        _addEvent(item.startDate.add(Duration(days: day)), item);
      }
    });
    _populateRecurringClasses(data['classes'] as List<ClassModel>);
    
    setState(() {});
    _selectedEvents.value = _getEventsForDay(_selectedDay!);
  }

  void _addEvent(DateTime date, dynamic event) {
    final normalizedDate = DateTime.utc(date.year, date.month, date.day);
    _eventsByDate[normalizedDate] = [...(_eventsByDate[normalizedDate] ?? []), event];
  }

  void _populateRecurringClasses(List<ClassModel> classes) {
    DateTime firstDay = DateTime.utc(_focusedDay.year, _focusedDay.month, 1);
    DateTime lastDay = DateTime.utc(_focusedDay.year, _focusedDay.month + 1, 0);

    for(var day = firstDay; day.isBefore(lastDay.add(const Duration(days: 1))); day = day.add(const Duration(days: 1))) {
      for (final aClass in classes) {
        if (day.weekday == aClass.dayOfWeek) {
          _addEvent(day, aClass);
        }
      }
    }
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    final events = _eventsByDate[DateTime.utc(day.year, day.month, day.day)] ?? [];
    events.sort((a, b) {
      String timeA = "00:00";
      String timeB = "00:00";
      if (a is ClassModel) timeA = a.startTime;
      if (b is ClassModel) timeB = b.startTime;
      if (a is TaskModel) timeA = a.startTime;
      if (b is TaskModel) timeB = b.startTime;
      return timeA.compareTo(timeB);
    });
    return events;
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      _selectedEvents.value = _getEventsForDay(selectedDay);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Calendar & Schedule')),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: _onDaySelected,
            eventLoader: _getEventsForDay,
            onFormatChanged: (format) {
              if (_calendarFormat != format) setState(() => _calendarFormat = format);
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
                _selectedDay = focusedDay;
              });
              _subscribeToDataStreams();
            },
            calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (events.isNotEmpty) {
                    return Positioned(
                      right: 1,
                      bottom: 1,
                      child: _buildEventsMarker(context, events),
                    );
                  }
                  return null;
                },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              'Schedule for ${DateFormat.yMMMd().format(_selectedDay ?? DateTime.now())}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<List<dynamic>>(
              valueListenable: _selectedEvents,
              builder: (context, value, _) {
                if (value.isEmpty) {
                  return const Center(child: Text("No scheduled activities for this day."));
                }
                
                final allDayEvents = value.where((e) => e is HolidayModel || e is LeaveApplicationModel || e is EventModel).toList();
                final timedEvents = value.where((e) => e is ClassModel || e is TaskModel).toList();

                return Column(
                  children: [
                    if (allDayEvents.isNotEmpty)
                      _buildAllDaySection(allDayEvents),
                    Expanded(child: _buildDailyTimetable(timedEvents)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsMarker(BuildContext context, List<dynamic> events) {
      return Row(
          mainAxisSize: MainAxisSize.min,
          children: events.take(3).map((event) {
              Color dotColor = Colors.grey;
              if (event is EventModel) dotColor = Colors.blue;
              if (event is TaskModel) dotColor = Colors.red;
              if (event is ClassModel) dotColor = Colors.purple;
              if (event is LeaveApplicationModel) dotColor = Colors.orange;
              if (event is HolidayModel) dotColor = Colors.green;
              return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
              );
          }).toList(),
      );
  }

  Widget _buildAllDaySection(List<dynamic> allDayEvents) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...allDayEvents.map((item) => _buildAgendaItem(item, isAllDay: true)).toList(),
        const Divider(),
      ],
    );
  }
  
  Widget _buildDailyTimetable(List<dynamic> timedEvents) {
    List<DateTime> timeSlots = [];
    final day = _selectedDay!;
    for (int hour = 8; hour < 18; hour++) {
      timeSlots.add(DateTime(day.year, day.month, day.day, hour));
    }

    final Map<String, dynamic> eventsByTime = {
      for (var event in timedEvents) _getTimeStringFromItem(event): event
    };
    
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: timeSlots.length,
      itemBuilder: (context, index) {
        final slotTime = timeSlots[index];
        final timeString = DateFormat.jm().format(slotTime);
        final event = eventsByTime[DateFormat('HH:mm').format(slotTime)];

        return Row(
          children: [
            SizedBox(
              width: 80,
              height: 60,
              child: Center(child: Text(timeString, style: TextStyle(color: Colors.grey[700]))),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                height: 60,
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade300, width: 0.5)),
                ),
                child: event != null ? _buildAgendaItem(event) : null,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAgendaItem(dynamic item, {bool isAllDay = false}) {
    IconData icon;
    Color color;
    String title;
    String subtitle;
    String? trailing;

    if (item is HolidayModel) {
      icon = Icons.celebration; color = Colors.green; title = item.name; subtitle = "Holiday";
    } else if (item is EventModel) {
      icon = Icons.event; color = Colors.blue; title = item.title; subtitle = "College Event";
    } else if (item is LeaveApplicationModel) {
      icon = Icons.beach_access; color = Colors.orange; title = 'On Leave'; subtitle = item.leaveType;
    } else if (item is TaskModel) {
      icon = Icons.assignment_turned_in; color = Colors.red; title = item.title;
      subtitle = item.assignedByName == 'Self' ? 'Personal Task' : 'Assigned by ${item.assignedByName}';
      trailing = item.startTime;
    } else if (item is ClassModel) {
      icon = Icons.school; color = Colors.purple; title = item.title; subtitle = 'Class';
      trailing = '${item.startTime} - ${item.endTime}';
    } else {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: isAllDay ? const EdgeInsets.symmetric(horizontal: 12, vertical: 4) : const EdgeInsets.only(top: 2, bottom: 2),
      decoration: BoxDecoration(
        color: isAllDay ? color.withOpacity(0.1) : Colors.transparent,
        border: isAllDay ? null : Border(left: BorderSide(color: color, width: 4)),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle),
        trailing: trailing != null ? Text(trailing, style: TextStyle(color: Colors.grey[600])) : null,
        dense: !isAllDay,
      ),
    );
  }

  String _getTimeStringFromItem(dynamic item) {
    if (item is ClassModel) return item.startTime;
    if (item is TaskModel) return item.startTime;
    if (item is EventModel) return DateFormat('HH:mm').format(item.eventDate);
    return "00:00";
  }
}