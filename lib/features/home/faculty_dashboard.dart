import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

// Import all necessary models, services, and screens
import '../../data/models/achievement_model.dart';
import '../../data/models/event_model.dart';
import '../../data/services/achievement_service.dart';
import '../../data/services/sound_service.dart';
import '../achievements/comments_screen.dart';
import '../profile/profile_screen.dart';

class FacultyDashboard extends StatefulWidget {
  const FacultyDashboard({super.key});
  @override
  State<FacultyDashboard> createState() => _FacultyDashboardState();
}

class _FacultyDashboardState extends State<FacultyDashboard> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
        body: Center(child: Text("This is a placeholder for card widgets.")));
  }
}

class EventCard extends StatelessWidget {
  final EventModel event;
  const EventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.event)),
        title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('By: ${event.creatorName}\nScheduled for: ${DateFormat.yMMMd().format(event.eventDate)}'),
        isThreeLine: true,
      ),
    );
  }
}

// --- ACHIEVEMENT CARD: FINAL VERSION WITH ALL FEATURES ---
class AchievementCard extends StatefulWidget {
  final AchievementModel achievement;
  final String currentUserId;
  const AchievementCard({
    super.key,
    required this.achievement,
    required this.currentUserId,
  });

  @override
  State<AchievementCard> createState() => _AchievementCardState();
}

class _AchievementCardState extends State<AchievementCard> {
  // Local state variables for optimistic UI updates
  late Map<String, String> _reactions;
  late int _commentCount;
  late int _repostCount;
  late bool _isRepostedByMe;

  final AchievementService _achievementService = AchievementService();
  final SoundService _soundService = SoundService();
  OverlayEntry? _overlayEntry;

  static const Map<String, String> availableReactions = {
    'like': '👍', 'celebrate': '🎉', 'love': '❤️', 'insightful': '💡', 'funny': '😂',
  };

  @override
  void initState() {
    super.initState();
    _reactions = Map.from(widget.achievement.reactions);
    _commentCount = widget.achievement.commentCount;
    _repostCount = widget.achievement.repostCount;
    _isRepostedByMe = widget.achievement.repostedBy.containsKey(widget.currentUserId);
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }
  
  // --- REAL-TIME UI HANDLERS WITH SOUND ---

  void _handleReaction(String reactionType) {
    _soundService.playReactSound();
    final currentReaction = _reactions[widget.currentUserId];
    setState(() {
      if (currentReaction == reactionType) {
        _reactions.remove(widget.currentUserId);
      } else {
        _reactions[widget.currentUserId] = reactionType;
      }
    });
    _achievementService.setReaction(
      achievementId: widget.achievement.id,
      newReactionType: reactionType,
    );
  }

  void _handleRepost() {
    _soundService.playRepostSound();
    setState(() {
      if (_isRepostedByMe) {
        _repostCount--;
        _isRepostedByMe = false;
      } else {
        _repostCount++;
        _isRepostedByMe = true;
      }
    });
    _achievementService.toggleRepost(widget.achievement);
  }
  
  // --- HORIZONTAL REACTION OVERLAY LOGIC ---

  void _showReactionOverlay(BuildContext context, GlobalKey buttonKey) {
    _overlayEntry?.remove();
    _overlayEntry = null;
    
    final RenderBox renderBox = buttonKey.currentContext!.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: position.dy - size.height - 12,
        left: position.dx - (size.width / 2),
        child: Material(
          elevation: 4.0,
          borderRadius: BorderRadius.circular(24.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: availableReactions.entries.map((entry) {
                return IconButton(
                  icon: Text(entry.value, style: const TextStyle(fontSize: 24)),
                  onPressed: () {
                    _handleReaction(entry.key);
                    _overlayEntry?.remove();
                    _overlayEntry = null;
                  },
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  // --- MAIN BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    final currentUserReaction = _reactions[widget.currentUserId];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 12),
            if (widget.achievement.description.isNotEmpty) _buildDescription(context),
            const SizedBox(height: 12),
            if (widget.achievement.fileUrls.isNotEmpty) _buildAttachments(context),
            _buildSocialCounts(context),
            const Divider(height: 1),
            _buildActionBar(context, currentUserReaction),
          ],
        ),
      ),
    );
  }
  
  // --- HELPER WIDGETS (NOW INSIDE THE STATE CLASS) ---

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(child: Icon(Icons.person)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.achievement.creatorName, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(DateFormat.yMMMd().format(widget.achievement.createdAt.toDate()), style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(BuildContext context) {
    List<TextSpan> spans = [];
    widget.achievement.description.splitMapJoin(
      RegExp(r'(@[a-zA-Z0-9_]+)'),
      onMatch: (m) {
        final mention = m.group(0)!;
        final username = mention.substring(1);
        String? userId;
        widget.achievement.taggedUsers.forEach((id, name) {
          if (name.replaceAll(' ', '') == username) {
            userId = id;
          }
        });

        if (userId != null) {
          spans.add(TextSpan(
            text: mention,
            style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
            recognizer: TapGestureRecognizer()..onTap = () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(userId: userId!)));
            },
          ));
        } else {
          spans.add(TextSpan(text: mention));
        }
        return '';
      },
      onNonMatch: (n) {
        spans.add(TextSpan(text: n));
        return '';
      },
    );
    return RichText(text: TextSpan(children: spans, style: DefaultTextStyle.of(context).style.copyWith(fontSize: 15)));
  }

