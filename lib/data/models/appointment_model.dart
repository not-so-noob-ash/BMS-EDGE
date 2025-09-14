import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentModel {
  final String id;
  final String subject;
  final String bookedByUid;
  final String bookedByName;
  final DateTime appointmentTime;
  final int durationMinutes;

  AppointmentModel({
    required this.id,
    required this.subject,
    required this.bookedByUid,
    required this.bookedByName,
    required this.appointmentTime,
    required this.durationMinutes,
  });

  factory AppointmentModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AppointmentModel(
      id: doc.id,
      subject: data['subject'] ?? '',
      bookedByUid: data['bookedByUid'] ?? '',
      bookedByName: data['bookedByName'] ?? '',
      appointmentTime: (data['appointmentTime'] as Timestamp).toDate(),
      durationMinutes: data['durationMinutes'] ?? 30,
    );
  }
}