class Post {
  final String id;
  final String thumb;
  final String mobile;
  final String raw;
  final int likes;
  final bool isLiked;

  Post({
    required this.id,
    required this.thumb,
    required this.mobile,
    required this.raw,
    required this.likes,
    this.isLiked = false,
  });

  Post copyWith({
    int? likes,
    bool? isLiked,
  }) {
    return Post(
      id: id,
      thumb: thumb,
      mobile: mobile,
      raw: raw,
      likes: likes ?? this.likes,
      isLiked: isLiked ?? this.isLiked,
    );
  }

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'] as String,
      thumb: map['media_thumb_url'] as String,
      mobile: map['media_mobile_url'] as String,
      raw: map['media_raw_url'] as String,
      likes: (map['like_count'] as num?)?.toInt() ?? 0,
    );
  }
}