import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../core/app_config.dart';
import '../core/app_session.dart';
import '../data/api_client.dart';
import '../models/add_plant_models.dart';
import '../models/ai_models.dart';

class AiRepository {
  AiRepository(this.session, {http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final AppSession session;
  final http.Client _httpClient;

  Future<PlantIdentificationModel> identifyPlant({
    required XFile image,
    required AddPlantDraft draft,
    bool addToGarden = false,
    String? customName,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConfig.apiBaseUrl}/ai/identify-plant'),
    );
    request.headers.addAll(_headers());
    request.fields.addAll(
      draft.toAiFields(addToGarden: addToGarden, customName: customName),
    );
    final bytes = await image.readAsBytes();
    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
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
    return PlantIdentificationModel.fromJson(decoded as Map<String, dynamic>);
  }

  Map<String, String> _headers() {
    final headers = <String, String>{'Accept': 'application/json'};
    final accessToken = session.accessToken;
    if (accessToken != null && accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }
    return headers;
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
