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

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
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
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              GestureDetector(
                onTap: _openDetails,
                child: Hero(
                  tag: post.id,
                  child: PostImage(url: post.thumb),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.favorite,
                      color: post.isLiked ? Colors.red : Colors.grey,
                    ),
                    onPressed: () =>
                        ref.read(likeProvider).toggle(post),
                  ),
                  Text('${post.likes}'),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}