import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

class ImageUtils {
  static final ImagePicker _picker = ImagePicker();

  /// Maximum size (in KB) for any image we store in Firestore as base64.
  /// Firestore has a 1MB per-document limit, and we store multiple images,
  /// so we keep each one under ~200KB.
  static const double _maxImageSizeKB = 200;

  /// Pick an image from gallery or camera
  static Future<XFile?> pickImage({
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 60, // Initial compression from camera/gallery
      );
      return image;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// Convert image file to a *compressed* base64 string suitable for Firestore.
  ///
  /// This will:
  /// - Compress/resize the image using flutter_image_compress
  /// - Ensure the final payload is <= [_maxImageSizeKB]
  static Future<String?> imageToBase64(XFile imageFile) async {
    try {
      // Read original bytes
      final originalBytes = await imageFile.readAsBytes();
      final originalSizeKB = originalBytes.lengthInBytes / 1024;

      Uint8List compressedBytes = originalBytes;

      // If already small enough, still run through a light compression pass
      // to avoid excessively large base64 strings.
      if (originalSizeKB > _maxImageSizeKB) {
        // Start with a reasonable quality and downscale dimensions.
        int quality = 70;
        int minWidth = 1024;
        int minHeight = 1024;

        // Iteratively compress until under limit or we reach a minimum quality.
        for (var i = 0; i < 3; i++) {
          final result = await FlutterImageCompress.compressWithList(
            compressedBytes,
            quality: quality,
            minWidth: minWidth,
            minHeight: minHeight,
            format: CompressFormat.jpeg,
          );

          compressedBytes = Uint8List.fromList(result);
          final sizeKB = compressedBytes.lengthInBytes / 1024;

          if (sizeKB <= _maxImageSizeKB) {
            break;
          }

          // Reduce quality/dimensions more for the next iteration.
          quality = (quality - 15).clamp(40, 90);
          minWidth = (minWidth * 0.8).toInt();
          minHeight = (minHeight * 0.8).toInt();
        }
      } else {
        // Light single-pass compression even for small images.
        final result = await FlutterImageCompress.compressWithList(
          originalBytes,
          quality: 75,
          minWidth: 1024,
          minHeight: 1024,
          format: CompressFormat.jpeg,
        );
        compressedBytes = Uint8List.fromList(result);
      }

      final base64String = base64Encode(compressedBytes);
      return base64String;
    } catch (e) {
      debugPrint('Error converting image to base64: $e');
      return null;
    }
  }

  /// Convert base64 string to image bytes
  static Uint8List? base64ToImage(String base64String) {
    try {
      return base64Decode(base64String);
    } catch (e) {
      debugPrint('Error decoding base64 image: $e');
      return null;
    }
  }

  /// Get image size in KB
  static Future<double> getImageSizeKB(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      return bytes.lengthInBytes / 1024;
    } catch (e) {
      debugPrint('Error getting image size: $e');
      return 0;
    }
  }
}
