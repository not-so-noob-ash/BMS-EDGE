import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workload_model.dart';

class WorkloadService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<WorkloadModel>> getWorkloadsForUser(String userId) {
    return _firestore
        .collection('workloads')
        .where('assignedToId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => WorkloadModel.fromFirestore(doc)).toList());
  }
}