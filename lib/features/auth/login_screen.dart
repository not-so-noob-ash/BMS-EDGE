import 'package:flutter/material.dart';
import '../../data/services/auth_service.dart'; // Import the service

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return Scaffold(
      appBar: AppBar(title: const Text("Faculty Social App")),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: () {
            // Call the service to handle sign-in
            authService.signInWithGoogle();
          },
          icon: const Icon(Icons.login),
          label: const Text("Sign in with Google"),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}