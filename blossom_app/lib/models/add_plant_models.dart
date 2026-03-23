import 'plant_models.dart';

class AddPlantDraft {
  const AddPlantDraft({
    this.locationType,
    this.lightCondition,
    this.caringStyle,
    this.petSafetyPriority,
  });

  final String? locationType;
  final String? lightCondition;
  final String? caringStyle;
  final String? petSafetyPriority;

  bool get isComplete =>
      locationType != null &&
      lightCondition != null &&
      caringStyle != null &&
      petSafetyPriority != null;

  Map<String, String> toAiFields({
    bool addToGarden = false,
    String? customName,
  }) {
    final fields = <String, String>{
      'add_to_garden': addToGarden ? 'true' : 'false',
    };
    if (locationType != null) {
      fields['location_type'] = locationType!;
    }
    if (lightCondition != null) {
      fields['light_condition'] = lightCondition!;
    }
    if (caringStyle != null) {
      fields['caring_style'] = caringStyle!;
    }
    if (petSafetyPriority != null) {
      fields['pet_safety_priority'] = petSafetyPriority!;
    }
    final normalizedCustomName = customName?.trim();
    if (normalizedCustomName != null && normalizedCustomName.isNotEmpty) {
      fields['custom_name'] = normalizedCustomName;
    }
    return fields;
  }

  Map<String, dynamic> toGardenPayload({
    required String plantId,
    String? customName,
    String createdVia = 'manual',
  }) {
    return {
      'plant_id': plantId,
      'custom_name': customName,
      'location_type': locationType,
      'light_condition': lightCondition,
      'caring_style': caringStyle,
      'pet_safety_priority': petSafetyPriority,
      'created_via': createdVia,
    };
  }
}

class AddPlantSelectionArgs {
  const AddPlantSelectionArgs({required this.draft, required this.plant});

  final AddPlantDraft draft;
  final PlantModel plant;
}
