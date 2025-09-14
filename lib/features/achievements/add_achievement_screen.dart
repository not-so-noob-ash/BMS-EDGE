import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../data/models/user_model.dart';
import '../../data/services/achievement_service.dart';
import '../../data/services/user_service.dart';

class AddAchievementScreen extends StatefulWidget {
  const AddAchievementScreen({super.key});

  @override
  State<AddAchievementScreen> createState() => _AddAchievementScreenState();
}

class _AddAchievementScreenState extends State<AddAchievementScreen> {
  final _descriptionController = TextEditingController();
  List<File> _pickedFiles = [];
  Map<String, String> _taggedUsers = {}; // Key: UID, Value: Name
  bool _isLoading = false;
  final AchievementService _achievementService = AchievementService();

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      setState(() {
        _pickedFiles = result.paths.map((path) => File(path!)).toList();
      });
    }
  }

  // --- NEW: Function to show the user search dialog for tagging ---
  Future<void> _showTagUserDialog() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const _TagUserDialog(),
    );
    if (result != null) {
      setState(() {
        _taggedUsers.addAll(result);
      });
    }
  }

  Future<void> _submitAchievement() async {
    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a description.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    // Updated call to include tagged users
    final success = await _achievementService.postAchievement(
      description: _descriptionController.text,
      files: _pickedFiles,
      taggedUsers: _taggedUsers, // <-- Pass the tagged users map
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.of(context).pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to post achievement.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post an Achievement')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'e.g., Published a new paper... Tag faculty with @Name',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 12),
                  // --- NEW: Buttons for tagging and attaching files ---
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _pickFiles,
                        icon: const Icon(Icons.attach_file),
                        label: const Text('Attach File'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: _showTagUserDialog,
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('Tag Faculty'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // --- NEW: Display for tagged users ---
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: _taggedUsers.entries.map((entry) {
                      return Chip(
                        label: Text(entry.value),
                        onDeleted: () {
                          setState(() {
                            _taggedUsers.remove(entry.key);
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const Divider(),
                  // Display for picked files
                  Expanded(
                    child: _pickedFiles.isEmpty
                        ? const Center(child: Text('No files selected.'))
                        : ListView.builder(
                            itemCount: _pickedFiles.length,
                            itemBuilder: (context, index) {
                              final file = _pickedFiles[index];
                              return Card(
                                child: ListTile(
                                  leading: const Icon(Icons.insert_drive_file),
                                  title: Text(file.path.split('/').last),
                                ),
                              );
                            },
                          ),
                  ),
                  ElevatedButton(
                    onPressed: _submitAchievement,
                    child: const Text('Post'),
                  ),
                ],
              ),
            ),
    );
  }
}

// --- NEW: A private dialog widget for searching and selecting users to tag ---
class _TagUserDialog extends StatefulWidget {
  const _TagUserDialog();

  @override
  State<_TagUserDialog> createState() => _TagUserDialogState();
}

class _TagUserDialogState extends State<_TagUserDialog> {
  final _searchController = TextEditingController();
  final UserService _userService = UserService();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tag Faculty'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() {}),
            ),
            Expanded(
              child: StreamBuilder<List<UserModel>>(
                stream: _userService.searchUsers(_searchController.text.trim()),
                builder: (context, snapshot) {
                  if (_searchController.text.trim().isEmpty) {
                    return const Center(child: Text('Start typing to search.'));
                  }
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final users = snapshot.data!;
                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return ListTile(
                        title: Text(user.name),
                        onTap: () {
                          // Return the selected user's ID and name
                          Navigator.of(context).pop({user.uid: user.name});
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}