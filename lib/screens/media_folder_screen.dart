import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../core/constants.dart';
import '../services/api_service.dart';
import '../services/premium_service.dart';

class MediaFolderScreen extends StatefulWidget {
  const MediaFolderScreen({super.key});

  @override
  State<MediaFolderScreen> createState() => _MediaFolderScreenState();
}

class _MediaFolderScreenState extends State<MediaFolderScreen> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isLoading = false;
  List<File> _savedImages = [];
  List<Map<String, dynamic>> _galleryImages = [];
  List<Map<String, dynamic>> _receivedImages = [];
  
  int _selectedTabIndex = 0;
  final List<String> _tabTitles = ['Saved', 'From Gallery', 'Received'];

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _loadSavedImages();
      await _loadGalleryImages();
      await _loadReceivedImages();
    } catch (e) {
      _showError('Failed to load images: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSavedImages() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final mediaDir = Directory('${directory.path}/media');
      
      if (await mediaDir.exists()) {
        final files = await mediaDir.list().toList();
        setState(() {
          _savedImages = files
              .where((file) => file.path.toLowerCase().endsWith('.jpg') || 
                             file.path.toLowerCase().endsWith('.png') ||
                             file.path.toLowerCase().endsWith('.jpeg'))
              .cast<File>()
              .toList();
        });
      }
    } catch (e) {
      print('Error loading saved images: $e');
    }
  }

  Future<void> _loadGalleryImages() async {
    try {
      // Load images added from gallery (stored in app storage with metadata)
      final directory = await getApplicationDocumentsDirectory();
      final metadataFile = File('${directory.path}/gallery_metadata.json');
      
      if (await metadataFile.exists()) {
        // Load metadata for gallery images
        // This would contain info about images saved from gallery
        setState(() {
          _galleryImages = []; // Initialize empty for now
        });
      }
    } catch (e) {
      print('Error loading gallery images: $e');
    }
  }

  Future<void> _loadReceivedImages() async {
    try {
      // Load images received from friends
      // This would integrate with the chat system
      setState(() {
        _receivedImages = []; // Initialize empty for now
      });
    } catch (e) {
      print('Error loading received images: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    // Check if user has premium
    final hasPremium = await PremiumService.checkMediaStorage(context);
    if (!hasPremium) {
      return; // User doesn't have premium, popup already shown
    }
    
    try {
      // Request storage permission
      final status = await Permission.storage.request();
      if (status != PermissionStatus.granted) {
        _showError('Storage permission is required to access gallery');
        return;
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        await _saveImageToMediaFolder(File(image.path), 'gallery');
        await _loadImages();
        _showSuccess('Image saved to media folder!');
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _takePhoto() async {
    // Check if user has premium
    final hasPremium = await PremiumService.checkMediaStorage(context);
    if (!hasPremium) {
      return; // User doesn't have premium, popup already shown
    }
    
    try {
      // Request camera permission
      final status = await Permission.camera.request();
      if (status != PermissionStatus.granted) {
        _showError('Camera permission is required to take photos');
        return;
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        await _saveImageToMediaFolder(File(image.path), 'camera');
        await _loadImages();
        _showSuccess('Photo saved to media folder!');
      }
    } catch (e) {
      _showError('Failed to take photo: $e');
    }
  }

  Future<void> _saveImageToMediaFolder(File imageFile, String source) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final mediaDir = Directory('${directory.path}/media');
      
      if (!await mediaDir.exists()) {
        await mediaDir.create(recursive: true);
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$source.jpg';
      final savedFile = File('${mediaDir.path}/$fileName');
      
      await imageFile.copy(savedFile.path);
    } catch (e) {
      throw Exception('Failed to save image: $e');
    }
  }

  Future<void> _deleteImage(File imageFile) async {
    try {
      await imageFile.delete();
      await _loadImages();
      _showSuccess('Image deleted successfully');
    } catch (e) {
      _showError('Failed to delete image: $e');
    }
  }

  Future<void> _shareImageWithFriend(File imageFile) async {
    // TODO: Implement friend selection and image sharing
    _showError('Image sharing feature coming soon!');
  }

  void _showImageDetails(File imageFile) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.file(
                  imageFile,
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              // Actions
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      icon: Icons.share,
                      label: 'Share',
                      onPressed: () {
                        Navigator.pop(context);
                        _shareImageWithFriend(imageFile);
                      },
                    ),
                    _buildActionButton(
                      icon: Icons.delete,
                      label: 'Delete',
                      color: Colors.red,
                      onPressed: () {
                        Navigator.pop(context);
                        _confirmDelete(imageFile);
                      },
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Column(
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon, color: color ?? AppColors.primary),
          style: IconButton.styleFrom(
            backgroundColor: (color ?? AppColors.primary).withOpacity(0.1),
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color ?? AppColors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _confirmDelete(File imageFile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Image'),
        content: const Text('Are you sure you want to delete this image? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteImage(imageFile);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  Widget _buildImageGrid(List<File> images) {
    if (images.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            const SizedBox(height: 16),
            Text(
              'No images yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add images from gallery or camera',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final image = images[index];
        return GestureDetector(
          onTap: () => _showImageDetails(image),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.3),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                image,
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if user has premium for media folder access
    if (!PremiumService.hasActivePremiumFromContext(context)) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Media Folder'),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'Premium Feature',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Media folder is only available for premium users',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  PremiumService.checkMediaStorage(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('Upgrade to Premium'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Folder'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.add),
            onSelected: (value) {
              switch (value) {
                case 'gallery':
                  _pickImageFromGallery();
                  break;
                case 'camera':
                  _takePhoto();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'gallery',
                child: Row(
                  children: [
                    Icon(Icons.photo_library),
                    SizedBox(width: 8),
                    Text('From Gallery'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'camera',
                child: Row(
                  children: [
                    Icon(Icons.camera_alt),
                    SizedBox(width: 8),
                    Text('Take Photo'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: TabController(length: 3, vsync: this),
          onTap: (index) {
            setState(() {
              _selectedTabIndex = index;
            });
          },
          labelColor: AppColors.primary,
          unselectedLabelColor: Theme.of(context).textTheme.bodySmall?.color,
          indicatorColor: AppColors.primary,
          tabs: _tabTitles
              .map((title) => Tab(text: title))
              .toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _selectedTabIndex,
              children: [
                // Saved Images Tab
                _buildImageGrid(_savedImages),
                
                // Gallery Images Tab
                _galleryImages.isEmpty
                    ? _buildEmptyState(
                        'No gallery images',
                        'Images you save from your device gallery will appear here',
                        Icons.photo_library_outlined,
                      )
                    : Container(), // TODO: Build gallery images grid
                
                // Received Images Tab
                _receivedImages.isEmpty
                    ? _buildEmptyState(
                        'No received images',
                        'Images sent by your friends will be saved here automatically',
                        Icons.inbox_outlined,
                      )
                    : Container(), // TODO: Build received images grid
              ],
            ),
    );
  }
} 