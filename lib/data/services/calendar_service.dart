import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

// Import all necessary models and services
import '../models/class_model.dart';
import '../models/event_model.dart';
import '../models/holiday_model.dart';
import '../models/leave_application_model.dart';
import '../models/task_model.dart'; // <-- UPDATED from workload_model
import 'event_service.dart';
import 'leave_service.dart';
import 'task_service.dart'; // <-- UPDATED from workload_service

class CalendarService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Updated to combine 5 streams, now using TaskService
  Stream<Map<String, List<dynamic>>> getAllCalendarData(String userId) {
    final eventService = EventService();
    final leaveService = LeaveService();
    final taskService = TaskService(); // <-- UPDATED

    return Rx.combineLatest5(
      eventService.getEventsForUserCalendar(userId),
      leaveService.getApprovedLeavesForUser(userId),
      taskService.getTasksForUser(userId), // <-- UPDATED
      _getClassesForUser(userId),
      _getAcademicTasks(),
      (
        List<EventModel> events,
        List<LeaveApplicationModel> leaves,
        List<TaskModel> personalTasks, // <-- UPDATED
        List<ClassModel> classes,
        List<TaskModel> academicTasks,
      ) {
        final allTasks = [...personalTasks, ...academicTasks];
        return {
          'events': events,
          'leaves': leaves,
          'tasks': allTasks, // <-- UPDATED from 'workloads'
          'classes': classes,
        };
      },
    );
  }

  // Helper to get academic tasks that apply to everyone
  Stream<List<TaskModel>> _getAcademicTasks() {
    return _firestore
        .collection('academicTasks')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList());
  }

  // Private helper to get recurring classes for a user
  Stream<List<ClassModel>> _getClassesForUser(String userId) {
    return _firestore
        .collection('users').doc(userId)
        .collection('classes')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ClassModel.fromFirestore(doc)).toList());
  }
  
  // Public method to get global holidays
  Future<List<HolidayModel>> getHolidays() async {
    final snapshot = await _firestore.collection('holidays').get();
    return snapshot.docs.map((doc) => HolidayModel.fromFirestore(doc)).toList();
  }
}