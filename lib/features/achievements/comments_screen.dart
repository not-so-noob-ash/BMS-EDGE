import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/comment_model.dart';
import '../../data/services/achievement_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/sound_service.dart';

class CommentsScreen extends StatefulWidget {
  final String achievementId;
  const CommentsScreen({super.key, required this.achievementId});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final _commentController = TextEditingController();
  final AchievementService _achievementService = AchievementService();
  final SoundService _soundService = SoundService();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;
    _soundService.playCommentSound();
    setState(() => _isSending = true);

    await _achievementService.addComment(widget.achievementId, _commentController.text.trim());
    
    _commentController.clear();
    setState(() => _isSending = false);

    // Scroll to the bottom after a comment is added
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comments')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<CommentModel>>(
              stream: _achievementService.getComments(widget.achievementId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No comments yet. Be the first!'));
                }
                final comments = snapshot.data!;
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8.0),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: comment.commenterPhotoUrl.isNotEmpty 
                            ? NetworkImage(comment.commenterPhotoUrl) 
                            : null,
                          child: comment.commenterPhotoUrl.isEmpty 
                            ? const Icon(Icons.person) 
                            : null,
                        ),
                        title: Text(comment.commenterName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(comment.text),
                        trailing: Text(
                          DateFormat.yMMMd().format(comment.timestamp.toDate()),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Input field for new comments
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(width: 8),
                _isSending
                    ? const CircularProgressIndicator()
                    : IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _addComment,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}