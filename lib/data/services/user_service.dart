import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- PROFILE METHODS ---
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }

  Future<void> updateUserProfile({
    required String uid,
    required String name,
    required String department,
    required String teacherPost,
    required DateTime dateOfJoining,
    required String clusterName,
    required List<String> additionalRoles,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'name': name,
      'department': department,
      'teacherPost': teacherPost,
      'dateOfJoining': Timestamp.fromDate(dateOfJoining),
      'clusterName': clusterName,
      'additionalRoles': additionalRoles,
    });
  }

  // --- HIERARCHY & TEAM MANAGEMENT METHODS ---
  Stream<List<UserModel>> getUsersReportingTo(String managerId) {
    return _firestore
        .collection('users')
        .where('reportsTo', isEqualTo: managerId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
  }

  Future<void> appointClusterHead({
    required String facultyUid,
    required String hodUid,
    required String clusterName,
  }) async {
    await _firestore.collection('users').doc(facultyUid).update({
      'role': 'ClusterHead',
      'reportsTo': hodUid,
      'clusterName': clusterName,
    });
  }

  // --- NEW: For an HOD to assign a faculty to a Cluster Head ---
  Future<void> assignFacultyToClusterHead({
    required String facultyUid,
    required String clusterHeadUid,
    required String clusterName,
  }) async {
    await _firestore.collection('users').doc(facultyUid).update({
      'reportsTo': clusterHeadUid,
      'clusterName': clusterName,
    });
  }

  // --- NEW: For an HOD to un-assign a faculty from a cluster ---
  Future<void> unassignFacultyFromCluster(String facultyUid) async {
    await _firestore.collection('users').doc(facultyUid).update({
      'reportsTo': '',
      'clusterName': '',
    });
  }
  
  // --- NEW: Get all faculty who are not yet in a cluster ---
  Stream<List<UserModel>> getUnassignedFaculty() {
      return _firestore
          .collection('users')
          .where('role', isEqualTo: 'Faculty')
          .where('reportsTo', isEqualTo: '')
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
  }

  // --- SEARCH METHODS ---
// This function searches for users by their name.
Stream<List<UserModel>> searchUsers(String query) {
    if (query.trim().isEmpty) return Stream.value([]);
    
    // The query must also be lowercase to match the data
    final lowerCaseQuery = query.toLowerCase();
    String endQuery = lowerCaseQuery.substring(0, lowerCaseQuery.length - 1) +
        String.fromCharCode(lowerCaseQuery.codeUnitAt(lowerCaseQuery.length - 1) + 1);

    return _firestore
        .collection('users')
        .where('searchableName', isGreaterThanOrEqualTo: lowerCaseQuery)
        .where('searchableName', isLessThan: endQuery)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
  }

  // Searches by role (case-insensitive keyword search)
  Stream<List<UserModel>> searchUsersByRole(String roleQuery) {
    if (roleQuery.trim().isEmpty) return Stream.value([]);

    // The query must also be lowercase
    final lowerCaseQuery = roleQuery.toLowerCase();
    
    return _firestore
        .collection('users')
        .where('searchableRoles', arrayContains: lowerCaseQuery)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
  }
  
  // --- UTILITY METHODS ---
 
}