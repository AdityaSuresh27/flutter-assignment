import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post.dart';
import '../providers/like_provider.dart';
import '../screens/detail_screen.dart';
import 'post_image.dart';

class PostCard extends ConsumerStatefulWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> {
  bool _navigating = false;

  String _usernameFromId(String id) {
    final short = id.length > 6 ? id.substring(0, 6) : id;
    return 'user_$short';
  }

  String _timeAgoFromId(String id) {
    final mins = (id.hashCode.abs() % 56) + 3;
    if (mins < 60) return '${mins}m';
    final hours = mins ~/ 60;
    return '${hours}h';
  }

  Color _avatarColor(String id) {
    const palette = [
      Color(0xFF0EA5E9),
      Color(0xFF14B8A6),
      Color(0xFFF97316),
      Color(0xFFEF4444),
      Color(0xFF6366F1),
      Color(0xFF84CC16),
    ];
    return palette[id.hashCode.abs() % palette.length];
  }

  Future<void> _openDetails() async {
    if (_navigating || !mounted) return;
    _navigating = true;
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DetailScreen(post: widget.post),
        ),
      );
    } finally {
      if (mounted) {
        _navigating = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final username = _usernameFromId(post.id);
    final timeAgo = _timeAgoFromId(post.id);
    final avatarColor = _avatarColor(post.id);

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              blurRadius: 44,
              spreadRadius: 10,
              offset: const Offset(0, 12),
              color: Colors.black.withValues(alpha: 0.3),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 10, 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 17,
                      backgroundColor: avatarColor,
                      child: Text(
                        username[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            username,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                          Text(
                            timeAgo,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.more_horiz_rounded),
                      color: const Color(0xFF64748B),
                    )
                  ],
                ),
              ),
              GestureDetector(
                onTap: _openDetails,
                child: Hero(
                  tag: post.id,
                  child: PostImage(url: post.thumb),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 8, 10, 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        post.isLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color:
                            post.isLiked ? const Color(0xFFDC2626) : null,
                      ),
                      onPressed: () => ref.read(likeProvider).toggle(post),
                    ),
                    Text(
                      '${post.likes}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.mode_comment_outlined),
                    ),
                    const SizedBox(width: 2),
                    const Text('12'),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.send_outlined),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.bookmark_border_rounded),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}