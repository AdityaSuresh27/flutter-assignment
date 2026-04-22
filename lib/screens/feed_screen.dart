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
        title: const Text(
          'Performance Feed',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
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
                showEmptyState ? 1 : posts.length + (feed.loading ? 1 : 0),
            itemBuilder: (_, i) {
              if (showEmptyState) {
                return const Padding(
                  padding: EdgeInsets.only(top: 120),
                  child: Center(
                    child: Text(
                      'No posts yet. Pull to refresh.',
                      style: TextStyle(
                        color: Color(0xFF334155),
                        fontSize: 15,
                      ),
                    ),
                  ),
                );
              }

              if (i == posts.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return PostCard(post: posts[i]);
            },
          ),
        ),
      ),
    );
  }
}