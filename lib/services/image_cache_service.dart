import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../utils/logger.dart';

/// Advanced image caching service with multiple strategies
class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  // Cache managers for different image types
  late CacheManager _profileImageCache;
  late CacheManager _galleryImageCache;
  late CacheManager _chatImageCache;
  late CacheManager _thumbnailCache;

  // Memory cache for frequently accessed images
  final Map<String, Uint8List> _memoryCache = {};
  final Map<String, DateTime> _memoryCacheTimestamps = {};
  
  // Cache configuration
  static const int maxMemoryCacheSize = 50; // Maximum number of images in memory
  static const Duration memoryCacheExpiry = Duration(minutes: 30);
  static const Duration diskCacheExpiry = Duration(days: 7);
  static const int maxDiskCacheSize = 200 * 1024 * 1024; // 200MB

  bool _isInitialized = false;

  /// Initialize the image cache service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      Logger.info('Initializing ImageCacheService...');

      // Initialize cache managers with different configurations
      _profileImageCache = CacheManager(
        Config(
          'profile_images',
          stalePeriod: diskCacheExpiry,
          maxNrOfCacheObjects: 1000,
          repo: JsonCacheInfoRepository(databaseName: 'profile_images'),
          fileService: HttpFileService(),
        ),
      );

      _galleryImageCache = CacheManager(
        Config(
          'gallery_images',
          stalePeriod: diskCacheExpiry,
          maxNrOfCacheObjects: 500,
          repo: JsonCacheInfoRepository(databaseName: 'gallery_images'),
          fileService: HttpFileService(),
        ),
      );

      _chatImageCache = CacheManager(
        Config(
          'chat_images',
          stalePeriod: diskCacheExpiry,
          maxNrOfCacheObjects: 2000,
          repo: JsonCacheInfoRepository(databaseName: 'chat_images'),
          fileService: HttpFileService(),
        ),
      );

      _thumbnailCache = CacheManager(
        Config(
          'thumbnails',
          stalePeriod: diskCacheExpiry,
          maxNrOfCacheObjects: 5000,
          repo: JsonCacheInfoRepository(databaseName: 'thumbnails'),
          fileService: HttpFileService(),
        ),
      );

      // Clean up old memory cache entries
      _startMemoryCacheCleanup();

      _isInitialized = true;
      Logger.info('ImageCacheService initialized successfully');
    } catch (e) {
      Logger.error('Failed to initialize ImageCacheService', error: e);
      rethrow;
    }
  }

  /// Get cache manager for specific image type
  CacheManager _getCacheManager(ImageType type) {
    switch (type) {
      case ImageType.profile:
        return _profileImageCache;
      case ImageType.gallery:
        return _galleryImageCache;
      case ImageType.chat:
        return _chatImageCache;
      case ImageType.thumbnail:
        return _thumbnailCache;
    }
  }

  /// Generate cache key for image URL
  String _generateCacheKey(String url) {
    final bytes = utf8.encode(url);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Get image from cache (memory first, then disk)
  Future<Uint8List?> getImage(String url, {ImageType type = ImageType.profile}) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final cacheKey = _generateCacheKey(url);

      // Check memory cache first
      if (_memoryCache.containsKey(cacheKey)) {
        final timestamp = _memoryCacheTimestamps[cacheKey];
        if (timestamp != null && 
            DateTime.now().difference(timestamp) < memoryCacheExpiry) {
          Logger.debug('Image loaded from memory cache: $url');
          return _memoryCache[cacheKey];
        } else {
          // Remove expired entry
          _memoryCache.remove(cacheKey);
          _memoryCacheTimestamps.remove(cacheKey);
        }
      }

      // Check disk cache
      final cacheManager = _getCacheManager(type);
      final file = await cacheManager.getFileFromCache(url);
      
      if (file != null) {
        final bytes = await file.file.readAsBytes();
        
        // Add to memory cache
        _addToMemoryCache(cacheKey, bytes);
        
        Logger.debug('Image loaded from disk cache: $url');
        return bytes;
      }

      Logger.debug('Image not found in cache: $url');
      return null;
    } catch (e) {
      Logger.error('Failed to get image from cache', error: e);
      return null;
    }
  }

  /// Cache image from URL
  Future<Uint8List?> cacheImage(String url, {ImageType type = ImageType.profile}) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final cacheKey = _generateCacheKey(url);
      final cacheManager = _getCacheManager(type);

      // Download and cache the image
      final file = await cacheManager.getSingleFile(url);
      final bytes = await file.readAsBytes();

      // Add to memory cache
      _addToMemoryCache(cacheKey, bytes);

      Logger.debug('Image cached successfully: $url');
      return bytes;
    } catch (e) {
      Logger.error('Failed to cache image', error: e);
      return null;
    }
  }

  /// Get or cache image (convenience method)
  Future<Uint8List?> getOrCacheImage(String url, {ImageType type = ImageType.profile}) async {
    // Try to get from cache first
    final cachedImage = await getImage(url, type: type);
    if (cachedImage != null) {
      return cachedImage;
    }

    // If not in cache, download and cache it
    return await cacheImage(url, type: type);
  }

  /// Add image to memory cache
  void _addToMemoryCache(String key, Uint8List bytes) {
    // Check if we need to evict old entries
    if (_memoryCache.length >= maxMemoryCacheSize) {
      _evictOldestMemoryCacheEntry();
    }

    _memoryCache[key] = bytes;
    _memoryCacheTimestamps[key] = DateTime.now();
  }

  /// Evict oldest entry from memory cache
  void _evictOldestMemoryCacheEntry() {
    if (_memoryCacheTimestamps.isEmpty) return;

    String? oldestKey;
    DateTime? oldestTime;

    for (final entry in _memoryCacheTimestamps.entries) {
      if (oldestTime == null || entry.value.isBefore(oldestTime)) {
        oldestTime = entry.value;
        oldestKey = entry.key;
      }
    }

    if (oldestKey != null) {
      _memoryCache.remove(oldestKey);
      _memoryCacheTimestamps.remove(oldestKey);
    }
  }

  /// Start memory cache cleanup timer
  void _startMemoryCacheCleanup() {
    // Clean up expired entries every 5 minutes
    Timer.periodic(const Duration(minutes: 5), (timer) {
      _cleanupExpiredMemoryCache();
    });
  }

  /// Clean up expired memory cache entries
  void _cleanupExpiredMemoryCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _memoryCacheTimestamps.entries) {
      if (now.difference(entry.value) > memoryCacheExpiry) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _memoryCache.remove(key);
      _memoryCacheTimestamps.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      Logger.debug('Cleaned up ${expiredKeys.length} expired memory cache entries');
    }
  }

  /// Clear specific image from cache
  Future<void> clearImage(String url, {ImageType type = ImageType.profile}) async {
    try {
      final cacheKey = _generateCacheKey(url);
      final cacheManager = _getCacheManager(type);

      // Remove from memory cache
      _memoryCache.remove(cacheKey);
      _memoryCacheTimestamps.remove(cacheKey);

      // Remove from disk cache
      await cacheManager.removeFile(url);

      Logger.debug('Image cleared from cache: $url');
    } catch (e) {
      Logger.error('Failed to clear image from cache', error: e);
    }
  }

  /// Clear all cache for specific type
  Future<void> clearCache({ImageType? type}) async {
    try {
      if (type != null) {
        final cacheManager = _getCacheManager(type);
        await cacheManager.emptyCache();
        Logger.debug('Cleared cache for type: $type');
      } else {
        // Clear all caches
        await _profileImageCache.emptyCache();
        await _galleryImageCache.emptyCache();
        await _chatImageCache.emptyCache();
        await _thumbnailCache.emptyCache();
        
        // Clear memory cache
        _memoryCache.clear();
        _memoryCacheTimestamps.clear();
        
        Logger.debug('Cleared all image caches');
      }
    } catch (e) {
      Logger.error('Failed to clear cache', error: e);
    }
  }

  /// Get cache statistics
  Future<CacheStats> getCacheStats() async {
    try {
      final profileStats = await _profileImageCache.getCacheStats();
      final galleryStats = await _galleryImageCache.getCacheStats();
      final chatStats = await _chatImageCache.getCacheStats();
      final thumbnailStats = await _thumbnailCache.getCacheStats();

      return CacheStats(
        totalFiles: profileStats.numberOfFiles + 
                   galleryStats.numberOfFiles + 
                   chatStats.numberOfFiles + 
                   thumbnailStats.numberOfFiles,
        totalSize: profileStats.totalSize + 
                  galleryStats.totalSize + 
                  chatStats.totalSize + 
                  thumbnailStats.totalSize,
        memoryCacheSize: _memoryCache.length,
        profileFiles: profileStats.numberOfFiles,
        galleryFiles: galleryStats.numberOfFiles,
        chatFiles: chatStats.numberOfFiles,
        thumbnailFiles: thumbnailStats.numberOfFiles,
      );
    } catch (e) {
      Logger.error('Failed to get cache stats', error: e);
      return CacheStats();
    }
  }

  /// Preload images for better performance
  Future<void> preloadImages(List<String> urls, {ImageType type = ImageType.profile}) async {
    try {
      final futures = urls.map((url) => cacheImage(url, type: type));
      await Future.wait(futures);
      Logger.debug('Preloaded ${urls.length} images');
    } catch (e) {
      Logger.error('Failed to preload images', error: e);
    }
  }

  /// Generate thumbnail for image
  Future<Uint8List?> generateThumbnail(String imageUrl, {int maxWidth = 200, int maxHeight = 200}) async {
    try {
      // Check if thumbnail already exists
      final thumbnailUrl = '${imageUrl}_thumb_${maxWidth}x${maxHeight}';
      final existingThumbnail = await getImage(thumbnailUrl, type: ImageType.thumbnail);
      if (existingThumbnail != null) {
        return existingThumbnail;
      }

      // Get original image
      final originalImage = await getOrCacheImage(imageUrl);
      if (originalImage == null) return null;

      // Generate thumbnail (simplified - in real implementation, use image processing library)
      // For now, return the original image
      // TODO: Implement actual thumbnail generation using image package
      
      // Cache the thumbnail
      await cacheImage(thumbnailUrl, type: ImageType.thumbnail);
      
      return originalImage;
    } catch (e) {
      Logger.error('Failed to generate thumbnail', error: e);
      return null;
    }
  }

  /// Dispose resources
  void dispose() {
    _memoryCache.clear();
    _memoryCacheTimestamps.clear();
    _isInitialized = false;
  }
}

/// Image types for different caching strategies
enum ImageType {
  profile,
  gallery,
  chat,
  thumbnail,
}

/// Cache statistics
class CacheStats {
  final int totalFiles;
  final int totalSize;
  final int memoryCacheSize;
  final int profileFiles;
  final int galleryFiles;
  final int chatFiles;
  final int thumbnailFiles;

  CacheStats({
    this.totalFiles = 0,
    this.totalSize = 0,
    this.memoryCacheSize = 0,
    this.profileFiles = 0,
    this.galleryFiles = 0,
    this.chatFiles = 0,
    this.thumbnailFiles = 0,
  });

  String get formattedSize {
    if (totalSize < 1024) return '${totalSize}B';
    if (totalSize < 1024 * 1024) return '${(totalSize / 1024).toStringAsFixed(1)}KB';
    return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}
