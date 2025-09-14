import 'package:flutter/material.dart';
import '../../data/services/auth_service.dart'; // Import for sign out

class HodDashboard extends StatelessWidget {
  const HodDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
     final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("HOD Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authService.signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
           children: [
            if (user?.photoURL != null)
              CircleAvatar(
                backgroundImage: NetworkImage(user!.photoURL!),
                radius: 40,
              ),
            const SizedBox(height: 16),
            Text("Welcome, ${user?.displayName ?? 'HOD'}!"),
            Text(user?.email ?? ""),
            // TODO: Add HOD specific features here
          ],
        )
      ),
    );
  }
}