  Widget _buildAttachments(BuildContext context) {
    final imageFiles = widget.achievement.fileUrls.where((url) => _isImageUrl(url)).toList();
    if (imageFiles.isEmpty) return const SizedBox.shrink();

    if (imageFiles.length > 1) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: imageFiles.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    imageFiles[index],
                    width: 200,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, p) => p == null ? child : const Center(child: CircularProgressIndicator()),
                    errorBuilder: (context, e, s) => const Icon(Icons.broken_image),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Image.network(
          imageFiles.first,
          width: double.infinity,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, p) => p == null ? child : const Center(child: CircularProgressIndicator()),
          errorBuilder: (context, e, s) => const Icon(Icons.broken_image, size: 40, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildSocialCounts(BuildContext context) {
    final reactionCounts = <String, int>{};
    _reactions.forEach((_, type) => reactionCounts[type] = (reactionCounts[type] ?? 0) + 1);
    final sortedReactions = reactionCounts.entries.toList()..sort((a,b) => b.value.compareTo(a.value));

    if (_reactions.isEmpty && _commentCount == 0 && _repostCount == 0) {
      return const SizedBox(height: 8);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          if (_reactions.isNotEmpty) ...[
            ...sortedReactions.take(3).map((e) => Text(availableReactions[e.key]!, style: const TextStyle(fontSize: 14))),
            const SizedBox(width: 4),
            Text('${_reactions.length}', style: Theme.of(context).textTheme.bodySmall),
          ],
          const Spacer(),
          if (_commentCount > 0)
            Text('$_commentCount Comments', style: Theme.of(context).textTheme.bodySmall),
          if (_commentCount > 0 && _repostCount > 0)
            Text(' • ', style: Theme.of(context).textTheme.bodySmall),
          if (_repostCount > 0)
            Text('$_repostCount Reposts', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildActionBar(BuildContext context, String? currentUserReaction) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildReactionButton(context, currentUserReaction),
        _actionButton(context, 'Comment', Icons.chat_bubble_outline, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => CommentsScreen(achievementId: widget.achievement.id)));
        }),
        _actionButton(
          context,
          'Repost',
          _isRepostedByMe ? Icons.repeat_on_sharp : Icons.repeat,
          _handleRepost,
          color: _isRepostedByMe ? Theme.of(context).primaryColor : Colors.grey[700],
        ),
      ],
    );
  }

  Widget _buildReactionButton(BuildContext context, String? currentUserReaction) {
    final key = GlobalKey();
    return TextButton.icon(
      key: key,
      icon: Text(
        currentUserReaction != null ? availableReactions[currentUserReaction]! : '👍',
        style: const TextStyle(fontSize: 20),
      ),
      label: Text(
        currentUserReaction != null ? currentUserReaction.capitalize() : 'React',
        style: TextStyle(
          color: currentUserReaction != null ? Theme.of(context).primaryColor : Colors.grey[700],
          fontWeight: currentUserReaction != null ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onPressed: () => _handleReaction('like'),
      onLongPress: () {
        _showReactionOverlay(context, key);
      },
    );
  }

  Widget _actionButton(BuildContext context, String label, IconData icon, VoidCallback onPressed, {Color? color}) {
    return TextButton.icon(
      icon: Icon(icon, color: color ?? Colors.grey[700], size: 20),
      label: Text(label, style: TextStyle(color: color ?? Colors.grey[700])),
      onPressed: onPressed,
    );
  }
  
  bool _isImageUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path.toLowerCase();
      return path.endsWith('.jpg') || path.endsWith('.jpeg') || path.endsWith('.png') || path.endsWith('.gif') || path.endsWith('.webp');
    } catch (_) { return false; }
  }
}

extension StringExtension on String {
    String capitalize() {
      if (isEmpty) return this;
      return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
    }
}