import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:telvo/config/app_config.dart';
import 'package:telvo/utils/error_messages.dart';
import 'package:telvo/utils/helpers.dart';

/// Uploads files directly to Firebase Storage (no backend API needed).
/// This avoids the `ClientException: SocketException` caused by the
/// unreachable `api.telvo.com` host.
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> _uploadToFirebaseStorage({
    required String folder,
    required String fileName,
    required File file,
  }) async {
    final ref = _storage.ref().child('$folder/$fileName');
    await ref.putFile(
      file,
      SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'public,max-age=31536000',
      ),
    );
    return await ref.getDownloadURL();
  }

  /// Uploads a [File] directly to Firebase Storage and returns the public
  /// download URL. Accepts a plain [File] (not just [XFile]) so it can be
  /// used from AuthProvider/ProfilePhotoPicker which pass a file path.
  Future<String?> uploadFileDirect({
    required File file,
    required String folder,
    String? fileName,
  }) async {
    try {
      final hasInternet = await Helpers.checkInternetConnection();
      if (!hasInternet) {
        throw const SocketException('No internet connection');
      }

      final cloudName = AppConfig.cloudinaryCloudName;
      final uploadPreset = AppConfig.cloudinaryUploadPreset;
      if (cloudName.isNotEmpty && uploadPreset.isNotEmpty) {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload'),
        );
        request.fields['upload_preset'] = uploadPreset;
        request.fields['folder'] = folder;
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            file.path,
            filename: fileName ?? file.uri.pathSegments.last,
          ),
        );
        final response = await request.send();
        final body = await response.stream.bytesToString();
        if (response.statusCode >= 200 && response.statusCode < 300) {
          final json = jsonDecode(body) as Map<String, dynamic>;
          return json['secure_url'] as String?;
        }
      }

      final ref = _storage.ref().child('$folder/$fileName');
      await ref.putFile(
        file,
        SettableMetadata(
          contentType: 'image/jpeg',
          cacheControl: 'public,max-age=31536000',
        ),
      );
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception(getFriendlyErrorMessage(e));
    }
  }

  /// Uploads a profile photo and returns the public download URL.
  Future<String?> uploadProfilePhoto(String userId, XFile image) async {
    try {
      return await _uploadToFirebaseStorage(
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
      return await _uploadToFirebaseStorage(
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
      return await _uploadToFirebaseStorage(
        file: File(image.path),
        folder: 'portfolio_photos/$userId',
        fileName: '$index.jpg',
      );
    } catch (_) {
      return null;
    }
  }

  /// Uploads a chat attachment image.
  Future<String?> uploadChatImage(String chatId, XFile image) async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${image.name.replaceAll(RegExp(r'[^a-zA-Z0-9.]'), '_')}';
      return await _uploadToFirebaseStorage(
        file: File(image.path),
        folder: 'chat_images/$chatId',
        fileName: fileName,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteFile(String pathToDelete) async {
    try {
      await _storage.ref(pathToDelete).delete();
    } catch (_) {
      // Ignore deletion failures
    }
  }

  Future<void> deleteUserFolder(String userId) async {
    try {
      final listResult = await _storage.ref('profile_photos').listAll();
      for (final item in listResult.items) {
        if (item.name.contains(userId)) {
          await item.delete();
        }
      }
    } catch (_) {
      // Ignore errors
    }
  }

  Future<String> getDownloadUrl(String pathToFile) async {
    try {
      return await _storage.ref(pathToFile).getDownloadURL();
    } catch (_) {
      return '';
    }
  }
}