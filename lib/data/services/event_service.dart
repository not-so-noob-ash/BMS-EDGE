import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event_model.dart';

class EventService {
  final CollectionReference _eventsCollection = FirebaseFirestore.instance.collection('events');
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> addEvent({
    required String title,
    required String description,
    required DateTime eventDate,
    required bool isPublic,
  }) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception("User not logged in");
    }

    await _eventsCollection.add({
      'title': title,
      'description': description,
      'eventDate': Timestamp.fromDate(eventDate),
      'isPublic': isPublic,
      'creatorId': currentUser.uid,
      'creatorName': currentUser.displayName ?? 'Anonymous Faculty',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<EventModel>> getPublicEventsStream() {
    return _eventsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
    });
  }

  // Get all events relevant to a user for their calendar
  Stream<List<EventModel>> getEventsForUserCalendar(String userId) {
    return _eventsCollection
        .where('isPublic', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
    });
  }
}