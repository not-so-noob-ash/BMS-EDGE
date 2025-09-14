import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Stream for auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  /// Google Sign-In function
  Future<User?> signInWithGoogle() async {
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        // Web
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        // Mobile
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null; // User cancelled the sign-in

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCredential = await _auth.signInWithCredential(credential);
      }

      final user = userCredential.user;
      if (user != null) {
        // Check if user exists in Firestore, if not, create a new document
        // with all necessary default fields.
        await _createUserDocument(user);
      }
      return user;
    } catch (e) {
      print("Google Sign-In failed: $e");
      return null;
    }
  }

  // --- THIS IS THE UPDATED FUNCTION ---
  /// Create user document in Firestore if it doesn't exist, initializing all fields.
  Future<void> _createUserDocument(User user) async {
    final userDoc = _firestore.collection('users').doc(user.uid);
    final snapshot = await userDoc.get();

    if (!snapshot.exists) {
      print("Creating new user document for ${user.uid}");
      await userDoc.set({
        // Basic info from Google
        'name': user.displayName ?? 'New Faculty',
        'email': user.email,
        'photoUrl': user.photoURL ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        
        // --- NEW: Initialize all necessary fields with default values ---
        'role': 'Faculty',          // Default role is always Faculty
        'department': '',           // Empty, to be filled in via "Edit Profile"
        'teacherPost': '',          // Empty, to be filled in via "Edit Profile"
        'dateOfJoining': null,      // Null, to be filled in via "Edit Profile"
        'reportsTo': '',            // Empty, crucial for the "unassigned" query
        'clusterName': '',          // Empty, to be assigned by an HOD
        'additionalRoles': [],      // Empty array for future roles
      });
    }
  }
  
  /// Get user role from Firestore
  Future<String?> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data()?['role'];
    } catch (e) {
      print("Error getting user role: $e");
      return null;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }
    await _auth.signOut();
  }
}