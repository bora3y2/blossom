import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/app_config.dart';
import '../core/app_session.dart';

class ApiClient {
  ApiClient(this.session, {http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final AppSession session;
  final http.Client _httpClient;

  Future<dynamic> getJson(String path) async {
    final response = await _httpClient.get(
      Uri.parse('${AppConfig.apiBaseUrl}$path'),
      headers: _headers(),
    );
    return _decodeResponse(response);
  }

  Future<dynamic> postJson(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('${AppConfig.apiBaseUrl}$path'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    return _decodeResponse(response);
  }

  Future<dynamic> patchJson(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    final response = await _httpClient.patch(
      Uri.parse('${AppConfig.apiBaseUrl}$path'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    return _decodeResponse(response);
  }

  Future<dynamic> deleteJson(String path) async {
    final response = await _httpClient.delete(
      Uri.parse('${AppConfig.apiBaseUrl}$path'),
      headers: _headers(),
    );
    return _decodeResponse(response);
  }

  Map<String, String> _headers() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final accessToken = session.accessToken;
    if (accessToken != null && accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }
    return headers;
  }

  dynamic _decodeResponse(http.Response response) {
    final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode >= 400) {
      final detail = decoded is Map<String, dynamic>
          ? decoded['detail']?.toString()
          : null;
      throw ApiException(
        detail ?? 'Request failed with status ${response.statusCode}',
      );
    }
    return decoded;
  }
}

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
