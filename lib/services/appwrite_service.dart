import 'package:appwrite/appwrite.dart';

/// Appwrite service for managing photo storage in documents
/// This service stores Base64 photo data in Appwrite Documents
/// to reduce Firestore storage usage
class AppwriteService {
  static final AppwriteService _instance = AppwriteService._internal();
  factory AppwriteService() => _instance;
  AppwriteService._internal();

  late Client _client;
  late Databases _databases;

  // Appwrite Configuration
  static const String _endpoint = 'https://fra.cloud.appwrite.io/v1';
  static const String _projectId = '6935585d000912ee1a86';
  static const String _databaseId = '693558df001f7968fabd';
  static const String _collectionId = 'team_task_photos';

  /// Initialize Appwrite client
  void initialize() {
    _client = Client().setEndpoint(_endpoint).setProject(_projectId);

    _databases = Databases(_client);
  }

  /// Store photo in Appwrite Documents
  ///
  /// Parameters:
  /// - teamTaskId: The team assignment ID (reference)
  /// - photoType: 'before' or 'after'
  /// - base64Data: Base64 encoded photo data (WebP format)
  ///
  /// Returns: Document ID of the stored photo
  Future<String?> storePhoto({
    required String teamTaskId,
    required String photoType, // 'before' or 'after'
    required String base64Data,
  }) async {
    try {
      // Create unique document ID: teamTaskId_photoType
      final documentId = '${teamTaskId}_$photoType';

      // Store photo data in Appwrite Documents
      final document = await _databases.createDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: documentId,
        data: {
          'teamTaskId': teamTaskId,
          'photoType': photoType,
          'base64Data': base64Data,
          'createdAt': DateTime.now().toIso8601String(),
          'sizeKB': (base64Data.length * 3 / 4) / 1024,
        },
      );

      return document.$id;
    } catch (e) {
      // If document exists, update it instead
      if (e.toString().contains(
        'Document with the requested ID already exists',
      )) {
        return await updatePhoto(
          teamTaskId: teamTaskId,
          photoType: photoType,
          base64Data: base64Data,
        );
      }

      print('Error storing photo in Appwrite: $e');
      return null;
    }
  }

  /// Update existing photo in Appwrite Documents
  Future<String?> updatePhoto({
    required String teamTaskId,
    required String photoType,
    required String base64Data,
  }) async {
    try {
      final documentId = '${teamTaskId}_$photoType';

      final document = await _databases.updateDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: documentId,
        data: {
          'base64Data': base64Data,
          'updatedAt': DateTime.now().toIso8601String(),
          'sizeKB': (base64Data.length * 3 / 4) / 1024,
        },
      );

      return document.$id;
    } catch (e) {
      print('Error updating photo in Appwrite: $e');
      return null;
    }
  }

  /// Retrieve photo from Appwrite Documents
  ///
  /// Returns: Base64 encoded photo data, or null if not found
  Future<String?> getPhoto({
    required String teamTaskId,
    required String photoType,
  }) async {
    try {
      final documentId = '${teamTaskId}_$photoType';

      final document = await _databases.getDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: documentId,
      );

      return document.data['base64Data'] as String?;
    } catch (e) {
      print('Error retrieving photo from Appwrite: $e');
      return null;
    }
  }

  /// Delete photo from Appwrite Documents
  Future<bool> deletePhoto({
    required String teamTaskId,
    required String photoType,
  }) async {
    try {
      final documentId = '${teamTaskId}_$photoType';

      await _databases.deleteDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: documentId,
      );

      return true;
    } catch (e) {
      print('Error deleting photo from Appwrite: $e');
      return false;
    }
  }

  /// Delete all photos for a team task (both before and after)
  Future<void> deleteAllPhotosForTask(String teamTaskId) async {
    await Future.wait([
      deletePhoto(teamTaskId: teamTaskId, photoType: 'before'),
      deletePhoto(teamTaskId: teamTaskId, photoType: 'after'),
    ]);
  }

  /// Get both photos for a team task
  /// Returns a map with 'before' and 'after' keys
  Future<Map<String, String?>> getBothPhotos(String teamTaskId) async {
    final results = await Future.wait([
      getPhoto(teamTaskId: teamTaskId, photoType: 'before'),
      getPhoto(teamTaskId: teamTaskId, photoType: 'after'),
    ]);

    return {'before': results[0], 'after': results[1]};
  }
}
