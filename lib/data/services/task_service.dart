import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_model.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // For the calendar: Get tasks assigned TO a specific user
  Stream<List<TaskModel>> getTasksForUser(String userId) {
    return _firestore
        .collection('tasks')
        .where('assignedToIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList());
  }

  // For managers/faculty to create and assign a new task
  Future<void> createTask({
    required String title,
    required String details,
    required DateTime date,
    required String startTime,
    required int durationMinutes,
    required List<String> assignedToIds,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('tasks').add({
      'title': title,
      'details': details,
      'date': Timestamp.fromDate(date),
      'startTime': startTime,
      'durationMinutes': durationMinutes,
      'assignedById': user.uid,
      'assignedByName': user.displayName ?? 'N/A',
      'assignedToIds': assignedToIds,
    });
  }
}