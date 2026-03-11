import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;

class CloudinaryService {
  // Cloudinary credentials – unsigned preset, no secret needed in app
  static const String _cloudName = 'drjzj4b6p';
  static const String _uploadPreset = 'humsafar_ids';

  /// Compress a single image and upload to Cloudinary.
  /// Returns the secure HTTPS URL of the uploaded image.
  Future<String> uploadIdImage({
    required File imageFile,
    required String userId,
    required String imageType,
  }) async {
    // Step A: Compress the image before uploading
    final compressed = await FlutterImageCompress.compressWithFile(
      imageFile.absolute.path,
      minWidth: 1000,
      minHeight: 700,
      quality: 75,
      format: CompressFormat.jpeg,
    );

    if (compressed == null) {
      throw Exception('Image compression failed for $imageType');
    }

    // Step B: Build the Cloudinary upload URL
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
    );

    // Step C: Build multipart request
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['folder'] = 'humsafar/users/$userId'
      ..fields['public_id'] = imageType
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          compressed,
          filename: '$imageType.jpg',
        ),
      );

    // Step D: Send and parse response
    final streamedResponse = await request.send();
    final responseBody = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode != 200) {
      debugPrint('Cloudinary upload failed ($imageType): $responseBody');
      throw Exception('Upload failed for $imageType');
    }

    final json = jsonDecode(responseBody) as Map<String, dynamic>;
    final url = json['secure_url'] as String?;

    if (url == null || url.isEmpty) {
      throw Exception('Upload succeeded but no secure_url returned for $imageType');
    }

    return url;
  }

  /// Upload all ID / document images for a user.
  ///
  /// Only non-null files are uploaded. Returned map keys:
  /// - student_card_front
  /// - student_card_back
  /// - cnic_front
  /// - cnic_back
  /// - license_front
  /// - license_back
  Future<Map<String, String>> uploadAllIdImages({
    required String userId,
    required File studentCardFront,
    required File studentCardBack,
    File? cnicFront,
    File? cnicBack,
    File? licenseFront,
    File? licenseBack,
  }) async {
    final results = <String, String>{};

    // Upload sequentially so errors are easy to track
    results['student_card_front'] = await uploadIdImage(
      imageFile: studentCardFront,
      userId: userId,
      imageType: 'student_card_front',
    );

    results['student_card_back'] = await uploadIdImage(
      imageFile: studentCardBack,
      userId: userId,
      imageType: 'student_card_back',
    );

    if (cnicFront != null) {
      results['cnic_front'] = await uploadIdImage(
        imageFile: cnicFront,
        userId: userId,
        imageType: 'cnic_front',
      );
    }

    if (cnicBack != null) {
      results['cnic_back'] = await uploadIdImage(
        imageFile: cnicBack,
        userId: userId,
        imageType: 'cnic_back',
      );
    }

    if (licenseFront != null) {
      results['license_front'] = await uploadIdImage(
        imageFile: licenseFront,
        userId: userId,
        imageType: 'license_front',
      );
    }

    if (licenseBack != null) {
      results['license_back'] = await uploadIdImage(
        imageFile: licenseBack,
        userId: userId,
        imageType: 'license_back',
      );
    }

    return results;
  }
}

