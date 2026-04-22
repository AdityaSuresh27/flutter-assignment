import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../models/post.dart';
import '../repositories/feed_repository.dart';

final feedProvider =
    StateNotifierProvider<FeedNotifier, FeedState>((ref) {
  return FeedNotifier();
});

class FeedState {
  final List<Post> posts;
  final int currentPage;
  final bool loading;
  final bool hasMore;

  const FeedState({
    required this.posts,
    required this.currentPage,
    required this.loading,
    required this.hasMore,
  });

  const FeedState.initial()
      : posts = const [],
        currentPage = 0,
        loading = false,
        hasMore = true;

  FeedState copyWith({
    List<Post>? posts,
    int? currentPage,
    bool? loading,
    bool? hasMore,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      currentPage: currentPage ?? this.currentPage,
      loading: loading ?? this.loading,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class FeedNotifier extends StateNotifier<FeedState> {
  FeedNotifier() : super(const FeedState.initial());

  final repo = FeedRepository();
  static const int _pageSize = 10;
  int _generation = 0;

  Future<void> loadInitial() async {
    final requestGeneration = ++_generation;
    state = state.copyWith(
      loading: true,
      currentPage: 0,
      hasMore: true,
      posts: const [],
    );

    try {
      final posts = await repo.fetchPosts(0, userId: testUserId);
      if (requestGeneration != _generation) return;
      state = state.copyWith(
        posts: posts,
        currentPage: 0,
        hasMore: posts.length == _pageSize,
        loading: false,
      );
    } catch (_) {
      if (requestGeneration != _generation) return;
      state = state.copyWith(
        posts: const [],
        currentPage: 0,
        hasMore: false,
        loading: false,
      );
    }
  }

  Future<void> loadMore() async {
    if (state.loading || !state.hasMore) return;

    final requestGeneration = _generation;
    final nextPage = state.currentPage + 1;
    final existing = state.posts;

    state = state.copyWith(loading: true);

    try {
      final posts = await repo.fetchPosts(nextPage, userId: testUserId);
      if (requestGeneration != _generation) return;

      final seen = existing.map((p) => p.id).toSet();
      final unique = posts.where((p) => !seen.contains(p.id));
      state = state.copyWith(
        posts: [...existing, ...unique],
        currentPage: nextPage,
        hasMore: posts.length == _pageSize,
        loading: false,
      );
    } catch (_) {
      if (requestGeneration != _generation) return;
      state = state.copyWith(loading: false);
    }
  }

  void updatePost(Post updated) {
    state = state.copyWith(
      posts: [
        for (final p in state.posts)
          if (p.id == updated.id) updated else p
      ],
    );
  }
}