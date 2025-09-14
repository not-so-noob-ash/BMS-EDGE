import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/leave_application_model.dart';
import '../models/leave_balance_model.dart'; 
import 'user_service.dart';

class LeaveService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  Stream<List<LeaveBalanceModel>> getLeaveBalancesForUser(String userId) {
    return _firestore
        .collection('users').doc(userId)
        .collection('leaveBalances')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => LeaveBalanceModel.fromFirestore(doc)).toList());
  }
  // --- UPGRADED: applyForLeave now finds the full approval chain ---
  Future<void> applyForLeave({
    required String leaveType,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final applicantProfile = await _userService.getUserProfile(user.uid);
    if (applicantProfile == null || applicantProfile.reportsTo.isEmpty) {
      throw Exception("Your profile is not configured with a manager. Cannot apply for leave.");
    }
    final clusterHeadId = applicantProfile.reportsTo;

    final clusterHeadProfile = await _userService.getUserProfile(clusterHeadId);
    if (clusterHeadProfile == null || clusterHeadProfile.reportsTo.isEmpty) {
      throw Exception("Your manager is not configured with an HOD. Cannot apply for leave.");
    }
    final hodId = clusterHeadProfile.reportsTo;

    await _firestore.collection('leaveApplications').add({
      'applicantId': user.uid,
      'applicantName': user.displayName ?? 'N/A',
      'clusterHeadApproverId': clusterHeadId,
      'hodApproverId': hodId,
      'leaveType': leaveType,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'reason': reason,
      'status': 'Pending Cluster Head Approval',
      'appliedOn': FieldValue.serverTimestamp(),
    });
  }

  // --- NEW: A single, powerful function for managers to approve or reject leaves ---
  Future<void> processLeaveRequest({
    required String applicationId,
    required bool isApproved,
    required String currentUserRole,
    String? rejectionReason,
  }) async {
    final applicationRef = _firestore.collection('leaveApplications').doc(applicationId);

    if (!isApproved) {
      await applicationRef.update({
        'status': 'Rejected',
        'rejectionReason': rejectionReason ?? 'No reason provided.',
      });
      return;
    }

    if (currentUserRole == 'ClusterHead') {
      await applicationRef.update({'status': 'Pending HOD Approval'});
    }

    if (currentUserRole == 'HOD') {
      final doc = await applicationRef.get();
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;
      final daysToDeduct = (data['endDate'] as Timestamp).toDate().difference((data['startDate'] as Timestamp).toDate()).inDays + 1;
      final applicantId = data['applicantId'];
      final leaveType = data['leaveType'];
      
      final leaveBalanceDocId = '${leaveType.replaceAll('/', '-').replaceAll(' ', '_').toLowerCase()}_${DateTime.now().year}';
      final leaveBalanceRef = _firestore.collection('users').doc(applicantId).collection('leaveBalances').doc(leaveBalanceDocId);

      await _firestore.runTransaction((transaction) async {
        transaction.update(applicationRef, {'status': 'Approved'});
        transaction.update(leaveBalanceRef, {'takenDays': FieldValue.increment(daysToDeduct)});
      });
    }
  }

  // --- NEW: Get pending requests specifically for the currently logged-in manager ---
  Stream<List<LeaveApplicationModel>> getPendingRequestsForManager(String managerId, String managerRole) {
    String statusFilter;
    String approverIdField;

    if (managerRole == 'ClusterHead') {
      statusFilter = 'Pending Cluster Head Approval';
      approverIdField = 'clusterHeadApproverId';
    } else if (managerRole == 'HOD') {
      statusFilter = 'Pending HOD Approval';
      approverIdField = 'hodApproverId';
    } else {
      return Stream.value([]);
    }

    return _firestore
        .collection('leaveApplications')
        .where('status', isEqualTo: statusFilter)
        .where(approverIdField, isEqualTo: managerId)
        .orderBy('appliedOn')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => LeaveApplicationModel.fromFirestore(doc)).toList()); // <-- TYPO FIXED HERE
  }
  
  // --- METHODS THAT REMAIN UNCHANGED ---

  Stream<List<LeaveApplicationModel>> getLeaveHistory(String userId) {
    return _firestore
        .collection('leaveApplications')
        .where('applicantId', isEqualTo: userId)
        .orderBy('appliedOn', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LeaveApplicationModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<LeaveApplicationModel>> getApprovedLeavesForUser(String userId) {
    return _firestore
        .collection('leaveApplications')
        .where('applicantId', isEqualTo: userId)
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LeaveApplicationModel.fromFirestore(doc))
            .toList());
  }
}