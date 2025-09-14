import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String title;
  final String details;
  final DateTime date;
  final String startTime;
  final int durationMinutes;

  final String assignedById;
  final String assignedByName; // This is the correct field name
  final List<String> assignedToIds;

  TaskModel({
    required this.id,
    required this.title,
    required this.details,
    required this.date,
    required this.startTime,
    required this.durationMinutes,
    required this.assignedById,
    required this.assignedByName,
    required this.assignedToIds,
  });

  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TaskModel(
      id: doc.id,
      title: data['title'] ?? '',
      details: data['details'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      startTime: data['startTime'] ?? '09:00',
      durationMinutes: data['durationMinutes'] ?? 60,
      assignedById: data['assignedById'] ?? '',
      assignedByName: data['assignedByName'] ?? '',
      assignedToIds: List<String>.from(data['assignedToIds'] ?? []),
    );
  }
}