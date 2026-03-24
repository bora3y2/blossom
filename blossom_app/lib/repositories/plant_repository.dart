import '../core/app_session.dart';
import '../data/api_client.dart';
import '../models/add_plant_models.dart';
import '../models/plant_models.dart';

class PlantRepository {
  PlantRepository(this.session) : _apiClient = ApiClient(session);

  final AppSession session;
  final ApiClient _apiClient;

  Future<PlantAddFlowModel> fetchAddFlow() async {
    final data =
        await _apiClient.getJson('/plants/add-flow') as Map<String, dynamic>;
    return PlantAddFlowModel.fromJson(data);
  }

  Future<List<PlantModel>> fetchCatalog({AddPlantDraft? draft}) async {
    final queryParams = <String, String>{};

    if (draft != null) {
      final locationType = draft.locationType;
      if (locationType != null) {
        queryParams['location_type'] = locationType;
      }
      final lightCondition = draft.lightCondition;
      if (lightCondition != null) {
        queryParams['light_condition'] = lightCondition;
      }
      final caringStyle = draft.caringStyle;
      if (caringStyle != null) {
        queryParams['caring_style'] = caringStyle;
      }
      if (draft.petSafetyPriority == 'Yes, keep it safe') {
        queryParams['pet_safe_only'] = 'true';
      }
    }

    final path = queryParams.isEmpty
        ? '/plants/catalog'
        : '/plants/catalog?${Uri(queryParameters: queryParams).query}';

    final data = await _apiClient.getJson(path) as List<dynamic>;
    return data
        .map((item) => PlantModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
