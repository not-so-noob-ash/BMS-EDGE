import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../../data/services/user_service.dart';

class ClusterDetailScreen extends StatelessWidget {
  final UserModel clusterHead;
  const ClusterDetailScreen({super.key, required this.clusterHead});

  @override
  Widget build(BuildContext context) {
    final UserService userService = UserService();

    return Scaffold(
      appBar: AppBar(
        title: Text('${clusterHead.clusterName} Cluster'),
      ),
      body: Column(
        children: [
          // Section 1: Members currently in the cluster
          _buildFacultyList(
            context: context,
            title: 'Assigned Faculty',
            stream: userService.getUsersReportingTo(clusterHead.uid),
            isAssigned: true,
            userService: userService,
            clusterHead: clusterHead,
          ),
          const Divider(thickness: 2),
          // Section 2: Faculty available to be added to the cluster
          _buildFacultyList(
            context: context,
            title: 'Unassigned Faculty',
            stream: userService.getUnassignedFaculty(),
            isAssigned: false,
            userService: userService,
            clusterHead: clusterHead,
          ),
        ],
      ),
    );
  }

  Widget _buildFacultyList({
    required BuildContext context,
    required String title,
    required Stream<List<UserModel>> stream,
    required bool isAssigned,
    required UserService userService,
    required UserModel clusterHead,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text(isAssigned ? 'No faculty in this cluster.' : 'No unassigned faculty available.'));
                }
                final users = snapshot.data!;
                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
                        child: user.photoUrl.isEmpty ? const Icon(Icons.person) : null,
                      ),
                      title: Text(user.name),
                      subtitle: Text(user.teacherPost),
                      trailing: IconButton(
                        icon: Icon(
                          isAssigned ? Icons.remove_circle : Icons.add_circle,
                          color: isAssigned ? Colors.red : Colors.green,
                        ),
                        tooltip: isAssigned ? 'Remove from cluster' : 'Add to cluster',
                        onPressed: () {
                          if (isAssigned) {
                            userService.unassignFacultyFromCluster(user.uid);
                          } else {
                            userService.assignFacultyToClusterHead(
                              facultyUid: user.uid,
                              clusterHeadUid: clusterHead.uid,
                              clusterName: clusterHead.clusterName,
                            );
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}