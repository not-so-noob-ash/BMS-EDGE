import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import '../../data/models/user_model.dart';
import '../../data/services/user_service.dart';
import '../profile/profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final UserService _userService = UserService();
  
  // A StreamController is a more standard way to manage text changes for RxDart
  final _textChangeStreamController = StreamController<String>();
  late final Stream<Map<String, List<UserModel>>> _combinedStream;

  @override
  void initState() {
    super.initState();

    // Listen to the text controller and add changes to our stream
    _searchController.addListener(() {
      _textChangeStreamController.add(_searchController.text);
    });

    // --- THIS IS THE UPGRADED LOGIC ---
    _combinedStream = _textChangeStreamController.stream
      // 1. Debounce: Wait for the user to stop typing for 300ms
      .debounceTime(const Duration(milliseconds: 300))
      // 2. Distinct: Only proceed if the text has actually changed
      .distinct()
      // 3. switchMap: Cancel previous searches and start a new one with the latest query
      .switchMap((query) {
        final cleanQuery = query.trim().toLowerCase(); // 4. Make query lowercase
        if (cleanQuery.isEmpty) {
          return Stream.value({'nameMatches': [], 'roleMatches': []});
        }
        // Rx.combineLatest2 listens to both streams and emits a new combined result
        return Rx.combineLatest2(
          _userService.searchUsers(cleanQuery), // Pass lowercase query
          _userService.searchUsersByRole(cleanQuery), // Pass lowercase query
          (List<UserModel> nameResults, List<UserModel> roleResults) => {
            'nameMatches': nameResults,
            'roleMatches': roleResults,
          },
        );
      });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _textChangeStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search by name or role...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<Map<String, List<UserModel>>>(
        stream: _combinedStream,
        builder: (context, snapshot) {
          if (_searchController.text.trim().isEmpty) {
            return const Center(
              child: Text('Enter a name or role to begin searching.'),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting && _searchController.text.trim().isNotEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No results found.'));
          }

          final nameMatches = snapshot.data!['nameMatches'] ?? [];
          final roleMatches = snapshot.data!['roleMatches'] ?? [];

          // De-duplicate results to ensure a user only appears once
          final Map<String, UserModel> uniqueUsers = {};
          for (var user in roleMatches) {
            uniqueUsers[user.uid] = user;
          }
          for (var user in nameMatches) {
            uniqueUsers[user.uid] = user;
          }
          
          if (uniqueUsers.isEmpty) {
            return Center(
              child: Text('No faculty found for "${_searchController.text.trim()}".'),
            );
          }
          
          // We can create separate lists again for displaying with headers
          final finalRoleMatches = uniqueUsers.values.where((user) => roleMatches.any((roleUser) => roleUser.uid == user.uid)).toList();
          final finalNameMatches = uniqueUsers.values.where((user) => nameMatches.any((nameUser) => nameUser.uid == user.uid)).toList();

          return ListView(
            children: [
              if (finalRoleMatches.isNotEmpty) ...[
                _buildSectionHeader('Matching Roles'),
                ...finalRoleMatches.map((user) => _buildUserTile(user)),
              ],
              if (finalNameMatches.isNotEmpty) ...[
                _buildSectionHeader('Matching Names'),
                ...finalNameMatches.map((user) => _buildUserTile(user)),
              ],
            ],
          );
        },
      ),
    );
  }

  // Helper widgets (no changes needed)
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.grey[600],
            ),
      ),
    );
  }

  Widget _buildUserTile(UserModel user) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
        child: user.photoUrl.isEmpty ? const Icon(Icons.person) : null,
      ),
      title: Text(user.name),
      subtitle: Text(
        '${user.teacherPost} - ${user.clusterName.isNotEmpty ? user.clusterName : user.department}',
      ),
      onTap: () {
        FocusScope.of(context).unfocus();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProfileScreen(userId: user.uid)),
        );
      },
    );
  }
}