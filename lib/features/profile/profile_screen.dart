import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/achievement_model.dart';
import '../../data/models/user_model.dart';
import '../../data/services/achievement_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/user_service.dart';
import '../home/faculty_dashboard.dart'; // To reuse the AchievementCard
import '../leaves/leave_dashboard_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  final String userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final userService = UserService();
    final achievementService = AchievementService();
    final authService = AuthService();
    final currentUserId = authService.currentUser?.uid;
    final isMyProfile = userId == currentUserId;

    return FutureBuilder<UserModel?>(
      future: userService.getUserProfile(userId),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!userSnapshot.hasData || userSnapshot.data == null) {
          return Scaffold(appBar: AppBar(), body: const Center(child: Text('User profile not found.')));
        }

        final user = userSnapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: Text(isMyProfile ? 'My Profile' : 'Faculty Profile'),
            actions: [
              if (isMyProfile)
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit Profile',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfileScreen(user: user),
                      ),
                    );
                  },
                ),
              if (isMyProfile)
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Logout',
                  onPressed: () {
                    authService.signOut();
                  },
                ),
            ],
          ),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
                        child: user.photoUrl.isEmpty ? const Icon(Icons.person, size: 50) : null,
                      ),
                      const SizedBox(height: 12),
                      Text(user.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      if (user.teacherPost.isNotEmpty && user.department.isNotEmpty)
                        Text('${user.teacherPost}, ${user.department}'),
                      
                      // --- NEW: HIERARCHY AND ROLE INFO ---
                      const SizedBox(height: 8),
                      if (user.clusterName.isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Cluster: ${user.clusterName}', style: const TextStyle(fontStyle: FontStyle.italic)),
                            // Display the manager's name if they have one
                            if (user.reportsTo.isNotEmpty)
                              _ManagerInfo(managerId: user.reportsTo),
                          ],
                        ),
                      
                      if (user.additionalRoles.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Wrap(
                            spacing: 8.0,
                            runSpacing: 4.0,
                            alignment: WrapAlignment.center,
                            children: user.additionalRoles.map((role) => Chip(
                              label: Text(role),
                              avatar: const Icon(Icons.star_border, size: 16),
                              labelStyle: const TextStyle(fontSize: 12),
                            )).toList(),
                          ),
                        ),
                      // --- END OF NEW SECTION ---
                        
                      if (user.dateOfJoining != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text('Joined: ${DateFormat.yMMMd().format(user.dateOfJoining!.toDate())}', style: const TextStyle(color: Colors.grey)),
                        ),
                      
                      if (isMyProfile) ...[
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.calendar_today_outlined),
                          label: const Text('Leave Management'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey[50],
                            foregroundColor: Colors.blueGrey[800],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const LeaveDashboardScreen()),
                            );
                          },
                        ),
                      ]
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: Divider(thickness: 1)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Center(child: Text("Achievements", style: Theme.of(context).textTheme.titleLarge)),
                ),
              ),
              StreamBuilder<List<AchievementModel>>(
                stream: achievementService.getAchievementsForUser(userId),
                builder: (context, achievementSnapshot) {
                  if (achievementSnapshot.connectionState == ConnectionState.waiting) {
                    return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
                  }
                  if (!achievementSnapshot.hasData || achievementSnapshot.data!.isEmpty) {
                    return const SliverToBoxAdapter(child: Center(child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('No achievements posted yet.'),
                    )));
                  }
                  final achievements = achievementSnapshot.data!;
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return AchievementCard(
                          achievement: achievements[index],
                          currentUserId: currentUserId ?? '',
                        );
                      },
                      childCount: achievements.length,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// A small helper widget to fetch and display the manager's name
class _ManagerInfo extends StatelessWidget {
  final String managerId;
  const _ManagerInfo({required this.managerId});

  @override
  Widget build(BuildContext context) {
    final userService = UserService();
    return FutureBuilder<UserModel?>(
      future: userService.getUserProfile(managerId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink(); // Don't show anything if manager not found
        }
        final manager = snapshot.data!;
        return Text(' (Head: ${manager.name})', style: const TextStyle(fontStyle: FontStyle.italic));
      },
    );
  }
}