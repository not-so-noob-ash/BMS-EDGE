import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> initNotifications() async {
    // Request permission from the user
    await _fcm.requestPermission();

    // Get the FCM token for this device
    final String? token = await _fcm.getToken();

    if (token != null) {
      print("FCM Token: $token");
      // Save the token to the current user's Firestore document
      await _saveTokenToDatabase(token);
    }
    
    // Listen for token refreshes
    _fcm.onTokenRefresh.listen(_saveTokenToDatabase);
  }

  Future<void> _saveTokenToDatabase(String token) async {
    final User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        // Using FieldValue.arrayUnion ensures we don't add duplicate tokens
        'fcmTokens': FieldValue.arrayUnion([token]),
      });
    }
  }
}