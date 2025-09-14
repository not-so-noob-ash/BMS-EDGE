import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String description;
  final DateTime eventDate;
  final String creatorId;
  final String creatorName;
  final bool isPublic;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.eventDate,
    required this.creatorId,
    required this.creatorName,
    required this.isPublic,
  });

  // A factory constructor to create an EventModel from a Firestore document
  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      eventDate: (data['eventDate'] as Timestamp).toDate(),
      creatorId: data['creatorId'] ?? '',
      creatorName: data['creatorName'] ?? '',
      isPublic: data['isPublic'] ?? false,
    );
  }
}