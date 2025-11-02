import 'dart:async';
import 'package:flutter/material.dart';
import 'image_cache_service.dart';
import '../utils/logger.dart';

/// Service for preloading images to improve user experience
class ImagePreloader {
  static final ImagePreloader _instance = ImagePreloader._internal();
  factory ImagePreloader() => _instance;
  ImagePreloader._internal();

  final ImageCacheService _cacheService = ImageCacheService();
  final Set<String> _preloadingUrls = {};
  final Set<String> _preloadedUrls = {};
  final Map<String, Completer<void>> _preloadCompleters = {};

  /// Preload a single image
  Future<void> preloadImage(String url, {ImageType type = ImageType.profile}) async {
    if (_preloadedUrls.contains(url)) {
      Logger.debug('Image already preloaded: $url');
      return;
    }

    if (_preloadingUrls.contains(url)) {
      // Wait for existing preload to complete
      final completer = _preloadCompleters[url];
      if (completer != null) {
        await completer.future;
      }
      return;
    }

    try {
      _preloadingUrls.add(url);
      final completer = Completer<void>();
      _preloadCompleters[url] = completer;

      Logger.debug('Preloading image: $url');
      await _cacheService.cacheImage(url, type: type);
      
      _preloadedUrls.add(url);
      _preloadingUrls.remove(url);
      _preloadCompleters.remove(url);
      completer.complete();

      Logger.debug('Image preloaded successfully: $url');
    } catch (e) {
      Logger.error('Failed to preload image: $url', error: e);
      _preloadingUrls.remove(url);
      _preloadCompleters.remove(url);
      rethrow;
    }
  }

  /// Preload multiple images
  Future<void> preloadImages(List<String> urls, {ImageType type = ImageType.profile}) async {
    if (urls.isEmpty) return;

    Logger.debug('Preloading ${urls.length} images');
    
    try {
      // Filter out already preloaded URLs
      final urlsToPreload = urls.where((url) => !_preloadedUrls.contains(url)).toList();
      
      if (urlsToPreload.isEmpty) {
        Logger.debug('All images already preloaded');
        return;
      }

      // Preload in batches to avoid overwhelming the system
      const batchSize = 5;
      for (int i = 0; i < urlsToPreload.length; i += batchSize) {
        final batch = urlsToPreload.skip(i).take(batchSize).toList();
        await Future.wait(
          batch.map((url) => preloadImage(url, type: type)),
        );
        
        // Small delay between batches
        if (i + batchSize < urlsToPreload.length) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      Logger.debug('Preloaded ${urlsToPreload.length} images successfully');
    } catch (e) {
      Logger.error('Failed to preload images', error: e);
      rethrow;
    }
  }

  /// Preload images for a specific screen
  Future<void> preloadForScreen(String screenName, List<String> urls, {ImageType type = ImageType.profile}) async {
    Logger.debug('Preloading images for screen: $screenName');
    await preloadImages(urls, type: type);
  }

  /// Preload profile images for a list of users
  Future<void> preloadProfileImages(List<Map<String, dynamic>> users) async {
    final profileImageUrls = users
        .map((user) => user['profileImage'] as String?)
        .where((url) => url != null && url.isNotEmpty)
        .cast<String>()
        .toList();

    if (profileImageUrls.isNotEmpty) {
      await preloadImages(profileImageUrls, type: ImageType.profile);
    }
  }

  /// Preload gallery images for a user
  Future<void> preloadGalleryImages(List<String> imageUrls) async {
    if (imageUrls.isNotEmpty) {
      await preloadImages(imageUrls, type: ImageType.gallery);
    }
  }

  /// Preload chat images for a conversation
  Future<void> preloadChatImages(List<String> imageUrls) async {
    if (imageUrls.isNotEmpty) {
      await preloadImages(imageUrls, type: ImageType.chat);
    }
  }

  /// Check if an image is preloaded
  bool isPreloaded(String url) {
    return _preloadedUrls.contains(url);
  }

  /// Check if an image is currently being preloaded
  bool isPreloading(String url) {
    return _preloadingUrls.contains(url);
  }

  /// Get preload statistics
  PreloadStats getStats() {
    return PreloadStats(
      preloadedCount: _preloadedUrls.length,
      preloadingCount: _preloadingUrls.length,
      preloadedUrls: Set.from(_preloadedUrls),
      preloadingUrls: Set.from(_preloadingUrls),
    );
  }

  /// Clear preload cache
  void clearPreloadCache() {
    _preloadedUrls.clear();
    _preloadingUrls.clear();
    _preloadCompleters.clear();
    Logger.debug('Preload cache cleared');
  }

  /// Cancel ongoing preloads
  void cancelPreloads() {
    for (final completer in _preloadCompleters.values) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
    _preloadingUrls.clear();
    _preloadCompleters.clear();
    Logger.debug('Preloads cancelled');
  }
}

/// Preload statistics
class PreloadStats {
  final int preloadedCount;
  final int preloadingCount;
  final Set<String> preloadedUrls;
  final Set<String> preloadingUrls;

  PreloadStats({
    required this.preloadedCount,
    required this.preloadingCount,
    required this.preloadedUrls,
    required this.preloadingUrls,
  });

  @override
  String toString() {
    return 'PreloadStats(preloaded: $preloadedCount, preloading: $preloadingCount)';
  }
}

/// Widget that automatically preloads images when it becomes visible
class ImagePreloaderWidget extends StatefulWidget {
  final Widget child;
  final List<String> imageUrls;
  final ImageType imageType;
  final bool enabled;

  const ImagePreloaderWidget({
    super.key,
    required this.child,
    required this.imageUrls,
    this.imageType = ImageType.profile,
    this.enabled = true,
  });

  @override
  State<ImagePreloaderWidget> createState() => _ImagePreloaderWidgetState();
}

class _ImagePreloaderWidgetState extends State<ImagePreloaderWidget>
    with AutomaticKeepAliveClientMixin {
  final ImagePreloader _preloader = ImagePreloader();
  bool _hasPreloaded = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      _preloadImages();
    }
  }

  @override
  void didUpdateWidget(ImagePreloaderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && 
        (oldWidget.imageUrls != widget.imageUrls || !_hasPreloaded)) {
      _preloadImages();
    }
  }

  Future<void> _preloadImages() async {
    if (widget.imageUrls.isEmpty || _hasPreloaded) return;

    try {
      await _preloader.preloadImages(widget.imageUrls, type: widget.imageType);
      _hasPreloaded = true;
    } catch (e) {
      Logger.error('Failed to preload images in widget', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

/// Mixin for widgets that need image preloading
mixin ImagePreloadingMixin<T extends StatefulWidget> on State<T> {
  final ImagePreloader _preloader = ImagePreloader();

  /// Preload images when widget is initialized
  Future<void> preloadImages(List<String> urls, {ImageType type = ImageType.profile}) async {
    try {
      await _preloader.preloadImages(urls, type: type);
    } catch (e) {
      Logger.error('Failed to preload images in mixin', error: e);
    }
  }

  /// Preload profile images for users
  Future<void> preloadUserProfileImages(List<Map<String, dynamic>> users) async {
    await _preloader.preloadProfileImages(users);
  }

  /// Check if image is preloaded
  bool isImagePreloaded(String url) {
    return _preloader.isPreloaded(url);
  }
}
