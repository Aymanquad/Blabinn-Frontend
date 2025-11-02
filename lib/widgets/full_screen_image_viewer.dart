import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen_protector/screen_protector.dart';

class FullScreenImageViewer extends StatefulWidget {
  final String imageUrl;
  final String? heroTag;
  final bool viewOnce;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrl,
    this.heroTag,
    this.viewOnce = false,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  final TransformationController _transformationController = TransformationController();
  bool _showAppBar = true;
  bool _protectionEnabled = false;
  bool _hasAutoClosed = false;

  @override
  void initState() {
    super.initState();
    // Hide system UI for full immersion
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    _enableProtection();
  }

  @override
  void dispose() {
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    _disableProtection();
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _enableProtection() async {
    try {
      await ScreenProtector.preventScreenshotOn();
      await ScreenProtector.protectDataLeakageOn();
      _protectionEnabled = true;
      if (widget.viewOnce && !_hasAutoClosed) {
        // Auto-close after short view for view-once
        Future.delayed(const Duration(seconds: 8), () {
          if (mounted && !_hasAutoClosed) {
            _hasAutoClosed = true;
            Navigator.of(context).maybePop();
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _disableProtection() async {
    if (!_protectionEnabled) return;
    try {
      await ScreenProtector.preventScreenshotOff();
      await ScreenProtector.protectDataLeakageOff();
    } catch (_) {}
  }

  void _toggleAppBar() {
    setState(() {
      _showAppBar = !_showAppBar;
    });
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _showAppBar ? AppBar(
        backgroundColor: Colors.black.withOpacity(0.5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_out_map, color: Colors.white),
            onPressed: _resetZoom,
          ),
        ],
      ) : null,
      body: GestureDetector(
        onTap: _toggleAppBar,
        child: Center(
          child: widget.heroTag != null
              ? Hero(
                  tag: widget.heroTag!,
                  child: _buildImageViewer(),
                )
              : _buildImageViewer(),
        ),
      ),
    );
  }

  Widget _buildImageViewer() {
    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: 0.5,
      maxScale: 4.0,
      child: Image.network(
        widget.imageUrl,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
              color: Colors.white,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image,
                  size: 64,
                  color: Colors.white,
                ),
                SizedBox(height: 16),
                Text(
                  'Failed to load image',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
} 