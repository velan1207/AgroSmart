import 'package:flutter/material.dart';
import 'dart:ui_web' as ui;
import 'package:web/web.dart' as web;
import '../services/youtube_service.dart';

/// Embedded YouTube Player for Flutter Web
class YouTubePlayerWidget extends StatefulWidget {
  final YouTubeVideo video;
  final double width;
  final double height;

  const YouTubePlayerWidget({
    super.key,
    required this.video,
    this.width = double.infinity,
    this.height = 250,
  });

  @override
  State<YouTubePlayerWidget> createState() => _YouTubePlayerWidgetState();
}

class _YouTubePlayerWidgetState extends State<YouTubePlayerWidget> {
  final String _viewType = 'youtube-player-';
  late String _currentViewType;

  @override
  void initState() {
    super.initState();
    _currentViewType = '$_viewType${DateTime.now().microsecondsSinceEpoch}';
    
    // Register the iframe view
    // ignore: undefined_prefix_non_constant_identifier
    ui.platformViewRegistry.registerViewFactory(
      _currentViewType,
      (int viewId) {
        final iframe = web.HTMLIFrameElement();
        iframe.src = widget.video.embedUrl;
        iframe.style.border = 'none';
        iframe.width = '100%';
        iframe.height = '100%';
        iframe.allow = 'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture';
        iframe.allowFullscreen = true;
        return iframe;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: HtmlElementView(
          viewType: _currentViewType,
        ),
      ),
    );
  }
}
