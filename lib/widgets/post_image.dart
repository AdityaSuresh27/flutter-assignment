import 'package:flutter/material.dart';

class PostImage extends StatelessWidget {
  final String url;

  const PostImage({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final targetWidth = width.round().clamp(1, 4096);

    return Image.network(
      url,
      width: width,
      height: width,
      fit: BoxFit.cover,
      cacheWidth: targetWidth,
      filterQuality: FilterQuality.low,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return SizedBox(
          width: width,
          height: width,
          child: const ColoredBox(color: Color(0xFFF2F2F2)),
        );
      },
      errorBuilder: (context, _, error) {
        return SizedBox(
          width: width,
          height: width,
          child: const ColoredBox(color: Color(0xFFEAEAEA)),
        );
      },
    );
  }
}