import 'package:flutter/material.dart';
import '../../data/services/event_service.dart';

class AddEventScreen extends StatefulWidget {
  const AddEventScreen({super.key});

  @override
  _AddEventScreenState createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  bool _isPublic = true; // Default to public
  bool _isLoading = false;

  final EventService _eventService = EventService();

  Future<void> _submitEvent() async {
    if (_titleController.text.isEmpty || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title and select a date.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _eventService.addEvent(
        title: _titleController.text,
        description: _descriptionController.text,
        eventDate: _selectedDate!,
        isPublic: _isPublic,
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add event: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Event')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Event Title')),
                  TextField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Description')),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Text(_selectedDate == null
                            ? 'No Date Chosen'
                            : 'Date: ${_selectedDate!.toLocal().toString().split(' ')[0]}'),
                      ),
                      TextButton(
                        onPressed: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2101),
                          );
                          if (pickedDate != null) {
                            setState(() => _selectedDate = pickedDate);
                          }
                        },
                        child: const Text('Choose Date'),
                      ),
                    ],
                  ),
                  SwitchListTile(
                    title: const Text('Make event public?'),
                    subtitle: const Text('Visible to all other faculty.'),
                    value: _isPublic,
                    onChanged: (bool value) => setState(() => _isPublic = value),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _submitEvent,
                    child: const Text('Add Event'),
                  ),
                ],
              ),
            ),
    );
  }
}