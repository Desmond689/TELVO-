import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:telvo/config/firebase_config.dart';
import 'package:telvo/services/api_service.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseConfig.storage;

  Future<String?> uploadProfilePhoto(String userId, XFile image) async {
    try {
      final file = File(image.path);
      final response = await ApiService().uploadImage(
        file: file,
        folder: 'profile_photos',
        fileName: '$userId.jpg',
      );

      final uploadedUrl = response['data']?['url'] ?? response['url'];
      if (uploadedUrl is String && uploadedUrl.isNotEmpty) {
        return uploadedUrl;
      }
    } catch (_) {}

    try {
      final ref = _storage.ref().child('profile_photos').child('$userId.jpg');

      await ref.putFile(File(image.path));
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<String?> uploadJobPhoto(String jobId, XFile image, int index) async {
    try {
      final file = File(image.path);
      final response = await ApiService().uploadImage(
        file: file,
        folder: 'job_photos/$jobId',
        fileName: '$index.jpg',
      );

      final uploadedUrl = response['data']?['url'] ?? response['url'];
      if (uploadedUrl is String && uploadedUrl.isNotEmpty) {
        return uploadedUrl;
      }
    } catch (_) {}

    try {
      final ref = _storage
          .ref()
          .child('job_photos')
          .child(jobId)
          .child('$index.jpg');

      await ref.putFile(File(image.path));
      return await ref.getDownloadURL();
    } catch (e) {
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
      final file = File(image.path);
      final response = await ApiService().uploadImage(
        file: file,
        folder: 'portfolio_photos/$userId',
        fileName: '$index.jpg',
      );

      final uploadedUrl = response['data']?['url'] ?? response['url'];
      if (uploadedUrl is String && uploadedUrl.isNotEmpty) {
        return uploadedUrl;
      }
    } catch (_) {}

    try {
      final ref = _storage
          .ref()
          .child('portfolio_photos')
          .child(userId)
          .child('$index.jpg');

      await ref.putFile(File(image.path));
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteFile(String path) async {
    try {
      final ref = _storage.ref().child(path);
      await ref.delete();
    } catch (e) {
      // File might not exist
    }
  }

  Future<void> deleteUserFolder(String userId) async {
    try {
      final ref = _storage.ref().child('profile_photos').child('$userId.jpg');
      await ref.delete();
    } catch (e) {
      // File might not exist
    }
  }

  Future<String> getDownloadUrl(String path) async {
    try {
      final ref = _storage.ref().child(path);
      return await ref.getDownloadURL();
    } catch (e) {
      return '';
    }
  }
}
