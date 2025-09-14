import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String photoUrl;
  final String department;
  final String teacherPost;
  final Timestamp? dateOfJoining;

  // --- HIERARCHY FIELDS ---
  final String role; // "Faculty", "ClusterHead", "HOD"
  final String reportsTo; // The UID of the user's manager
  final String clusterName;
  final List<String> additionalRoles; // e.g., "Time Table Incharge"

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.photoUrl,
    this.department = '',
    this.teacherPost = '',
    this.dateOfJoining,
    this.role = 'Faculty',
    this.reportsTo = '',
    this.clusterName = '',
    this.additionalRoles = const [],
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      department: data['department'] ?? '',
      teacherPost: data['teacherPost'] ?? '',
      dateOfJoining: data['dateOfJoining'],
      role: data['role'] ?? 'Faculty',
      reportsTo: data['reportsTo'] ?? '',
      clusterName: data['clusterName'] ?? '',
      additionalRoles: List<String>.from(data['additionalRoles'] ?? []),
    );
  }
}