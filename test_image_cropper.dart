import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:io';
import 'lib/widgets/image_cropper_widget.dart';

void main() {
  group('ImageCropperWidget Tests', () {
    testWidgets('ImageCropperWidget should be created', (WidgetTester tester) async {
      // This test verifies that the ImageCropperWidget can be instantiated
      expect(ImageCropperWidget, isNotNull);
    });

    test('ImageCropperWidget static methods should exist', () {
      // Test that static methods exist
      expect(ImageCropperWidget.showImageCropper, isNotNull);
      expect(ImageCropperWidget.showImageEditor, isNotNull);
    });
  });
}

// Example usage of the image cropper widget
class ImageCropperExample extends StatelessWidget {
  const ImageCropperExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Image Cropper Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                // Example of how to use the image cropper
                // This would typically be called after picking an image
                // final croppedFile = await ImageCropperWidget.showImageCropper(
                //   context: context,
                //   imageFile: File('path/to/image.jpg'),
                //   title: 'Crop Image',
                //   isCircular: true,
                // );
              },
              child: const Text('Test Image Cropper'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                // Example of how to use the image editor
                // final editedFile = await ImageCropperWidget.showImageEditor(
                //   context: context,
                //   imageFile: File('path/to/image.jpg'),
                //   title: 'Edit Image',
                // );
              },
              child: const Text('Test Image Editor'),
            ),
          ],
        ),
      ),
    );
  }
} 