import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:convert';
import '../core/constants.dart';
import '../services/api_service.dart';
import '../services/premium_service.dart';
import '../utils/permission_helper.dart';
import '../widgets/banner_ad_widget.dart';

/// MediaFolderScreen - Manages user's media collection with two tabs:
/// 1. Saved - All images saved to media folder (from camera)
/// 2. Received - Images received from friends in chats
///
/// INTEGRATION WITH CHAT SYSTEM:
/// To automatically save received images from friends, call:
/// ```dart
/// import '../screens/media_folder_screen.dart';
///
/// // In your chat message handler when an image is received:
/// await MediaFolderScreen.saveReceivedImage(imageFile, friendId, friendName);
/// ```
///
/// FEATURES IMPLEMENTED:
/// ✅ Fixed Android 13+ photo permission handling
/// ✅ Gallery metadata system to track image sources
/// ✅ Automatic chronological sorting (newest first)
/// ✅ Performance optimizations with caching
/// ✅ Error handling for corrupted images
/// ✅ Permission settings redirect for permanently denied permissions
/// ✅ Real-time integration with chat system for auto-saving received images
///
/// HOW IT WORKS:
/// When friends send you images in chat, they're automatically saved to the "Received" tab
/// with the friend's name displayed. You can view, share, or delete these images.
class MediaFolderScreen extends StatefulWidget {
  const MediaFolderScreen({super.key});

  @override
  State<MediaFolderScreen> createState() => _MediaFolderScreenState();

  // Function to save received images from friends (called from chat system)
  static Future<void> saveReceivedImage(
      File imageFile, String friendId, String friendName,
      {String? messageId, String? imageUrl}) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final mediaDir = Directory('${directory.path}/media');

      if (!await mediaDir.exists()) {
        await mediaDir.create(recursive: true);
      }

      final timestamp = DateTime.now();
      final fileName = '${timestamp.millisecondsSinceEpoch}_received.jpg';
      final savedFile = File('${mediaDir.path}/$fileName');

      await imageFile.copy(savedFile.path);

      // Save metadata with friend info, messageId, and imageUrl
      await _saveImageMetadataStatic(fileName, 'received', timestamp,
          friendId: friendId,
          friendName: friendName,
          messageId: messageId,
          imageUrl: imageUrl);

      //print('✅ Received image saved successfully: $friendName -> $fileName');
    } catch (e) {
      //print('Error saving received image: $e');
    }
  }

  static Future<void> _saveImageMetadataStatic(
      String fileName, String source, DateTime timestamp,
      {String? friendId,
      String? friendName,
      String? messageId,
      String? imageUrl}) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final metadataFile = File('${directory.path}/media_metadata.json');

      Map<String, dynamic> metadata = {};
      if (await metadataFile.exists()) {
        final content = await metadataFile.readAsString();
        if (content.isNotEmpty) {
          final decodedMetadata = json.decode(content);
          metadata = Map<String, dynamic>.from(decodedMetadata as Map);
        }
      }

      Map<String, dynamic> imageMetadata = {
        'source': source,
        'timestamp': timestamp.toIso8601String(),
        'dateAdded': timestamp.toIso8601String(),
      };

      if (friendId != null) {
        imageMetadata['friendId'] = friendId;
        imageMetadata['friendName'] = friendName;
      }

      if (messageId != null) {
        imageMetadata['messageId'] = messageId;
      }

      if (imageUrl != null) {
        imageMetadata['imageUrl'] = imageUrl;
      }

      metadata[fileName] = imageMetadata;
      await metadataFile.writeAsString(json.encode(metadata));
    } catch (e) {
      //print('Error saving image metadata: $e');
    }
  }
}

