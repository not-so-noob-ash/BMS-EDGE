import 'package:cloud_firestore/cloud_firestore.dart';

class AchievementModel {
  final String id;
  final String description;
  final List<String> fileUrls;
  final String creatorId;
  final String creatorName;
  final Timestamp createdAt;
  final Map<String, String> taggedUsers;
  final Map<String, String> reactions;
  final int commentCount;
  final int repostCount;
  final Map<String, String> repostedBy; // <-- 1. ADD THIS FIELD

  AchievementModel({
    required this.id,
    required this.description,
    required this.fileUrls,
    required this.creatorId,
    required this.creatorName,
    required this.createdAt,
    required this.taggedUsers,
    required this.reactions,
    required this.commentCount,
    required this.repostCount,
    required this.repostedBy, // <-- 2. ADD TO CONSTRUCTOR
  });

  factory AchievementModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AchievementModel(
      id: doc.id,
      description: data['description'] ?? '',
      fileUrls: List<String>.from(data['fileUrls'] ?? []),
      creatorId: data['creatorId'] ?? '',
      creatorName: data['creatorName'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      taggedUsers: Map<String, String>.from(data['taggedUsers'] ?? {}),
      reactions: Map<String, String>.from(data['reactions'] ?? {}),
      commentCount: data['commentCount'] ?? 0,
      repostCount: data['repostCount'] ?? 0,
      repostedBy: Map<String, String>.from(data['repostedBy'] ?? {}), // <-- 3. ADD TO FACTORY
    );
  }
}