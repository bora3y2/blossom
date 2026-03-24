class PlantModel {
  PlantModel({
    required this.id,
    required this.commonName,
    required this.scientificName,
    required this.shortDescription,
    required this.imagePath,
    required this.waterRequirements,
    required this.lightRequirements,
    required this.temperature,
    required this.petSafe,
    required this.locationType,
    required this.caringDifficulty,
  });

  final String id;
  final String commonName;
  final String? scientificName;
  final String shortDescription;
  final String? imagePath;
  final String waterRequirements;
  final String lightRequirements;
  final String temperature;
  final bool petSafe;
  final String locationType;
  final String caringDifficulty;

  factory PlantModel.fromJson(Map<String, dynamic> json) {
    return PlantModel(
      id: json['id'] as String,
      commonName: json['common_name'] as String,
      scientificName: json['scientific_name'] as String?,
      shortDescription: (json['short_description'] as String?) ?? '',
      imagePath: json['image_path'] as String?,
      waterRequirements: json['water_requirements'] as String,
      lightRequirements: json['light_requirements'] as String,
      temperature: json['temperature'] as String,
      petSafe: json['pet_safe'] as bool? ?? false,
      locationType: (json['location_type'] as String?) ?? 'Both',
      caringDifficulty: (json['caring_difficulty'] as String?) ?? 'low',
    );
  }
}

class AddPlantQuestionModel {
  AddPlantQuestionModel({
    required this.key,
    required this.title,
    required this.options,
  });

  final String key;
  final String title;
  final List<String> options;

  factory AddPlantQuestionModel.fromJson(Map<String, dynamic> json) {
    return AddPlantQuestionModel(
      key: json['key'] as String,
      title: json['title'] as String,
      options: (json['options'] as List<dynamic>).cast<String>(),
    );
  }
}

class PlantAddFlowModel {
  PlantAddFlowModel({required this.questions});

  final List<AddPlantQuestionModel> questions;

  factory PlantAddFlowModel.fromJson(Map<String, dynamic> json) {
    return PlantAddFlowModel(
      questions: (json['questions'] as List<dynamic>)
          .map(
            (item) =>
                AddPlantQuestionModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}
