import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'data/services/auth_service.dart';
import 'data/services/notification_service.dart';
import 'features/auth/login_screen.dart';
import 'features/home/main_navigation_screen.dart'; // This is now the single entry point

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<String?> _initAndGetUserRole(String uid) async {
    if (!kIsWeb) {
      await NotificationService().initNotifications();
    }
    return await AuthService().getUserRole(uid);
  }

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        return FutureBuilder<String?>(
          future: _initAndGetUserRole(snapshot.data!.uid),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            if (roleSnapshot.hasError) {
              authService.signOut();
              return const LoginScreen();
            }

            // All authenticated users are directed to the main navigation screen,
            // which will then adapt its UI based on the user's role.
            return const MainNavigationScreen();
          },
        );
      },
    );
  }
}