import 'package:flutter/material.dart';
// Import all your main screens, INCLUDING the CalendarScreen
import '../../data/services/auth_service.dart';
import '../profile/profile_screen.dart';
import '../search/search_screen.dart';
import '../team/team_management_screen.dart';
import '../tasks/assign_task_screen.dart';
import '../calendar/calendar_screen.dart'; // <-- 1. IMPORT THE CALENDAR SCREEN
import 'feed_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});
  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  List<Widget> _pages = [];
  List<BottomNavigationBarItem> _navBarItems = [];
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _fetchUserRoleAndBuildUI();
  }

  Future<void> _fetchUserRoleAndBuildUI() async {
    final authService = AuthService();
    final user = authService.currentUser;
    if (user == null) return;

    final role = await authService.getUserRole(user.uid);
    final currentUserId = user.uid;

    if (!mounted) return;

    // --- 2. ADD CALENDAR TO THE UI FOR ALL ROLES ---
    if (role == 'HOD' || role == 'ClusterHead') {
      setState(() {
        _userRole = role;
        _pages = [
          const FeedScreen(),
          const SearchScreen(),
          const CalendarScreen(), // <-- ADDED CALENDAR SCREEN
          const TeamManagementScreen(),
          ProfileScreen(userId: currentUserId),
        ];
        _navBarItems = [
          const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          const BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), label: 'Calendar'), // <-- ADDED CALENDAR TAB
          const BottomNavigationBarItem(icon: Icon(Icons.group_outlined), label: 'Team'),
          const BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ];
      });
    } else { // Faculty
      setState(() {
        _userRole = 'Faculty';
        _pages = [
          const FeedScreen(),
          const SearchScreen(),
          const CalendarScreen(), // <-- ADDED CALENDAR SCREEN
          ProfileScreen(userId: currentUserId),
        ];
        _navBarItems = [
          const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          const BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), label: 'Calendar'), // <-- ADDED CALENDAR TAB
          const BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ];
      });
    }
  }

  void _onTabTapped(int index) {
    setState(() { _selectedIndex = index; });
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(context: context, builder: (ctx) {
      return Wrap(children: [
        ListTile(
          leading: const Icon(Icons.emoji_events), title: const Text('Post Achievement'),
          onTap: () { Navigator.pop(ctx); /* Navigate to AddAchievementScreen */ },
        ),
        if (_userRole == 'HOD' || _userRole == 'ClusterHead' || _userRole == 'Faculty')
          ListTile(
            leading: const Icon(Icons.assignment_late_outlined), title: const Text('Assign Task'),
            onTap: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AssignTaskScreen()));
            },
          ),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_pages.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Using IndexedStack to preserve the state of each page when switching tabs
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        items: _navBarItems,
        type: BottomNavigationBarType.fixed, // Important for more than 3 items
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
      ),
      // The FAB is no longer docked since we have up to 5 items, which is standard practice
      floatingActionButton: (_userRole != null) ? FloatingActionButton(
        onPressed: () => _showAddOptions(context),
        child: const Icon(Icons.add),
      ) : null,
    );
  }
}