import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String text;
  final String commenterId;
  final String commenterName;
  final String commenterPhotoUrl;
  final Timestamp timestamp;

  CommentModel({
    required this.id,
    required this.text,
    required this.commenterId,
    required this.commenterName,
    required this.commenterPhotoUrl,
    required this.timestamp,
  });

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CommentModel(
      id: doc.id,
      text: data['text'] ?? '',
      commenterId: data['commenterId'] ?? '',
      commenterName: data['commenterName'] ?? '',
      commenterPhotoUrl: data['commenterPhotoUrl'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }
}