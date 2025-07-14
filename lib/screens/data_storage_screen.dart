import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../core/constants.dart';
import '../services/api_service.dart';

class DataStorageScreen extends StatefulWidget {
  const DataStorageScreen({super.key});

  @override
  State<DataStorageScreen> createState() => _DataStorageScreenState();
}

class _DataStorageScreenState extends State<DataStorageScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  
  // Storage data
  double _totalStorage = 0;
  Map<String, double> _storageData = {
    'Chat Messages': 0,
    'Media Files': 0,
    'Cache': 0,
    'Profile Data': 0,
    'Documents': 0,
    'Other': 0,
  };

  // Colors for different storage types
  final Map<String, Color> _storageColors = {
    'Chat Messages': AppColors.primary,
    'Media Files': AppColors.secondary,
    'Cache': AppColors.accent,
    'Profile Data': AppColors.success,
    'Documents': AppColors.warning,
    'Other': Colors.grey,
  };

  @override
  void initState() {
    super.initState();
    _loadStorageData();
  }

  Future<void> _loadStorageData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate API call to get storage data
      // In a real app, this would call the backend
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock data for demonstration
      final random = math.Random();
      setState(() {
        _storageData = {
          'Chat Messages': 45.2 + random.nextDouble() * 20,
          'Media Files': 128.7 + random.nextDouble() * 50,
          'Cache': 23.4 + random.nextDouble() * 15,
          'Profile Data': 5.1 + random.nextDouble() * 3,
          'Documents': 12.8 + random.nextDouble() * 8,
          'Other': 8.5 + random.nextDouble() * 5,
        };
        _totalStorage = _storageData.values.fold(0, (sum, value) => sum + value);
      });
    } catch (e) {
      _showError('Failed to load storage data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'Are you sure you want to clear the cache? This will free up space but may slow down the app temporarily.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Simulate clearing cache
        await Future.delayed(const Duration(seconds: 1));
        setState(() {
          _storageData['Cache'] = 0;
          _totalStorage = _storageData.values.fold(0, (sum, value) => sum + value);
        });
        _showSuccess('Cache cleared successfully');
      } catch (e) {
        _showError('Failed to clear cache: $e');
      }
    }
  }

  Future<void> _clearMediaFiles() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Media Files'),
        content: const Text(
          'Are you sure you want to clear media files? This will permanently delete downloaded images, videos, and audio files.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear Media', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Simulate clearing media files
        await Future.delayed(const Duration(seconds: 1));
        setState(() {
          _storageData['Media Files'] = 0;
          _totalStorage = _storageData.values.fold(0, (sum, value) => sum + value);
        });
        _showSuccess('Media files cleared successfully');
      } catch (e) {
        _showError('Failed to clear media files: $e');
      }
    }
  }

  String _formatBytes(double bytes) {
    if (bytes < 1024) return '${bytes.toStringAsFixed(1)} B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  double _getPercentage(double value) {
    if (_totalStorage == 0) return 0;
    return (value / _totalStorage) * 100;
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

  Widget _buildStorageItem(String title, double size, Color color) {
    final percentage = _getPercentage(size);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatBytes(size),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onPressed,
    Color? iconColor,
    Color? backgroundColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.3),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? AppColors.primary).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor ?? AppColors.primary,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
        onTap: onPressed,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildStorageOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.storage_rounded,
                size: 32,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Storage Used',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    _formatBytes(_totalStorage),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(
                Icons.pie_chart_outline,
                size: 20,
                color: Colors.white70,
              ),
              const SizedBox(width: 8),
              const Text(
                'Storage breakdown by category',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data & Storage'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStorageData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Storage Overview
                  _buildStorageOverview(),
                  const SizedBox(height: 24),

                  // Storage Breakdown
                  Text(
                    'Storage Breakdown',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Storage items with bar charts
                  ...(_storageData.entries.map((entry) => _buildStorageItem(
                    entry.key,
                    entry.value,
                    _storageColors[entry.key] ?? Colors.grey,
                  )).toList()),

                  const SizedBox(height: 24),

                  // Management Actions
                  Text(
                    'Storage Management',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildActionButton(
                    title: 'Clear Cache',
                    subtitle: 'Free up ${_formatBytes(_storageData['Cache'] ?? 0)} of temporary files',
                    icon: Icons.cleaning_services,
                    onPressed: _clearCache,
                    iconColor: AppColors.warning,
                  ),

                  _buildActionButton(
                    title: 'Clear Media Files',
                    subtitle: 'Delete downloaded images, videos, and audio files',
                    icon: Icons.perm_media,
                    onPressed: _clearMediaFiles,
                    iconColor: AppColors.error,
                  ),

                  _buildActionButton(
                    title: 'Export Chat Data',
                    subtitle: 'Export your chat history as a backup file',
                    icon: Icons.file_download,
                    onPressed: () {
                      _showError('Export feature coming soon!');
                    },
                    iconColor: AppColors.secondary,
                  ),

                  _buildActionButton(
                    title: 'Data Usage Settings',
                    subtitle: 'Manage auto-download and data usage preferences',
                    icon: Icons.data_usage,
                    onPressed: () {
                      _showError('Data usage settings coming soon!');
                    },
                    iconColor: AppColors.primary,
                  ),

                  const SizedBox(height: 24),

                  // Info Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Storage Information',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '• Chat Messages: Text conversations and emojis\n'
                          '• Media Files: Photos, videos, and audio messages\n'
                          '• Cache: Temporary files for faster loading\n'
                          '• Profile Data: Your profile information and settings\n'
                          '• Documents: PDF files and other documents\n'
                          '• Other: Miscellaneous app data',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.primary.withOpacity(0.8),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
} 