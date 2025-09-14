import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import '../../core/widgets/responsive_center.dart'; // <-- 1. IMPORT THE NEW WIDGET
import '../../data/models/achievement_model.dart';
import '../../data/models/event_model.dart';
import '../../data/services/achievement_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/event_service.dart';
import '../chatbot/chat_screen.dart';
import '../messages/messages_screen.dart';
import '../profile/profile_screen.dart';
import 'package:async/async.dart';

import 'faculty_dashboard.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final eventService = EventService();
    final achievementService = AchievementService();
    final user = authService.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Please log in.")));
    }

    final combinedStream = StreamZip([
      eventService.getPublicEventsStream(),
      achievementService.getAchievementsStream(),
    ]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Feed'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'Messages',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MessagesScreen()));
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProfileScreen(userId: user.uid)),
                );
              },
              customBorder: const CircleBorder(),
              child: CircleAvatar(
                radius: 18,
                backgroundImage: user.photoURL != null && user.photoURL!.isNotEmpty
                    ? NetworkImage(user.photoURL!)
                    : null,
                child: user.photoURL == null || user.photoURL!.isEmpty
                    ? const Icon(Icons.person, size: 18)
                    : null,
              ),
            ),
          ),
        ],
      ),
      // --- 2. WRAP THE BODY WITH RESPONSIVECENTER ---
      body: ResponsiveCenter(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Welcome back, ${user.displayName ?? 'Faculty'}!",
                              style: Theme.of(context).textTheme.titleLarge,
                              overflow: TextOverflow.ellipsis),
                          Text(user.email ?? ""),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: Divider()),
            StreamBuilder<List<dynamic>>(
              stream: combinedStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: Text('No activity yet.')),
                  );
                }

                final List<EventModel> events = snapshot.data![0];
                final List<AchievementModel> achievements = snapshot.data![1];

                List<Map<String, dynamic>> feedItems = [];
                feedItems.addAll(events.map((e) =>
                    {'type': 'event', 'data': e, 'timestamp': e.eventDate}));
                feedItems.addAll(achievements.map((a) => {
                      'type': 'achievement',
                      'data': a,
                      'timestamp': a.createdAt.toDate()
                    }));

                feedItems.sort((a, b) => (b['timestamp'] as DateTime)
                    .compareTo(a['timestamp'] as DateTime));
                
                if (feedItems.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: Text('No activity in the feed.')),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = feedItems[index];
                      if (item['type'] == 'event') {
                        return EventCard(event: item['data']);
                      } else {
                        return AchievementCard(
                          achievement: item['data'],
                          currentUserId: user.uid,
                        );
                      }
                    },
                    childCount: feedItems.length,
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen()));
        },
        tooltip: 'AI Quick Support',
        child: const Icon(Icons.support_agent),
      ),
    );
  }
}