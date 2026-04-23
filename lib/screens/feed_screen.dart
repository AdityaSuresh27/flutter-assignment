import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/feed_provider.dart';
import '../providers/like_provider.dart';
import '../widgets/post_card.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final controller = ScrollController();
  bool _autoLoadScheduled = false;

  @override
  void initState() {
    super.initState();

    ref.listenManual<String?>(likeErrorMessageProvider, (previous, next) {
      if (next == null || !mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(next)));
      ref.read(likeErrorMessageProvider.notifier).state = null;
    });

    Future.microtask(() {
      ref.read(feedProvider.notifier).loadInitial();
    });

    controller.addListener(() {
      if (!controller.hasClients) return;
      if (controller.position.pixels >
          controller.position.maxScrollExtent - 300) {
        ref.read(feedProvider.notifier).loadMore();
      }
    });
  }

  void _scheduleAutoLoadIfNeeded() {
    if (_autoLoadScheduled) return;
    _autoLoadScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoLoadScheduled = false;
      if (!mounted || !controller.hasClients) return;

      final notifier = ref.read(feedProvider.notifier);
      final feed = ref.read(feedProvider);
      final notScrollableYet =
          controller.position.maxScrollExtent <=
              controller.position.viewportDimension * 0.05;

      if (notScrollableYet && feed.hasMore && !feed.loading) {
        notifier.loadMore();
      }
    });
  }

  Future<void> _onRefresh() async {
    ref.read(likeProvider).clearPendingSync();
    await ref.read(feedProvider.notifier).loadInitial();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(feedProvider);
    final posts = feed.posts;
    final showEmptyState = posts.isEmpty && !feed.loading;
    _scheduleAutoLoadIfNeeded();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 14,
        title: const Row(
          children: [
            Icon(Icons.bubble_chart_rounded, color: Color(0xFF0F766E)),
            SizedBox(width: 8),
            Text(
              'Pulse',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
            ),
          ],
        ),
        actions: const [
          Icon(Icons.search_rounded),
          SizedBox(width: 14),
          Icon(Icons.chat_bubble_outline_rounded),
          SizedBox(width: 16),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF0FDFA), Color(0xFFF8FAFC)],
            ),
          ),
          child: ListView.builder(
            controller: controller,
            cacheExtent: 1200,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount:
                showEmptyState
                    ? 3
                    : posts.length + 2 + (feed.loading ? 1 : 0),
            itemBuilder: (_, i) {
              if (i == 0) {
                return const _ComposerPrompt();
              }

              if (i == 1) {
                return _StoriesRow(posts: posts);
              }

              if (showEmptyState && i == 2) {
                return const Padding(
                  padding: EdgeInsets.only(top: 84),
                  child: Center(
                    child: Text(
                      'No posts yet. Pull down to refresh.',
                      style: TextStyle(
                        color: Color(0xFF334155),
                        fontSize: 15,
                      ),
                    ),
                  ),
                );
              }

              final postIndex = i - 2;

              if (postIndex == posts.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              return PostCard(post: posts[postIndex]);
            },
          ),
        ),
      ),
    );
  }
}

class _ComposerPrompt extends StatelessWidget {
  const _ComposerPrompt();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Row(
        children: [
          CircleAvatar(radius: 16, child: Icon(Icons.person_outline_rounded)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "What's new today?",
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          Icon(Icons.image_outlined, color: Color(0xFF0F766E)),
        ],
      ),
    );
  }
}

class _StoriesRow extends StatelessWidget {
  final List<dynamic> posts;

  const _StoriesRow({required this.posts});

  @override
  Widget build(BuildContext context) {
    final count = posts.length < 8 ? posts.length : 8;
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
        itemBuilder: (_, i) {
          if (i == 0) {
            return const _StoryAvatar(
              label: 'Your story',
              icon: Icons.add_rounded,
              accent: Color(0xFF0EA5E9),
            );
          }

          final id = posts[i - 1].id as String;
          final short = id.length > 4 ? id.substring(0, 4) : id;
          const accents = [
            Color(0xFFEF4444),
            Color(0xFFF59E0B),
            Color(0xFF22C55E),
            Color(0xFF3B82F6),
            Color(0xFFA855F7),
          ];

          return _StoryAvatar(
            label: 'u_$short',
            icon: Icons.person_rounded,
            accent: accents[id.hashCode.abs() % accents.length],
          );
        },
        separatorBuilder: (_, index) => const SizedBox(width: 10),
        itemCount: count + 1,
      ),
    );
  }
}

class _StoryAvatar extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accent;

  const _StoryAvatar({
    required this.label,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 68,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [accent, accent.withValues(alpha: 0.55)],
              ),
            ),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white,
              child: Icon(icon, color: accent),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}