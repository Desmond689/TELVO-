import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:telvo/services/api_service.dart';

class StorageService {
  Future<String?> _uploadViaBackend({
    required String folder,
    required String fileName,
    required File file,
  }) async {
    final response = await ApiService().uploadImage(
      file: file,
      folder: folder,
      fileName: fileName,
    );

    final uploadedUrl = response['data']?['url'] ?? response['url'];
    if (uploadedUrl is String && uploadedUrl.isNotEmpty) {
      return uploadedUrl;
    }
    return null;
  }

  Future<String?> uploadProfilePhoto(String userId, XFile image) async {
    try {
      return await _uploadViaBackend(
        file: File(image.path),
        folder: 'profile_photos',
        fileName: '$userId.jpg',
      );
    } catch (_) {
      return null;
    }
  }

  Future<String?> uploadJobPhoto(String jobId, XFile image, int index) async {
    try {
      return await _uploadViaBackend(
        file: File(image.path),
        folder: 'job_photos/$jobId',
        fileName: '$index.jpg',
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<String>> uploadJobPhotos(String jobId, List<XFile> images) async {
    final urls = <String>[];
    for (int i = 0; i < images.length; i++) {
      final url = await uploadJobPhoto(jobId, images[i], i);
      if (url != null) {
        urls.add(url);
      }
    }
    return urls;
  }

  Future<String?> uploadPortfolioPhoto(
    String userId,
    XFile image,
    int index,
  ) async {
    try {
      return await _uploadViaBackend(
        file: File(image.path),
        folder: 'portfolio_photos/$userId',
        fileName: '$index.jpg',
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteFile(String path) async {
    // Deletion via backend or Cloudinary API would need a server endpoint.
    // Firebase Storage deletion is intentionally not used here because uploads
    // should go through the backend Cloudinary route.
  }

  Future<void> deleteUserFolder(String userId) async {
    // Cloudinary folder deletion is not implemented in the mobile client.
  }

  Future<String> getDownloadUrl(String path) async {
    // Cloudinary URLs are returned directly by the backend; no client-side
    // download URL fetch is needed.
    return '';
  }
}
