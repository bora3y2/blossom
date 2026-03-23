import '../core/app_session.dart';
import '../data/api_client.dart';
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

  Future<List<PlantModel>> fetchCatalog() async {
    final data = await _apiClient.getJson('/plants/catalog') as List<dynamic>;
    return data
        .map((item) => PlantModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
