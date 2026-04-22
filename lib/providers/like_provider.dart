import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../models/post.dart';
import '../repositories/feed_repository.dart';
import 'feed_provider.dart';

final likeErrorMessageProvider = StateProvider<String?>((ref) => null);

final likeProvider = Provider((ref) => LikeController(ref));

class LikeController {
  final Ref ref;
  final repo = FeedRepository();
  final Map<String, _LikeSyncEntry> _entries = {};

  LikeController(this.ref);

  void toggle(Post post) {
    final notifier = ref.read(feedProvider.notifier);
    final current = _findCurrentPost(post.id) ?? post;
    final entry =
        _entries.putIfAbsent(post.id, () => _LikeSyncEntry(current));

    entry.desired = _togglePost(entry.desired);
    notifier.updatePost(entry.desired);

    entry.debounce?.cancel();
    entry.debounce = Timer(
      const Duration(milliseconds: 350),
      () => _flush(post.id),
    );
  }

  Future<void> _flush(String postId) async {
    final entry = _entries[postId];
    if (entry == null || entry.inFlight) return;
    if (_isSame(entry.confirmed, entry.desired)) {
      entry.debounce?.cancel();
      _entries.remove(postId);
      return;
    }

    entry.inFlight = true;
    try {
      await repo.toggleLike(postId, testUserId);
      entry.confirmed = _togglePost(entry.confirmed);
    } catch (_) {
      final notifier = ref.read(feedProvider.notifier);
      notifier.updatePost(entry.confirmed);
      entry.desired = entry.confirmed;
      ref.read(likeErrorMessageProvider.notifier).state =
          'Could not sync like. Check connection.';
    } finally {
      entry.inFlight = false;
    }

    if (!_isSame(entry.confirmed, entry.desired)) {
      // If user tapped again while request was in flight, keep syncing.
      unawaited(_flush(postId));
      return;
    }

    entry.debounce?.cancel();
    _entries.remove(postId);
  }

  Post _togglePost(Post post) {
    final nextLikes = post.isLiked ? post.likes - 1 : post.likes + 1;
    return post.copyWith(
      isLiked: !post.isLiked,
      likes: nextLikes < 0 ? 0 : nextLikes,
    );
  }

  Post? _findCurrentPost(String postId) {
    final feed = ref.read(feedProvider);
    for (final post in feed.posts) {
      if (post.id == postId) return post;
    }
    return null;
  }

  bool _isSame(Post a, Post b) {
    return a.id == b.id && a.likes == b.likes && a.isLiked == b.isLiked;
  }

  void clearPendingSync() {
    for (final entry in _entries.values) {
      entry.debounce?.cancel();
    }
    _entries.clear();
  }
}

class _LikeSyncEntry {
  Post confirmed;
  Post desired;
  bool inFlight;
  Timer? debounce;

  _LikeSyncEntry(Post initial)
      : confirmed = initial,
        desired = initial,
        inFlight = false;
}