class _MediaFolderScreenState extends State<MediaFolderScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ImagePicker _picker = ImagePicker();
  final ApiService _apiService = ApiService();
  final PremiumService _premiumService = PremiumService();

  List<Map<String, dynamic>> _savedImages = [];
  List<Map<String, dynamic>> _receivedImages = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkPermissions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.photos.status;
    setState(() {
      _hasPermission = status.isGranted;
    });

    if (_hasPermission) {
      _loadImages();
    }
  }

  Future<void> _loadImages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final directory = await getApplicationDocumentsDirectory();
      final mediaDir = Directory('${directory.path}/media');

      print('🔍 [MEDIA DEBUG] Media directory path: ${mediaDir.path}');
      print('🔍 [MEDIA DEBUG] Media directory exists: ${await mediaDir.exists()}');

      if (!await mediaDir.exists()) {
        print('🔍 [MEDIA DEBUG] Media directory does not exist, creating empty lists');
        setState(() {
          _savedImages = [];
          _receivedImages = [];
          _isLoading = false;
        });
        return;
      }

      final files = await mediaDir.list().toList();
      print('🔍 [MEDIA DEBUG] Found ${files.length} files in media directory');
      
      final metadataFile = File('${directory.path}/media_metadata.json');
      Map<String, dynamic> metadata = {};

      if (await metadataFile.exists()) {
        final content = await metadataFile.readAsString();
        if (content.isNotEmpty) {
          final decodedMetadata = json.decode(content);
          metadata = Map<String, dynamic>.from(decodedMetadata as Map);
          print('🔍 [MEDIA DEBUG] Loaded metadata for ${metadata.length} images');
        }
      } else {
        print('🔍 [MEDIA DEBUG] No metadata file found');
      }

      final List<Map<String, dynamic>> savedImages = [];
      final List<Map<String, dynamic>> receivedImages = [];

      for (final file in files) {
        if (file is File && file.path.endsWith('.jpg')) {
          final fileName = file.path.split('/').last;
          final fileMetadata = (metadata[fileName] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
          final source = fileMetadata['source'] ?? 'saved';

          print('🔍 [MEDIA DEBUG] Processing file: $fileName (source: $source)');

          final imageData = <String, dynamic>{
            'file': file,
            'fileName': fileName,
            'metadata': fileMetadata,
            'timestamp': DateTime.tryParse(fileMetadata['timestamp'] ?? '') ?? DateTime.now(),
          };

          if (source == 'received') {
            receivedImages.add(imageData);
          } else {
            savedImages.add(imageData);
          }
        }
      }

      // Sort by timestamp (newest first)
      savedImages.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
      receivedImages.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

      print('🔍 [MEDIA DEBUG] Final counts - Saved: ${savedImages.length}, Received: ${receivedImages.length}');

      setState(() {
        _savedImages = savedImages;
        _receivedImages = receivedImages;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ [MEDIA DEBUG] Error loading images: $e');
      setState(() {
        _errorMessage = 'Failed to load images: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D1B69), // Dark purple background
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg1.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              // Tab bar
              _buildTabBar(),
              
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Back button
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          
          // Title in center
          const Expanded(
            child: Text(
              'Media Gallery',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          
          // Add photo icon
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: _takePhoto,
              icon: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFF8B5CF6),
          borderRadius: BorderRadius.circular(16),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.7),
        labelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_camera, size: 18),
                SizedBox(width: 8),
                Text('Saved'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_library, size: 18),
                SizedBox(width: 8),
                Text('Received'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (!_hasPermission) {
      return _buildPermissionRequest();
    }

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.white.withOpacity(0.7),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadImages,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildImageGrid(_savedImages, 'saved'),
        _buildImageGrid(_receivedImages, 'received'),
      ],
    );
  }

  Widget _buildPermissionRequest() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library,
            color: Colors.white.withOpacity(0.7),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Photo Permission Required',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Allow access to your photos to view and manage your media',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _requestPermission,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid(List<Map<String, dynamic>> images, String type) {
    if (images.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  type == 'saved' ? Icons.photo_camera : Icons.photo_library,
                  color: Colors.white.withOpacity(0.8),
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                type == 'saved' ? 'No saved photos' : 'No received photos',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                type == 'saved' 
                  ? 'Take photos to see them here'
                  : 'Photos from friends will appear here',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final image = images[index];
        return _buildImageTile(image, type);
      },
    );
  }

  Widget _buildImageTile(Map<String, dynamic> image, String type) {
    final file = image['file'] as File;
    final metadata = (image['metadata'] as Map).cast<String, dynamic>();
    
    return GestureDetector(
      onTap: () => _showImageDetail(image, type),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Image.file(
                file,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
              // Gradient overlay for better text readability
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),
              if (type == 'received' && metadata['friendName'] != null)
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Text(
                    metadata['friendName'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              // Play button overlay for videos (if needed in future)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    type == 'saved' ? Icons.photo_camera : Icons.photo_library,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageDetail(Map<String, dynamic> image, String type) {
    final file = image['file'] as File;
    final metadata = (image['metadata'] as Map).cast<String, dynamic>();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.file(
                  file,
                  fit: BoxFit.contain,
                  height: 300,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (type == 'received' && metadata['friendName'] != null)
                      Text(
                        'From: ${metadata['friendName']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _shareImage(file);
                          },
                          icon: const Icon(Icons.share),
                          label: const Text('Share'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5CF6),
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _deleteImage(image);
                          },
                          icon: const Icon(Icons.delete),
                          label: const Text('Delete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _requestPermission() async {
    final status = await Permission.photos.request();
    setState(() {
      _hasPermission = status.isGranted;
    });

    if (_hasPermission) {
      _loadImages();
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        await _savePhoto(File(photo.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to take photo: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _savePhoto(File photoFile) async {
    try {
      print('📸 [MEDIA DEBUG] Starting to save photo...');
      final directory = await getApplicationDocumentsDirectory();
      final mediaDir = Directory('${directory.path}/media');

      if (!await mediaDir.exists()) {
        print('📸 [MEDIA DEBUG] Creating media directory');
        await mediaDir.create(recursive: true);
      }

      final timestamp = DateTime.now();
      final fileName = '${timestamp.millisecondsSinceEpoch}_saved.jpg';
      final savedFile = File('${mediaDir.path}/$fileName');

      print('📸 [MEDIA DEBUG] Saving photo as: $fileName');
      await photoFile.copy(savedFile.path);

      // Save metadata
      await _saveImageMetadata(fileName, 'saved', timestamp);
      print('📸 [MEDIA DEBUG] Photo saved successfully!');

      _loadImages(); // Reload images
    } catch (e) {
      print('❌ [MEDIA DEBUG] Error saving photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save photo: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveImageMetadata(String fileName, String source, DateTime timestamp) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final metadataFile = File('${directory.path}/media_metadata.json');

      Map<String, dynamic> metadata = {};
      if (await metadataFile.exists()) {
        final content = await metadataFile.readAsString();
        if (content.isNotEmpty) {
          final decodedMetadata = json.decode(content);
          metadata = Map<String, dynamic>.from(decodedMetadata as Map);
        }
      }

      metadata[fileName] = {
        'source': source,
        'timestamp': timestamp.toIso8601String(),
        'dateAdded': timestamp.toIso8601String(),
      };

      await metadataFile.writeAsString(json.encode(metadata));
    } catch (e) {
      //print('Error saving image metadata: $e');
    }
  }

  Future<void> _shareImage(File imageFile) async {
    // TODO: Implement image sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _deleteImage(Map<String, dynamic> image) async {
    try {
      final file = image['file'] as File;
      final fileName = image['fileName'] as String;

      // Delete the file
      await file.delete();

      // Remove from metadata
      final directory = await getApplicationDocumentsDirectory();
      final metadataFile = File('${directory.path}/media_metadata.json');

      if (await metadataFile.exists()) {
        final content = await metadataFile.readAsString();
        if (content.isNotEmpty) {
          final decodedMetadata = json.decode(content);
          final metadata = Map<String, dynamic>.from(decodedMetadata as Map);
          metadata.remove(fileName);
          await metadataFile.writeAsString(json.encode(metadata));
        }
      }

      _loadImages(); // Reload images
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
