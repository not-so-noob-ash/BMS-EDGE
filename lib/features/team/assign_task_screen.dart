import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../../data/services/task_service.dart';
import '../../data/services/user_service.dart';

class AssignTaskScreen extends StatefulWidget {
  const AssignTaskScreen({super.key});
  @override
  State<AssignTaskScreen> createState() => _AssignTaskScreenState();
}

class _AssignTaskScreenState extends State<AssignTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _detailsController = TextEditingController();
  final Map<String, String> _selectedUsers = {}; // Key: UID, Value: Name
  DateTime? _selectedDate;
  bool _isLoading = false;
  final TaskService _taskService = TaskService();

  void _showUserSelection() async {
    final results = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => const _UserSelectionDialog(),
    );
    if (results != null) {
      setState(() {
        _selectedUsers.addAll(results);
      });
    }
  }

  Future<void> _submitTask() async {
    if (!_formKey.currentState!.validate() || _selectedUsers.isEmpty || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and select at least one faculty.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    await _taskService.createTask(
      title: _titleController.text,
      details: _detailsController.text,
      date: _selectedDate!,
      startTime: "09:00", // Default start time
      durationMinutes: 60, // Default duration
      assignedToIds: _selectedUsers.keys.toList(),
    );
    setState(() => _isLoading = false);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assign a New Task')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: 'Task Title'), validator: (v) => v!.isEmpty ? 'Required' : null),
                  const SizedBox(height: 16),
                  TextFormField(controller: _detailsController, decoration: const InputDecoration(labelText: 'Details'), maxLines: 4),
                  const SizedBox(height: 16),
                  TextButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_selectedDate == null ? 'Select Deadline Date' : 'Deadline: ${DateFormat.yMMMd().format(_selectedDate!)}'),
                      onPressed: () async {
                          final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                          if (date != null) setState(() => _selectedDate = date);
                      },
                  ),
                  const Divider(height: 24),
                  Text("Assigned To:", style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    children: _selectedUsers.entries.map((e) => Chip(
                        label: Text(e.value),
                        onDeleted: () => setState(() => _selectedUsers.remove(e.key)),
                    )).toList(),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Select Faculty'),
                    onPressed: _showUserSelection,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _submitTask,
                    child: const Text('Assign Task'),
                  )
                ],
              ),
            ),
          ),
    );
  }
}

class _UserSelectionDialog extends StatefulWidget {
  const _UserSelectionDialog();
  @override
  State<_UserSelectionDialog> createState() => _UserSelectionDialogState();
}

class _UserSelectionDialogState extends State<_UserSelectionDialog> {
  final _searchController = TextEditingController();
  final UserService _userService = UserService();
  final Map<String, String> _tempSelectedUsers = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Faculty'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(hintText: 'Search by name...'),
              onChanged: (value) => setState(() {}),
            ),
            Expanded(
              child: StreamBuilder<List<UserModel>>(
                stream: _userService.searchUsers(_searchController.text.trim()),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final users = snapshot.data!;
                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final isSelected = _tempSelectedUsers.containsKey(user.uid);
                      return CheckboxListTile(
                        title: Text(user.name),
                        value: isSelected,
                        onChanged: (selected) {
                          setState(() {
                            if (selected!) {
                              _tempSelectedUsers[user.uid] = user.name;
                            } else {
                              _tempSelectedUsers.remove(user.uid);
                            }
                          });
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
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.of(context).pop(_tempSelectedUsers), child: const Text('Add Selected')),
      ],
    );
  }
}