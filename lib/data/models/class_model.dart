import 'package:cloud_firestore/cloud_firestore.dart';

class ClassModel {
  final String title;
  final int dayOfWeek; // Monday = 1, Sunday = 7
  final String startTime;
  final String endTime;

  ClassModel({
    required this.title,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  factory ClassModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ClassModel(
      title: data['title'] ?? '',
      dayOfWeek: data['dayOfWeek'] ?? 1,
      startTime: data['startTime'] ?? '00:00',
      endTime: data['endTime'] ?? '00:00',
    );
  }
}