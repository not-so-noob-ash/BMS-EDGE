import 'package:cloud_firestore/cloud_firestore.dart';

class WorkloadModel {
  final String id;
  final String title;
  final String type;
  final DateTime date;
  final String startTime;       // <-- ADDED: e.g., "14:00"
  final int durationMinutes;  // <-- ADDED: e.g., 60

  WorkloadModel({
    required this.id,
    required this.title,
    required this.type,
    required this.date,
    required this.startTime,     // <-- ADDED
    required this.durationMinutes, // <-- ADDED
  });

  factory WorkloadModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return WorkloadModel(
      id: doc.id,
      title: data['title'] ?? '',
      type: data['type'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      startTime: data['startTime'] ?? '09:00', // <-- ADDED
      durationMinutes: data['durationMinutes'] ?? 60, // <-- ADDED
    );
  }
}