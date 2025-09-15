import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/image_cache_service.dart';
import '../utils/logger.dart';

/// Optimized image widget with advanced caching and loading strategies
class OptimizedImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final ImageType imageType;
  final bool enableMemoryCache;
  final bool enableDiskCache;
  final bool enableThumbnail;
  final int? thumbnailWidth;
  final int? thumbnailHeight;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  final Color? backgroundColor;
  final Duration fadeInDuration;
  final bool enableFadeIn;

  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.imageType = ImageType.profile,
    this.enableMemoryCache = true,
    this.enableDiskCache = true,
    this.enableThumbnail = false,
    this.thumbnailWidth,
    this.thumbnailHeight,
    this.borderRadius,
    this.boxShadow,
    this.backgroundColor,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.enableFadeIn = true,
  });

  @override
  State<OptimizedImage> createState() => _OptimizedImageState();
}

class _OptimizedImageState extends State<OptimizedImage>
    with SingleTickerProviderStateMixin {
  late ImageCacheService _cacheService;
  Uint8List? _imageData;
  bool _isLoading = true;
  bool _hasError = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _cacheService = ImageCacheService();
    _initializeAnimations();
    _loadImage();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: widget.fadeInDuration,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadImage() async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Initialize cache service if needed
      await _cacheService.initialize();

      Uint8List? imageData;

      // Try to load thumbnail first if enabled
      if (widget.enableThumbnail && 
          widget.thumbnailWidth != null && 
          widget.thumbnailHeight != null) {
        imageData = await _cacheService.generateThumbnail(
          widget.imageUrl,
          maxWidth: widget.thumbnailWidth!,
          maxHeight: widget.thumbnailHeight!,
        );
      }

      // If thumbnail failed or not enabled, load full image
      if (imageData == null) {
        if (widget.enableMemoryCache || widget.enableDiskCache) {
          imageData = await _cacheService.getOrCacheImage(
            widget.imageUrl,
            type: widget.imageType,
          );
        } else {
          // Direct network load without caching
          imageData = await _loadImageFromNetwork();
        }
      }

      if (mounted) {
        setState(() {
          _imageData = imageData;
          _isLoading = false;
          _hasError = imageData == null;
        });

        if (widget.enableFadeIn && imageData != null) {
          _fadeController.forward();
        }
      }
    } catch (e) {
      Logger.error('Failed to load image: ${widget.imageUrl}', error: e);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Future<Uint8List?> _loadImageFromNetwork() async {
    try {
      // This is a simplified network load
      // In a real implementation, you would use http package
      // For now, return null to trigger error state
      return null;
    } catch (e) {
      Logger.error('Network load failed', error: e);
      return null;
    }
  }

  @override
  void didUpdateWidget(OptimizedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadImage();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        boxShadow: widget.boxShadow,
        color: widget.backgroundColor,
      ),
      child: ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.zero,
        child: _buildImageContent(),
      ),
    );
  }

  Widget _buildImageContent() {
    if (_isLoading) {
      return _buildPlaceholder();
    }

    if (_hasError || _imageData == null) {
      return _buildErrorWidget();
    }

    final imageWidget = Image.memory(
      _imageData!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorBuilder: (context, error, stackTrace) {
        Logger.error('Image rendering error', error: error);
        return _buildErrorWidget();
      },
    );

    if (widget.enableFadeIn) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildPlaceholder() {
    if (widget.placeholder != null) {
      return widget.placeholder!;
    }

    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[300],
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorWidget() {
    if (widget.errorWidget != null) {
      return widget.errorWidget!;
    }

    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[300],
      child: const Center(
        child: Icon(
          Icons.broken_image,
          color: Colors.grey,
        ),
      ),
    );
  }
}

/// Circular profile image with optimization
class OptimizedProfileImage extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final String? fallbackText;
  final Color? backgroundColor;
  final Color? textColor;
  final bool enableCache;

  const OptimizedProfileImage({
    super.key,
    this.imageUrl,
    this.size = 50,
    this.fallbackText,
    this.backgroundColor,
    this.textColor,
    this.enableCache = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? Theme.of(context).colorScheme.primary,
      ),
      child: ClipOval(
        child: imageUrl != null
            ? OptimizedImage(
                imageUrl: imageUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                imageType: ImageType.profile,
                enableMemoryCache: enableCache,
                enableDiskCache: enableCache,
                placeholder: _buildLoadingPlaceholder(),
                errorWidget: _buildFallback(),
              )
            : _buildFallback(),
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      width: size,
      height: size,
      color: Colors.grey[300],
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      width: size,
      height: size,
      color: backgroundColor ?? Colors.grey[400],
      child: Center(
        child: Text(
          fallbackText ?? '?',
          style: TextStyle(
            color: textColor ?? Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// Gallery image with thumbnail support
class OptimizedGalleryImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final bool enableThumbnail;

  const OptimizedGalleryImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.onTap,
    this.enableThumbnail = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: OptimizedImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        imageType: ImageType.gallery,
        enableThumbnail: enableThumbnail,
        thumbnailWidth: 200,
        thumbnailHeight: 200,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        placeholder: _buildPlaceholder(),
        errorWidget: _buildErrorWidget(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Center(
        child: Icon(
          Icons.broken_image,
          color: Colors.grey,
        ),
      ),
    );
  }
}

/// Chat image with optimization
class OptimizedChatImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  const OptimizedChatImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: OptimizedImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        imageType: ImageType.chat,
        enableThumbnail: true,
        thumbnailWidth: 150,
        thumbnailHeight: 150,
        borderRadius: BorderRadius.circular(12),
        placeholder: _buildPlaceholder(),
        errorWidget: _buildErrorWidget(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Center(
        child: Icon(
          Icons.broken_image,
          color: Colors.grey,
        ),
      ),
    );
  }
}
