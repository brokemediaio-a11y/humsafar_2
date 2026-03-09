import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class ImageUtils {
  static final ImagePicker _picker = ImagePicker();

  /// Pick an image from gallery or camera
  static Future<XFile?> pickImage({
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 70, // Reduce quality to save space
      );
      return image;
    } catch (e) {
      return null;
    }
  }

  /// Convert image file to base64 string
  static Future<String?> imageToBase64(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64String = base64Encode(bytes);
      return base64String;
    } catch (e) {
      return null;
    }
  }

  /// Convert base64 string to image bytes
  static Uint8List? base64ToImage(String base64String) {
    try {
      return base64Decode(base64String);
    } catch (e) {
      return null;
    }
  }

  /// Get image size in KB
  static Future<double> getImageSizeKB(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      return bytes.length / 1024;
    } catch (e) {
      return 0;
    }
  }
}

