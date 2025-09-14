import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/leave_application_model.dart';
import '../../data/models/user_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/leave_service.dart';
import '../../data/services/user_service.dart';
import '../profile/profile_screen.dart';
import 'cluster_detail_screen.dart'; 

class TeamManagementScreen extends StatefulWidget {
  const TeamManagementScreen({super.key});

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final LeaveService _leaveService = LeaveService();
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  
  String _userRole = 'Faculty';
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _authService.currentUser;
    if (user != null) {
      final role = await _authService.getUserRole(user.uid);
      if (mounted) {
        setState(() {
          _userId = user.uid;
          _userRole = role ?? 'Faculty';
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- NEW: A function to show the dialog for appointing a head ---
  void _showAppointHeadDialog() {
    showDialog(
      context: context,
      // We pass the HOD's ID to the dialog so it knows who is making the appointment
      builder: (context) => _AppointHeadDialog(hodId: _userId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.approval_outlined), text: 'Approvals'),
            Tab(icon: Icon(Icons.group_outlined), text: 'My Team'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildApprovalsTab(),
          _buildMyTeamTab(),
        ],
      ),
      // --- NEW: A FloatingActionButton that is ONLY visible to HODs ---
      floatingActionButton: _userRole == 'HOD'
          ? FloatingActionButton.extended(
              onPressed: _showAppointHeadDialog,
              label: const Text('Appoint Head'),
              icon: const Icon(Icons.add_moderator),
            )
          : null, // If the user is not an HOD, no button is shown
    );
  }

  Widget _buildApprovalsTab() {
    // This widget's code is perfect, no changes needed
    return StreamBuilder<List<LeaveApplicationModel>>(
      stream: _leaveService.getPendingRequestsForManager(_userId, _userRole),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No pending approvals.'));
        }
        final requests = snapshot.data!;
        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                    title: Text('${request.applicantName} - ${request.leaveType}'),
                    subtitle: Text('Reason: ${request.reason}\nDates: ${DateFormat.yMMMd().format(request.startDate)} to ${DateFormat.yMMMd().format(request.endDate)}'),
                    isThreeLine: true,
                    trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                            IconButton(icon: const Icon(Icons.check_circle, color: Colors.green), onPressed: () => 
                                _leaveService.processLeaveRequest(applicationId: request.id, isApproved: true, currentUserRole: _userRole)
                            ),
                            IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () => 
                                _leaveService.processLeaveRequest(applicationId: request.id, isApproved: false, currentUserRole: _userRole, rejectionReason: "Rejected by manager.")
                            ),
                        ],
                    ),
                ),
            );
          },
        );
      },
    );
  }

  Widget _buildMyTeamTab() {
    // This widget's code is perfect, no changes needed
    return StreamBuilder<List<UserModel>>(
      stream: _userService.getUsersReportingTo(_userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No faculty are currently assigned to you.'));
        }
        final teamMembers = snapshot.data!;
        return ListView.builder(
          itemCount: teamMembers.length,
          itemBuilder: (context, index) {
            final member = teamMembers[index];
            return ListTile(
              leading: CircleAvatar(backgroundImage: member.photoUrl.isNotEmpty ? NetworkImage(member.photoUrl) : null, child: member.photoUrl.isEmpty ? const Icon(Icons.person) : null),
              title: Text(member.name),
              subtitle: Text(member.teacherPost),
              trailing: _userRole == 'HOD' && member.role == 'ClusterHead' ? const Icon(Icons.chevron_right) : null,
              onTap: () { if (_userRole == 'HOD' && member.role == 'ClusterHead') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ClusterDetailScreen(clusterHead: member)));
                } else {
                  // Otherwise, just go to the regular profile screen.
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(userId: member.uid)));
                }
              }
            );
          },
        );
      },
    );
  }
}

// --- NEW: A PRIVATE DIALOG WIDGET for HODs to appoint Cluster Heads ---

class _AppointHeadDialog extends StatefulWidget {
  final String hodId;
  const _AppointHeadDialog({required this.hodId});

  @override
  State<_AppointHeadDialog> createState() => _AppointHeadDialogState();
}

class _AppointHeadDialogState extends State<_AppointHeadDialog> {
  final _searchController = TextEditingController();
  final _clusterNameController = TextEditingController();
  final UserService _userService = UserService();
  UserModel? _selectedFaculty;

  void _appointHead() {
    if (_selectedFaculty == null || _clusterNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a faculty and enter a cluster name.')),
      );
      return;
    }

    _userService.appointClusterHead(
      facultyUid: _selectedFaculty!.uid,
      hodUid: widget.hodId,
      clusterName: _clusterNameController.text.trim(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_selectedFaculty!.name} has been appointed as a Cluster Head.'))
    );
    Navigator.of(context).pop();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _clusterNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Appoint Cluster Head'),
      scrollable: true,
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // This section either shows the selected faculty or the search bar
            if (_selectedFaculty != null)
              ListTile(
                leading: CircleAvatar(backgroundImage: NetworkImage(_selectedFaculty!.photoUrl)),
                title: Text(_selectedFaculty!.name),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _selectedFaculty = null),
                ),
              )
            else
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(hintText: 'Search for a faculty...'),
                onChanged: (value) => setState(() {}),
              ),

            // This section shows the search results
            if (_selectedFaculty == null && _searchController.text.isNotEmpty)
              SizedBox(
                height: 150, // Constrain the height of the results list
                child: StreamBuilder<List<UserModel>>(
                  stream: _userService.searchUsers(_searchController.text.trim()),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    // Filter out users who are already managers
                    final users = snapshot.data!.where((user) => user.role == 'Faculty').toList();
                    if (users.isEmpty) return const Center(child: Text('No matching faculty found.'));
                    
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return ListTile(
                          title: Text(user.name),
                          onTap: () => setState(() => _selectedFaculty = user),
                        );
                      },
                    );
                  },
                ),
              ),
            
            // Input for cluster name
            const SizedBox(height: 16),
            TextField(
              controller: _clusterNameController,
              decoration: const InputDecoration(labelText: 'Cluster Name'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(onPressed: _appointHead, child: const Text('Appoint')),
      ],
    );
  }
}