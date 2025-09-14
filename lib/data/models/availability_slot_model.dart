import 'package:cloud_firestore/cloud_firestore.dart';

class AvailabilitySlotModel {
  final String id;
  final int dayOfWeek; // Monday = 1, Sunday = 7
  final String startTime; // "14:00"
  final String endTime;   // "16:00"
  final int slotDurationMinutes;

  AvailabilitySlotModel({
    required this.id,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.slotDurationMinutes,
  });

  factory AvailabilitySlotModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AvailabilitySlotModel(
      id: doc.id,
      dayOfWeek: data['dayOfWeek'] ?? 1,
      startTime: data['startTime'] ?? '09:00',
      endTime: data['endTime'] ?? '17:00',
      slotDurationMinutes: data['slotDurationMinutes'] ?? 30,
    );
  }
}