import 'package:cloud_firestore/cloud_firestore.dart';

class LeaveBalanceModel {
  final String leaveType;
  final int year;
  final num allocatedDays;
  final num takenDays;

  LeaveBalanceModel({
    required this.leaveType,
    required this.year,
    required this.allocatedDays,
    required this.takenDays,
  });

  // A helpful getter to calculate remaining days
  double get remainingDays => (allocatedDays - takenDays).toDouble();

  factory LeaveBalanceModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return LeaveBalanceModel(
      leaveType: data['leaveType'] ?? '',
      year: data['year'] ?? DateTime.now().year,
      allocatedDays: data['allocatedDays'] ?? 0,
      takenDays: data['takenDays'] ?? 0,
    );
  }
}