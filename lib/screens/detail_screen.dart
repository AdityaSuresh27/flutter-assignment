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

    return Scaffold(
      appBar: AppBar(),
      body: Column(
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
          ElevatedButton(
            onPressed: downloadingRaw ? null : _downloadHighRes,
            child: Text(
              downloadingRaw ? 'Fetching...' : 'Download High-Res',
            ),
          )
        ],
      ),
    );
  }
}