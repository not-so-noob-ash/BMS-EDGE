import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/leave_application_model.dart';
import '../../data/models/leave_balance_model.dart'; // <-- IMPORT THE NEW MODEL
import '../../data/services/auth_service.dart';
import '../../data/services/leave_service.dart';
import 'apply_for_leave_screen.dart';

class LeaveDashboardScreen extends StatefulWidget {
  const LeaveDashboardScreen({super.key});

  @override
  State<LeaveDashboardScreen> createState() => _LeaveDashboardScreenState();
}

class _LeaveDashboardScreenState extends State<LeaveDashboardScreen> {
  final LeaveService _leaveService = LeaveService();
  final String? _userId = AuthService().currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text("User not found.")));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Leave Management')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- SECTION 1: LIVE Leave Balance Summary ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text("Your Leave Balance (${DateTime.now().year})", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          ),
          
          // REPLACED the dummy grid with a real-time StreamBuilder
          _buildLiveBalanceGrid(),
          
          const Divider(height: 32),

          // --- SECTION 2: Application History (No changes needed here) ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text("Application History", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: StreamBuilder<List<LeaveApplicationModel>>(
              stream: _leaveService.getLeaveHistory(_userId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("You haven't applied for any leaves."));
                }
                final applications = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: applications.length,
                  itemBuilder: (context, index) {
                    final app = applications[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: _getStatusIcon(app.status),
                        title: Text(app.leaveType, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${DateFormat.yMMMd().format(app.startDate)} to ${DateFormat.yMMMd().format(app.endDate)}'),
                        trailing: Text(
                          app.status.toUpperCase(),
                          style: TextStyle(fontWeight: FontWeight.bold, color: _getStatusColor(app.status)),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ApplyForLeaveScreen()),
          );
        },
        label: const Text('Apply for Leave'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  // --- NEW WIDGET to build the grid from live data ---
  Widget _buildLiveBalanceGrid() {
    return StreamBuilder<List<LeaveBalanceModel>>(
      stream: _leaveService.getLeaveBalancesForUser(_userId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No leave balances found. Contact HR."));
        }
        final balances = snapshot.data!;
        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.2,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: balances.length,
          itemBuilder: (context, index) {
            final balance = balances[index];
            // Display Taken / Allocated
            return _balanceCard(balance.leaveType, "${balance.takenDays} / ${balance.allocatedDays}");
          },
        );
      },
    );
  }

  // A card widget for the balance grid (no changes needed)
  Widget _balanceCard(String title, String balance) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text(balance, style: const TextStyle(fontSize: 16, color: Colors.blueGrey)),
          ],
        ),
      ),
    );
  }

  // Helper methods for styling (no changes needed)
  Icon _getStatusIcon(String status) {
    switch (status) {
      case 'Approved': // Note: Status might be capitalized from HOD approval
      case 'approved':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'Rejected':
      case 'rejected':
        return const Icon(Icons.cancel, color: Colors.red);
      default:
        return const Icon(Icons.hourglass_top, color: Colors.orange);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approved':
      case 'approved':
        return Colors.green;
      case 'Rejected':
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
}