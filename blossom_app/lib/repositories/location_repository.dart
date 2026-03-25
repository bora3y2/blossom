import '../core/app_session.dart';
import '../data/api_client.dart';
import '../models/location_models.dart';

class LocationRepository {
  LocationRepository(AppSession session) : _apiClient = ApiClient(session);

  final ApiClient _apiClient;

  Future<List<CountryModel>> fetchCountries() async {
    final data = await _apiClient.getJson('/location/countries') as List<dynamic>;
    return data
        .map((e) => CountryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<StateModel>> fetchStates(int countryId) async {
    final data = await _apiClient.getJson(
      '/location/countries/$countryId/states',
    ) as List<dynamic>;
    return data
        .map((e) => StateModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<WeatherModel> fetchCurrentWeather(int stateId) async {
    final data = await _apiClient.getJson(
      '/weather/current?state_id=$stateId',
    ) as Map<String, dynamic>;
    return WeatherModel.fromJson(data);
  }
}
