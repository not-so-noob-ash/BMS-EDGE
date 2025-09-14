import 'package:cloud_firestore/cloud_firestore.dart';

class LeaveApplicationModel {
  final String id;
  final String applicantId;
  final String applicantName;
  final String leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  
  // --- NEW WORKFLOW FIELDS ---
  final String status; // "Pending Cluster Head Approval", "Pending HOD Approval", "Approved", "Rejected"
  final String clusterHeadApproverId;
  final String hodApproverId;
  final String? rejectionReason;

  LeaveApplicationModel({
    required this.id,
    required this.applicantId,
    required this.applicantName,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
    required this.clusterHeadApproverId,
    required this.hodApproverId,
    this.rejectionReason,
  });

  factory LeaveApplicationModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return LeaveApplicationModel(
      id: doc.id,
      applicantId: data['applicantId'] ?? '',
      applicantName: data['applicantName'] ?? '',
      leaveType: data['leaveType'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      reason: data['reason'] ?? '',
      status: data['status'] ?? 'pending',
      clusterHeadApproverId: data['clusterHeadApproverId'] ?? '',
      hodApproverId: data['hodApproverId'] ?? '',
      rejectionReason: data['rejectionReason'],
    );
  }
}