import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Service for compressing images to WebP Base64 format
/// Target: < 80KB per image for Firestore storage
class ImageHelper {
  /// Compress image to WebP format and convert to Base64
  ///
  /// Settings:
  /// - Format: WebP
  /// - Quality: 50%
  /// - Max dimension: 600px
  ///
  /// Returns Base64 string (target < 80KB)
  static Future<String?> compressAndConvert(File file) async {
    try {
      // Read the file
      final fileBytes = await file.readAsBytes();

      // Compress to WebP format
      final result = await FlutterImageCompress.compressWithList(
        fileBytes,
        minWidth: 600,
        minHeight: 600,
        quality: 50,
        format: CompressFormat.webp,
      );

      // Convert to Base64
      final base64String = base64Encode(result);

      // Calculate size in KB
      final sizeInKB = (base64String.length * 3 / 4) / 1024;

      // If still too large, reduce quality further
      if (sizeInKB > 80) {
        final reducedResult = await FlutterImageCompress.compressWithList(
          fileBytes,
          minWidth: 500,
          minHeight: 500,
          quality: 30,
          format: CompressFormat.webp,
        );
        return base64Encode(reducedResult);
      }

      return base64String;
    } catch (e) {
      print('Error compressing image: $e');
      return null;
    }
  }

  /// Compress from Uint8List (useful for camera/gallery picks)
  static Future<String?> compressFromBytes(Uint8List bytes) async {
    try {
      final result = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: 600,
        minHeight: 600,
        quality: 50,
        format: CompressFormat.webp,
      );

      final base64String = base64Encode(result);
      final sizeInKB = (base64String.length * 3 / 4) / 1024;

      if (sizeInKB > 80) {
        final reducedResult = await FlutterImageCompress.compressWithList(
          bytes,
          minWidth: 500,
          minHeight: 500,
          quality: 30,
          format: CompressFormat.webp,
        );
        return base64Encode(reducedResult);
      }

      return base64String;
    } catch (e) {
      print('Error compressing image from bytes: $e');
      return null;
    }
  }

  /// Decode Base64 string back to Uint8List for display
  static Uint8List? decodeBase64(String base64String) {
    try {
      return base64Decode(base64String);
    } catch (e) {
      print('Error decoding Base64: $e');
      return null;
    }
  }

  /// Get estimated size of Base64 string in KB
  static double getBase64SizeKB(String base64String) {
    return (base64String.length * 3 / 4) / 1024;
  }
}
