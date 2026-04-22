import '../core/supabase_client.dart';
import '../models/post.dart';

class FeedRepository {
  Future<List<Post>> fetchPosts(int page, {required String userId}) async {
    final from = page * 10;
    final to = from + 9;

    final res = await supabase
        .from('posts')
        .select()
        .order('created_at', ascending: false)
        .range(from, to);

    final posts = (res as List).map((e) => Post.fromMap(e)).toList();
    if (posts.isEmpty) return posts;

    final postIds = posts.map((p) => p.id).toList(growable: false);
    final likesRes = await supabase
        .from('user_likes')
        .select('post_id')
        .eq('user_id', userId)
        .inFilter('post_id', postIds);

    final likedIds = <String>{
      for (final row in (likesRes as List)) row['post_id'] as String,
    };

    return posts
        .map((p) => p.copyWith(isLiked: likedIds.contains(p.id)))
        .toList(growable: false);
  }

  Future<void> toggleLike(String postId, String userId) async {
    await supabase.rpc('toggle_like', params: {
      'p_post_id': postId,
      'p_user_id': userId,
    });
  }
}