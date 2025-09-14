import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/services/leave_service.dart';

class ApplyForLeaveScreen extends StatefulWidget {
  const ApplyForLeaveScreen({super.key});

  @override
  State<ApplyForLeaveScreen> createState() => _ApplyForLeaveScreenState();
}

class _ApplyForLeaveScreenState extends State<ApplyForLeaveScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  // --- THIS IS THE FIX ---
  // This list now exactly matches the keys in the seeding function.
  final List<String> _leaveTypes = [
    'Privilege/Earned Leave',
    'Sick Leave',
    'Maternity Leave',
    'Paternity Leave',
    'Unpaid Leave'
    // Removed other types for now to match the seeder
  ];

  String? _selectedLeaveType;
  DateTimeRange? _selectedDateRange;
  bool _isLoading = false;
  final LeaveService _leaveService = LeaveService();

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLeaveType == null || _selectedDateRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a leave type and date range.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _leaveService.applyForLeave(
        leaveType: _selectedLeaveType!,
        startDate: _selectedDateRange!.start,
        endDate: _selectedDateRange!.end,
        reason: _reasonController.text,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit application: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Apply for Leave')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedLeaveType,
                      decoration: const InputDecoration(labelText: 'Leave Type', border: OutlineInputBorder()),
                      items: _leaveTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                      onChanged: (value) => setState(() => _selectedLeaveType = value),
                      validator: (value) => value == null ? 'Please select a leave type' : null,
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.date_range),
                      label: const Text('Select Dates'),
                      onPressed: _selectDateRange,
                    ),
                    if (_selectedDateRange != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'From: ${DateFormat.yMMMd().format(_selectedDateRange!.start)} \nTo: ${DateFormat.yMMMd().format(_selectedDateRange!.end)}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _reasonController,
                      decoration: const InputDecoration(labelText: 'Reason for Leave', border: OutlineInputBorder()),
                      maxLines: 4,
                      validator: (value) => value!.isEmpty ? 'Please provide a reason' : null,
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _submitApplication,
                      child: const Text('Submit Application'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}