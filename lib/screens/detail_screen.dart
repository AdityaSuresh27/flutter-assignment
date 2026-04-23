import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/post.dart';

class DetailScreen extends StatefulWidget {
  final Post post;

  const DetailScreen({super.key, required this.post});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool mobileLoaded = false;
  bool downloadingRaw = false;

  String _usernameFromId(String id) {
    final short = id.length > 6 ? id.substring(0, 6) : id;
    return 'user_$short';
  }

  Future<void> _downloadHighRes() async {
    if (downloadingRaw) return;
    setState(() => downloadingRaw = true);
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(widget.post.raw));
      final response = await request.close();
      final bytes = await consolidateHttpClientResponseBytes(response);
      client.close(force: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('High-res fetched: ${bytes.length} bytes'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch high-res image.')),
      );
    } finally {
      if (mounted) {
        setState(() => downloadingRaw = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final mobileCacheWidth =
        (width * media.devicePixelRatio).round().clamp(1, 1080);
    final username = _usernameFromId(widget.post.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(username),
      ),
      body: ListView(
        children: [
          Hero(
            tag: widget.post.id,
            child: Stack(
              children: [
                Image.network(
                  widget.post.thumb,
                  width: width,
                  height: width,
                  fit: BoxFit.cover,
                ),
                AnimatedOpacity(
                  opacity: mobileLoaded ? 1 : 0,
                  duration: const Duration(milliseconds: 260),
                  child: Image.network(
                    widget.post.mobile,
                    width: width,
                    height: width,
                    fit: BoxFit.cover,
                    cacheWidth: mobileCacheWidth,
                    frameBuilder: (context, child, frame, _) {
                      if (frame != null && !mobileLoaded) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() => mobileLoaded = true);
                          }
                        });
                      }
                      return child;
                    },
                  ),
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      widget.post.isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: widget.post.isLiked
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF334155),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.post.likes} likes',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    const Icon(Icons.ios_share_rounded,
                        color: Color(0xFF334155)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '$username  Enjoying the feed view with staged image loading.',
                  style: const TextStyle(height: 1.4),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: downloadingRaw ? null : _downloadHighRes,
                    icon: Icon(downloadingRaw
                        ? Icons.downloading_rounded
                        : Icons.download_rounded),
                    label: Text(
                      downloadingRaw
                          ? 'Fetching high-res...'
                          : 'Download High-Res',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}