import 'package:cloud_firestore/cloud_firestore.dart';

class HolidayModel {
  final String name;
  final DateTime date;

  HolidayModel({required this.name, required this.date});

  factory HolidayModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return HolidayModel(
      name: data['name'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
    );
  }
}