import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/app_session.dart';
import '../data/api_client.dart';
import '../models/garden_models.dart';
import '../services/notification_service.dart';

class GardenRepository {
  GardenRepository(this.session) : _apiClient = ApiClient(session);

  final AppSession session;
  final ApiClient _apiClient;

  Future<UserPlantModel> addPlantToGarden(Map<String, dynamic> payload) async {
    final data =
        await _apiClient.postJson('/garden/plants', body: payload)
            as Map<String, dynamic>;
    return UserPlantModel.fromJson(data);
  }

  Future<List<UserPlantModel>> fetchMyGarden() async {
    try {
      final data = await _apiClient.getJson('/garden/plants') as List<dynamic>;

      final box = Hive.box<String>('garden_cache');
      await box.put('my_garden', jsonEncode(data));

      final plants = data
          .map((item) => UserPlantModel.fromJson(item as Map<String, dynamic>))
          .toList();

      for (var plant in plants) {
        final pendingWaterTask = plant.careTasks
            .where((t) => t.isPending && t.taskType == 'water')
            .firstOrNull;
        if (pendingWaterTask?.dueAt != null) {
          notificationService.scheduleWateringReminder(
            plantId: plant.id,
            plantName: plant.displayName,
            nextWaterDate: pendingWaterTask!.dueAt!,
          );
        }
      }

      return plants;
    } catch (e) {
      final box = Hive.box<String>('garden_cache');
      final cachedStr = box.get('my_garden');
      if (cachedStr != null) {
        final data = jsonDecode(cachedStr) as List<dynamic>;
        return data
            .map(
              (item) => UserPlantModel.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      }
      rethrow;
    }
  }

  Future<UserPlantModel> fetchGardenPlant(String userPlantId) async {
    final data =
        await _apiClient.getJson('/garden/plants/$userPlantId')
            as Map<String, dynamic>;
    return UserPlantModel.fromJson(data);
  }

  Future<CareTaskCompletionModel> completeCareTask(String taskId) async {
    final data =
        await _apiClient.postJson(
              '/garden/tasks/$taskId/complete',
              body: <String, dynamic>{},
            )
            as Map<String, dynamic>;
    return CareTaskCompletionModel.fromJson(data);
  }
}
