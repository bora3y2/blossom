import 'plant_models.dart';

class CareTaskModel {
  CareTaskModel({
    required this.id,
    required this.userPlantId,
    required this.title,
    required this.description,
    required this.taskType,
    required this.dueAt,
    required this.completedAt,
    required this.isEnabled,
  });

  final String id;
  final String userPlantId;
  final String title;
  final String? description;
  final String taskType;
  final DateTime? dueAt;
  final DateTime? completedAt;
  final bool isEnabled;

  bool get isPending => isEnabled && completedAt == null;

  CareTaskModel copyWith({
    String? id,
    String? userPlantId,
    String? title,
    String? description,
    String? taskType,
    DateTime? dueAt,
    DateTime? completedAt,
    bool? isEnabled,
  }) {
    return CareTaskModel(
      id: id ?? this.id,
      userPlantId: userPlantId ?? this.userPlantId,
      title: title ?? this.title,
      description: description ?? this.description,
      taskType: taskType ?? this.taskType,
      dueAt: dueAt ?? this.dueAt,
      completedAt: completedAt ?? this.completedAt,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  factory CareTaskModel.fromJson(Map<String, dynamic> json) {
    return CareTaskModel(
      id: json['id'] as String,
      userPlantId: json['user_plant_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      taskType: json['task_type'] as String,
      dueAt: json['due_at'] == null
          ? null
          : DateTime.parse(json['due_at'] as String),
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
      isEnabled: json['is_enabled'] as bool? ?? true,
    );
  }
}

class CareTaskCompletionModel {
  CareTaskCompletionModel({
    required this.completedTask,
    required this.nextTask,
  });

  final CareTaskModel completedTask;
  final CareTaskModel? nextTask;

  factory CareTaskCompletionModel.fromJson(Map<String, dynamic> json) {
    return CareTaskCompletionModel(
      completedTask: CareTaskModel.fromJson(
        json['completed_task'] as Map<String, dynamic>,
      ),
      nextTask: json['next_task'] == null
          ? null
          : CareTaskModel.fromJson(json['next_task'] as Map<String, dynamic>),
    );
  }
}

class UserPlantModel {
  UserPlantModel({
    required this.id,
    required this.customName,
    required this.locationType,
    required this.lightCondition,
    required this.caringStyle,
    required this.petSafetyPriority,
    required this.createdVia,
    required this.plant,
    required this.careTasks,
  });

  final String id;
  final String? customName;
  final String locationType;
  final String lightCondition;
  final String caringStyle;
  final String petSafetyPriority;
  final String createdVia;
  final PlantModel plant;
  final List<CareTaskModel> careTasks;

  String get displayName {
    final normalizedCustomName = customName?.trim();
    if (normalizedCustomName != null && normalizedCustomName.isNotEmpty) {
      return normalizedCustomName;
    }
    return plant.commonName;
  }

  UserPlantModel copyWith({
    String? id,
    String? customName,
    String? locationType,
    String? lightCondition,
    String? caringStyle,
    String? petSafetyPriority,
    String? createdVia,
    PlantModel? plant,
    List<CareTaskModel>? careTasks,
  }) {
    return UserPlantModel(
      id: id ?? this.id,
      customName: customName ?? this.customName,
      locationType: locationType ?? this.locationType,
      lightCondition: lightCondition ?? this.lightCondition,
      caringStyle: caringStyle ?? this.caringStyle,
      petSafetyPriority: petSafetyPriority ?? this.petSafetyPriority,
      createdVia: createdVia ?? this.createdVia,
      plant: plant ?? this.plant,
      careTasks: careTasks ?? this.careTasks,
    );
  }

  factory UserPlantModel.fromJson(Map<String, dynamic> json) {
    return UserPlantModel(
      id: json['id'] as String,
      customName: json['custom_name'] as String?,
      locationType: json['location_type'] as String,
      lightCondition: json['light_condition'] as String,
      caringStyle: json['caring_style'] as String,
      petSafetyPriority: json['pet_safety_priority'] as String,
      createdVia: json['created_via'] as String,
      plant: PlantModel.fromJson(json['plant'] as Map<String, dynamic>),
      careTasks: (json['care_tasks'] as List<dynamic>? ?? const [])
          .map((item) => CareTaskModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
