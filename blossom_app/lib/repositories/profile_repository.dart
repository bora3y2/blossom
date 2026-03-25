import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../core/app_config.dart';
import '../core/app_session.dart';
import '../data/api_client.dart';
import '../models/profile_models.dart';

class ProfileRepository {
  ProfileRepository(this.session, {http.Client? httpClient})
    : _apiClient = ApiClient(session),
      _httpClient = httpClient ?? http.Client();

  final AppSession session;
  final ApiClient _apiClient;
  final http.Client _httpClient;

  Future<ProfileModel> fetchMyProfile() async {
    final data =
        await _apiClient.getJson('/profiles/me') as Map<String, dynamic>;
    return ProfileModel.fromJson(data);
  }

  Future<ProfileModel> updateMyProfile({
    String? displayName,
    String? avatarPath,
    bool? notificationsEnabled,
    int? countryId,
    int? stateId,
  }) async {
    final body = <String, dynamic>{};
    if (displayName != null) {
      body['display_name'] = displayName;
    }
    if (avatarPath != null) {
      body['avatar_path'] = avatarPath;
    }
    if (notificationsEnabled != null) {
      body['notifications_enabled'] = notificationsEnabled;
    }
    if (countryId != null) {
      body['country_id'] = countryId;
    }
    if (stateId != null) {
      body['state_id'] = stateId;
    }
    final data =
        await _apiClient.patchJson('/profiles/me', body: body)
            as Map<String, dynamic>;
    return ProfileModel.fromJson(data);
  }

  Future<void> deleteAccount() async {
    await _apiClient.deleteJson('/profiles/me');
  }

  Future<ProfileModel> updateAvatar(XFile image) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConfig.apiBaseUrl}/profiles/me/avatar'),
    );
    final headers = <String, String>{'Accept': 'application/json'};
    final accessToken = session.accessToken;
    if (accessToken != null && accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }
    request.headers.addAll(headers);

    final bytes = await image.readAsBytes();
    request.files.add(
      http.MultipartFile.fromBytes(
        'file', // MUST match FastAPI `UploadFile = File(...)` parameter name
        bytes,
        filename: image.name,
        contentType: _resolveMediaType(image),
      ),
    );

    final streamedResponse = await _httpClient.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    final decoded = response.body.isEmpty
        ? null
        : jsonDecode(response.body) as dynamic;

    if (response.statusCode >= 400) {
      final detail = decoded is Map<String, dynamic>
          ? decoded['detail']?.toString()
          : null;
      throw ApiException(
        detail ?? 'Request failed with status ${response.statusCode}',
      );
    }

    return ProfileModel.fromJson(decoded as Map<String, dynamic>);
  }

  MediaType _resolveMediaType(XFile image) {
    final extension = image.name.contains('.')
        ? image.name.split('.').last.toLowerCase()
        : '';
    switch (extension) {
      case 'png':
        return MediaType('image', 'png');
      case 'webp':
        return MediaType('image', 'webp');
      case 'heic':
        return MediaType('image', 'heic');
      case 'heif':
        return MediaType('image', 'heif');
      default:
        return MediaType('image', 'jpeg');
    }
  }
}
