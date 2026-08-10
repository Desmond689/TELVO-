import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:telvo/config/app_config.dart';
import 'package:telvo/utils/error_messages.dart';
import 'package:telvo/utils/helpers.dart';

/// Uses Cloudinary for all image uploads. Firebase Storage is intentionally not
/// used for profile, job, or chat media uploads.
class StorageService {
  /// Maximum accepted upload size. image_picker already downsamples photos
  /// (maxWidth/maxHeight/imageQuality), but we still guard here since this
  /// is the single chokepoint every upload path (profile, job, portfolio,
  /// chat) goes through, and a picked file could come from a non-picker
  /// source in the future.
  static const int maxUploadBytes = 10 * 1024 * 1024; // 10 MB

  static const Set<String> _allowedExtensions = {
    'jpg', 'jpeg', 'png', 'webp', 'heic', 'heif',
  };

  /// Validates a file before it's sent to Cloudinary. Throws a friendly,
  /// user-facing [Exception] (via [getFriendlyErrorMessage]-compatible
  /// messages) if the file is missing, empty, too large, or not an
  /// image-like extension. Called before every upload so bad input fails
  /// fast with a clear message instead of surfacing as a vague network or
  /// "Invalid image data" error later.
  Future<void> _validateImageFile(File file) async {
    if (!await file.exists()) {
      throw Exception('Selected file could not be found. Please try again.');
    }

    final length = await file.length();
    if (length <= 0) {
      throw Exception('That file appears to be empty. Please choose another photo.');
    }
    if (length > maxUploadBytes) {
      throw Exception('That photo is too large (max 10MB). Please choose a smaller photo.');
    }

    final ext = file.path.split('.').last.toLowerCase();
    if (!_allowedExtensions.contains(ext)) {
      throw Exception('Unsupported file type. Please choose a JPG, PNG, or WEBP photo.');
    }
  }

  Future<String> _uploadToCloudinary({
    required String folder,
    required String fileName,
    required File file,
  }) async {
    final cloudName = AppConfig.cloudinaryCloudName;
    final uploadPreset = AppConfig.cloudinaryUploadPreset;
    if (cloudName.isEmpty || uploadPreset.isEmpty) {
      throw Exception(
        'Cloudinary is not configured. Add CLOUDINARY_CLOUD_NAME and CLOUDINARY_UPLOAD_PRESET in your environment.',
      );
    }

    await _validateImageFile(file);

    const int maxAttempts = 3;
    int attempt = 0;
    while (true) {
      attempt++;
      try {
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
            filename: fileName,
          ),
        );

        // Timeout the upload to avoid hanging indefinitely
        final streamedResponse = await request.send().timeout(const Duration(seconds: 60));
        final body = await streamedResponse.stream.bytesToString();
        if (streamedResponse.statusCode < 200 || streamedResponse.statusCode >= 300) {
          if (const bool.fromEnvironment('dart.vm.product') == false) {
            // ignore: avoid_print
            print('Cloudinary upload HTTP ${streamedResponse.statusCode}: $body');
            print('Upload URL: https://api.cloudinary.com/v1_1/$cloudName/image/upload');
            print('Upload preset: $uploadPreset');
            print('Folder: $folder, fileName: $fileName');
          }
          throw Exception('Cloudinary upload failed: ${streamedResponse.statusCode}');
        }

        final json = jsonDecode(body) as Map<String, dynamic>;
        final url = json['secure_url'] as String?;
        if (url == null || url.isEmpty) {
          if (const bool.fromEnvironment('dart.vm.product') == false) {
            // ignore: avoid_print
            print('Cloudinary response but no secure_url: $body');
          }
          throw Exception('Cloudinary returned no secure URL');
        }
        return url;
      } catch (e) {
        // If last attempt, rethrow a detailed error. Otherwise, wait and retry.
        if (attempt >= maxAttempts) {
          final message = getFriendlyErrorMessage(e);
          if (const bool.fromEnvironment('dart.vm.product') == false) {
            // ignore: avoid_print
            print('Cloudinary upload failed after $attempt attempts: $e');
            print('Attempted upload to https://api.cloudinary.com/v1_1/$cloudName/image/upload with preset $uploadPreset');
          }
          throw Exception(message);
        }
        // Exponential backoff before retrying
        final backoff = Duration(seconds: 1 << (attempt - 1));
        await Future.delayed(backoff);
      }
    }
  }

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
      return await _uploadToCloudinary(
        file: file,
        folder: folder,
        fileName: fileName ?? file.uri.pathSegments.last,
      );
    } catch (e) {
      throw Exception(getFriendlyErrorMessage(e));
    }
  }

  Future<String?> uploadProfilePhoto(String userId, XFile image) async {
    try {
      return await _uploadToCloudinary(
        file: File(image.path),
        folder: 'profile_photos',
        fileName: '$userId.jpg',
      );
    } catch (e) {
      // Surface the actual error for debugging instead of silently returning null
      final msg = getFriendlyErrorMessage(e);
      // Keep the old behavior for callers expecting null on failure, but log the detailed error
      // to help diagnose Cloudinary misconfiguration or network issues.
      // In debug builds print stack trace as well.
      if (const bool.fromEnvironment('dart.vm.product') == false) {
        // ignore: avoid_print
        print('uploadProfilePhoto error: $e');
      }
      throw Exception(msg);
    }
  }

  Future<String?> uploadJobPhoto(String jobId, XFile image, int index) async {
    try {
      return await _uploadToCloudinary(
        file: File(image.path),
        folder: 'job_photos/$jobId',
        fileName: '$index.jpg',
      );
    } catch (e) {
      if (const bool.fromEnvironment('dart.vm.product') == false) {
        // ignore: avoid_print
        print('uploadJobPhoto error (jobId=$jobId, index=$index): $e');
      }
      throw Exception(getFriendlyErrorMessage(e));
    }
  }

  Future<List<String>> uploadJobPhotos(String jobId, List<XFile> images) async {
    final urls = <String>[];
    for (int i = 0; i < images.length; i++) {
      // uploadJobPhoto now throws on failure — allow the exception to bubble so callers can handle it
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
      return await _uploadToCloudinary(
        file: File(image.path),
        folder: 'portfolio_photos/$userId',
        fileName: '$index.jpg',
      );
    } catch (e) {
      if (const bool.fromEnvironment('dart.vm.product') == false) {
        // ignore: avoid_print
        print('uploadPortfolioPhoto error (userId=$userId, index=$index): $e');
      }
      throw Exception(getFriendlyErrorMessage(e));
    }
  }

  Future<String?> uploadChatImage(String chatId, XFile image) async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${image.name.replaceAll(RegExp(r'[^a-zA-Z0-9.]'), '_')}';
      return await _uploadToCloudinary(
        file: File(image.path),
        folder: 'chat_images/$chatId',
        fileName: fileName,
      );
    } catch (e) {
      if (const bool.fromEnvironment('dart.vm.product') == false) {
        // ignore: avoid_print
        print('uploadChatImage error (chatId=$chatId): $e');
      }
      throw Exception(getFriendlyErrorMessage(e));
    }
  }

  Future<void> deleteFile(String pathToDelete) async {
    return;
  }

  Future<void> deleteUserFolder(String userId) async {
    return;
  }

  Future<String> getDownloadUrl(String pathToFile) async {
    return pathToFile;
  }
}