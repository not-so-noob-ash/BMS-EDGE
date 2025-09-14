import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/user_model.dart';
import '../../data/services/user_service.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _departmentController;
  late final TextEditingController _postController;
  late final TextEditingController _clusterNameController;
  late final TextEditingController _additionalRolesController;
  DateTime? _selectedDate;
  bool _isLoading = false;

  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _departmentController = TextEditingController(text: widget.user.department);
    _postController = TextEditingController(text: widget.user.teacherPost);
    _clusterNameController = TextEditingController(text: widget.user.clusterName);
    _additionalRolesController = TextEditingController(text: widget.user.additionalRoles.join(', '));
    _selectedDate = widget.user.dateOfJoining?.toDate();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      setState(() => _isLoading = true);

      final additionalRoles = _additionalRolesController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

      // --- FIX: This call now matches the updated service method ---
      await _userService.updateUserProfile(
        uid: widget.user.uid,
        name: _nameController.text,
        department: _departmentController.text,
        teacherPost: _postController.text,
        dateOfJoining: _selectedDate!,
        clusterName: _clusterNameController.text,
        additionalRoles: additionalRoles,
      );

      setState(() => _isLoading = false);
      if (mounted) Navigator.of(context).pop();
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _departmentController.dispose();
    _postController.dispose();
    _clusterNameController.dispose();
    _additionalRolesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name'), validator: (v) => v!.isEmpty ? 'Required' : null),
                    const SizedBox(height: 16),
                    TextFormField(controller: _departmentController, decoration: const InputDecoration(labelText: 'Department'), validator: (v) => v!.isEmpty ? 'Required' : null),
                    const SizedBox(height: 16),
                    TextFormField(controller: _postController, decoration: const InputDecoration(labelText: 'Post (e.g., Professor)'), validator: (v) => v!.isEmpty ? 'Required' : null),
                    const SizedBox(height: 16),
                    TextFormField(controller: _clusterNameController, decoration: const InputDecoration(labelText: 'Cluster Name')),
                    const SizedBox(height: 16),
                    TextFormField(controller: _additionalRolesController, decoration: const InputDecoration(labelText: 'Additional Roles', hintText: 'e.g., Lab Head, Timetable Incharge')),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: Text(_selectedDate == null ? 'No date chosen' : 'Joined: ${DateFormat.yMMMd().format(_selectedDate!)}')),
                        TextButton(
                          onPressed: () async {
                            final pickedDate = await showDatePicker(context: context, initialDate: _selectedDate ?? DateTime.now(), firstDate: DateTime(1980), lastDate: DateTime.now());
                            if (pickedDate != null) setState(() => _selectedDate = pickedDate);
                          },
                          child: const Text('Select Date'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(onPressed: _saveProfile, child: const Text('Save Changes')),
                  ],
                ),
              ),
            ),
    );
  }
}