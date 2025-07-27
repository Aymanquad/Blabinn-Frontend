import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'dart:typed_data';

class SimpleImageCropper {
  static Future<File?> showImageCropper({
    required BuildContext context,
    required File imageFile,
    String? title,
    bool isCircular = true,
  }) async {
    return showDialog<File?>(
      context: context,
      barrierDismissible: false,
      builder: (context) => SimpleCropperDialog(
        imageFile: imageFile,
        title: title ?? 'Crop Image',
        isCircular: isCircular,
      ),
    );
  }

  static Future<File?> showImageEditor({
    required BuildContext context,
    required File imageFile,
    String? title,
  }) async {
    return showDialog<File?>(
      context: context,
      barrierDismissible: false,
      builder: (context) => SimpleEditorDialog(
        imageFile: imageFile,
        title: title ?? 'Edit Image',
      ),
    );
  }
}

class SimpleCropperDialog extends StatefulWidget {
  final File imageFile;
  final String title;
  final bool isCircular;

  const SimpleCropperDialog({
    Key? key,
    required this.imageFile,
    required this.title,
    required this.isCircular,
  }) : super(key: key);

  @override
  State<SimpleCropperDialog> createState() => _SimpleCropperDialogState();
}

class _SimpleCropperDialogState extends State<SimpleCropperDialog> {
  late File _currentImage;
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _currentImage = widget.imageFile;
  }

  Future<void> _cropImage() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Read the image
      final bytes = await _currentImage.readAsBytes();
      var image = img.decodeImage(bytes);
      
      if (image == null) return;

      // Simple cropping implementation
      // For now, we'll just return the original image
      // In a full implementation, you would apply the crop based on _scale and _offset
      
      // Encode the processed image
      final processedBytes = img.encodeJpg(image, quality: 80);
      
      // Save to temporary file
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/cropped_image_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(processedBytes);

      setState(() {
        _currentImage = tempFile;
        _isProcessing = false;
      });

      Navigator.of(context).pop(tempFile);
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cropping image: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _isProcessing ? null : _cropImage,
                    child: const Text(
                      'Crop',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _isProcessing
                      ? const Center(child: CircularProgressIndicator())
                      : InteractiveViewer(
                          child: Image.file(
                            _currentImage,
                            fit: BoxFit.contain,
                          ),
                        ),
                ),
              ),
            ),
            
            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                widget.isCircular 
                    ? 'Pinch to zoom and pan to position your image for circular cropping'
                    : 'Pinch to zoom and pan to position your image for cropping',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SimpleEditorDialog extends StatefulWidget {
  final File imageFile;
  final String title;

  const SimpleEditorDialog({
    Key? key,
    required this.imageFile,
    required this.title,
  }) : super(key: key);

  @override
  State<SimpleEditorDialog> createState() => _SimpleEditorDialogState();
}

class _SimpleEditorDialogState extends State<SimpleEditorDialog> {
  late File _currentImage;
  double _rotation = 0.0;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _currentImage = widget.imageFile;
  }

  Future<void> _applyRotation() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Read the image
      final bytes = await _currentImage.readAsBytes();
      var image = img.decodeImage(bytes);
      
      if (image == null) return;

      // Apply rotation
      if (_rotation != 0) {
        image = img.copyRotate(image, angle: _rotation.toInt());
      }

      // Encode the processed image
      final processedBytes = img.encodeJpg(image, quality: 80);
      
      // Save to temporary file
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/edited_image_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(processedBytes);

      setState(() {
        _currentImage = tempFile;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing image: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _isProcessing ? null : () {
                      Navigator.of(context).pop(_currentImage);
                    },
                    child: const Text(
                      'Done',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: Column(
                children: [
                  // Image preview
                  Expanded(
                    flex: 3,
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _isProcessing
                            ? const Center(child: CircularProgressIndicator())
                            : Image.file(
                                _currentImage,
                                fit: BoxFit.contain,
                              ),
                      ),
                    ),
                  ),
                  
                  // Controls
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Adjustments',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Rotation
                          _buildSliderControl(
                            label: 'Rotation',
                            value: _rotation,
                            min: -180,
                            max: 180,
                            divisions: 36,
                            onChanged: (value) {
                              setState(() {
                                _rotation = value;
                              });
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Action buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isProcessing ? null : _applyRotation,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: _isProcessing
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Text('Apply Rotation'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _rotation = 0.0;
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Reset'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  Widget _buildSliderControl({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(value.toStringAsFixed(1)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
} 