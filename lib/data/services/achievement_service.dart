import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/achievement_model.dart';
import '../models/comment_model.dart';

class AchievementService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Stream<List<AchievementModel>> getAchievementsStream() {
    return _firestore
        .collection('achievements')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AchievementModel.fromFirestore(doc))
          .toList();
    });
  }

  Stream<List<AchievementModel>> getAchievementsForUser(String userId) {
    return _firestore
        .collection('achievements')
        .where('creatorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => AchievementModel.fromFirestore(doc)).toList();
    });
  }

  Future<void> setReaction({required String achievementId, required String newReactionType}) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final docRef = _firestore.collection('achievements').doc(achievementId);
    final docSnapshot = await docRef.get();
    final currentReactions = Map<String, String>.from(docSnapshot.data()?['reactions'] ?? {});

    if (currentReactions[currentUser.uid] == newReactionType) {
      await docRef.update({
        'reactions.${currentUser.uid}': FieldValue.delete(),
      });
    } else {
      await docRef.update({
        'reactions.${currentUser.uid}': newReactionType,
      });
    }
  }

  Future<bool> postAchievement({required String description, required List<File> files, required Map<String, String> taggedUsers}) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      final List<String> downloadUrls = [];
      for (final file in files) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
        final ref = _storage.ref().child('achievements/${currentUser.uid}/$fileName');
        final uploadTask = ref.putFile(file);
        final snapshot = await uploadTask.whenComplete(() => {});
        final downloadUrl = await snapshot.ref.getDownloadURL();
        downloadUrls.add(downloadUrl);
      }

      await _firestore.collection('achievements').add({
        'description': description,
        'fileUrls': downloadUrls,
        'creatorId': currentUser.uid,
        'creatorName': currentUser.displayName ?? 'Anonymous Faculty',
        'createdAt': FieldValue.serverTimestamp(),
        'taggedUsers': taggedUsers,
        'reactions': {},
        'commentCount': 0,
        'repostCount': 0,
        'repostedBy': {}, // Initialize the new field
      });
      return true;
    } catch (e) {
      print("Error posting achievement: $e");
      return false;
    }
  }

  Stream<List<CommentModel>> getComments(String achievementId) {
    return _firestore
        .collection('achievements').doc(achievementId)
        .collection('comments')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => CommentModel.fromFirestore(doc)).toList());
  }

  Future<void> addComment(String achievementId, String text) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final commentRef = _firestore.collection('achievements').doc(achievementId).collection('comments').doc();
    final achievementRef = _firestore.collection('achievements').doc(achievementId);

    await _firestore.runTransaction((transaction) async {
      transaction.set(commentRef, {
        'text': text,
        'commenterId': user.uid,
        'commenterName': user.displayName ?? 'N/A',
        'commenterPhotoUrl': user.photoURL ?? '',
        'timestamp': FieldValue.serverTimestamp(),
      });
      transaction.update(achievementRef, {'commentCount': FieldValue.increment(1)});
    });
  }

  // --- REPLACED repostAchievement WITH toggleRepost ---
  Future<void> toggleRepost(AchievementModel originalPost) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final originalPostRef = _firestore.collection('achievements').doc(originalPost.id);
    final isAlreadyReposted = originalPost.repostedBy.containsKey(user.uid);

    if (isAlreadyReposted) {
      // --- UN-REPOST LOGIC ---
      final repostIdToDelete = originalPost.repostedBy[user.uid];
      if (repostIdToDelete == null) return;
      final repostRef = _firestore.collection('achievements').doc(repostIdToDelete);

      await _firestore.runTransaction((transaction) async {
        transaction.delete(repostRef);
        transaction.update(originalPostRef, {
          'repostCount': FieldValue.increment(-1),
          'repostedBy.${user.uid}': FieldValue.delete(),
        });
      });
    } else {
      // --- REPOST LOGIC ---
      final newPostRef = _firestore.collection('achievements').doc();

      await _firestore.runTransaction((transaction) async {
        transaction.set(newPostRef, {
          'creatorId': user.uid,
          'creatorName': user.displayName ?? 'N/A',
          'createdAt': FieldValue.serverTimestamp(),
          'description': originalPost.description,
          'fileUrls': originalPost.fileUrls,
          'taggedUsers': originalPost.taggedUsers,
          'originalPost': {
            'originalCreatorName': originalPost.creatorName,
            'originalPostId': originalPost.id,
          },
          'commentCount': 0, 'repostCount': 0, 'reactions': {}, 'repostedBy': {},
        });
        transaction.update(originalPostRef, {
          'repostCount': FieldValue.increment(1),
          'repostedBy.${user.uid}': newPostRef.id,
        });
      });
    }
  }
}