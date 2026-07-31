import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:telvo/config/app_config.dart';

class ApiService {
  factory ApiService() => _instance;
  ApiService._internal();
  static final ApiService _instance = ApiService._internal();

  final String baseUrl = AppConfig.apiBaseUrl;

  Future<Map<String, String>> _authHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    final token = await user?.getIdToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$endpoint'),
      headers: await _authHeaders(),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: await _authHeaders(),
      body: body != null ? json.encode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> uploadFile(
    String endpoint, {
    required File file,
    String? folder,
    String? fileName,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/$endpoint'));
    final headers = await _authHeaders();
    headers.remove('Content-Type');
    request.headers.addAll(headers);

    if (folder != null) {
      request.fields['folder'] = folder;
    }

    if (fileName != null) {
      request.fields['fileName'] = fileName;
    }

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
        filename: fileName ?? file.uri.pathSegments.last,
      ),
    );

    final streamedResponse = await request.send();
    final responseBody = await streamedResponse.stream.bytesToString();
    final response = http.Response(
      responseBody,
      streamedResponse.statusCode,
      headers: streamedResponse.headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> uploadImage({
    required File file,
    String? folder,
    String? fileName,
  }) async => uploadFile(
    'uploads/image',
    file: file,
    folder: folder,
    fileName: fileName,
  );

  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$endpoint'),
      headers: await _authHeaders(),
      body: body != null ? json.encode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$endpoint'),
      headers: await _authHeaders(),
    );
    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      throw Exception('API Error: ${response.statusCode} - ${response.body}');
    }
  }

  // AI Service APIs
  Future<Map<String, dynamic>> estimateCost(
    Map<String, dynamic> params,
  ) async => post('ai/estimate-cost', body: params);

  Future<Map<String, dynamic>> diagnoseImage(String imageBase64) async =>
      post('ai/diagnose', body: {'image': imageBase64});

  Future<Map<String, dynamic>> recommendProfessionals(
    Map<String, dynamic> params,
  ) async => post('ai/recommend', body: params);

  Future<Map<String, dynamic>> translateMessage(
    String message,
    String targetLanguage,
  ) async => post(
    'ai/translate',
    body: {'message': message, 'language': targetLanguage},
  );

  Future<Map<String, dynamic>> summarizeChat(
    List<Map<String, dynamic>> messages,
  ) async => post('ai/summarize', body: {'messages': messages});

  // Payment Service APIs
  Future<Map<String, dynamic>> processPayment(
    Map<String, dynamic> paymentData,
  ) async => post('payments/process', body: paymentData);

  Future<Map<String, dynamic>> getPaymentStatus(String paymentId) async =>
      get('payments/$paymentId');

  // Notification APIs - recipient/content is re-derived server-side from
  // the job record, never trusted from client-supplied fields (see
  // backend/src/controllers/notificationController.js#triggerJobEvent).
  Future<Map<String, dynamic>> triggerJobEventNotification(
    Map<String, dynamic> eventData,
  ) async => post('notifications/job-event', body: eventData);
}
