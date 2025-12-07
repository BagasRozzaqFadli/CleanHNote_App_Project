import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:cleanhnote/services/appwrite_service.dart';

/// Service for compressing images and managing photo storage
///
/// Photos are compressed to WebP format and stored in Appwrite Documents as Base64
/// to avoid exceeding Firestore's 1MB document limit
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

  /// Upload photo to Appwrite Documents
  ///
  /// This method compresses the image and uploads it to Appwrite,
  /// avoiding Firestore's 1MB document limit
  ///
  /// Returns: Appwrite document ID if successful, null otherwise
  static Future<String?> uploadPhotoToAppwrite({
    required File file,
    required String teamTaskId,
    required String photoType, // 'before' or 'after'
  }) async {
    try {
      // Compress image
      final base64Data = await compressAndConvert(file);
      if (base64Data == null) {
        print('Failed to compress image');
        return null;
      }

      // Upload to Appwrite
      final docId = await AppwriteService().storePhoto(
        teamTaskId: teamTaskId,
        photoType: photoType,
        base64Data: base64Data,
      );

      return docId;
    } catch (e) {
      print('Error uploading photo to Appwrite: $e');
      return null;
    }
  }

  /// Retrieve photo from Appwrite Documents
  ///
  /// Returns: Uint8List for displaying the image, or null if not found
  static Future<Uint8List?> getPhotoFromAppwrite({
    required String teamTaskId,
    required String photoType,
  }) async {
    try {
      final base64Data = await AppwriteService().getPhoto(
        teamTaskId: teamTaskId,
        photoType: photoType,
      );

      if (base64Data == null) return null;

      return decodeBase64(base64Data);
    } catch (e) {
      print('Error retrieving photo from Appwrite: $e');
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
