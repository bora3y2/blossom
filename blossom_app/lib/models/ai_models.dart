import 'add_plant_models.dart';
import 'garden_models.dart';
import 'plant_models.dart';

class PlantIdentificationModel {
  PlantIdentificationModel({
    required this.plant,
    required this.matchedExisting,
    required this.createdNewPlant,
    required this.gardenItem,
    required this.missingAnswers,
    required this.nextQuestions,
    required this.usedAnswers,
    required this.inputMode,
    required this.provider,
    required this.rawResult,
  });

  final PlantModel plant;
  final bool matchedExisting;
  final bool createdNewPlant;
  final UserPlantModel? gardenItem;
  final List<String> missingAnswers;
  final List<AddPlantQuestionModel> nextQuestions;
  final Map<String, String> usedAnswers;
  final String inputMode;
  final String provider;
  final Map<String, dynamic> rawResult;

  bool get canAddToGarden => gardenItem == null && missingAnswers.isEmpty;

  factory PlantIdentificationModel.fromJson(Map<String, dynamic> json) {
    return PlantIdentificationModel(
      plant: PlantModel.fromJson(json['plant'] as Map<String, dynamic>),
      matchedExisting: json['matched_existing'] as bool? ?? false,
      createdNewPlant: json['created_new_plant'] as bool? ?? false,
      gardenItem: json['garden_item'] == null
          ? null
          : UserPlantModel.fromJson(
              json['garden_item'] as Map<String, dynamic>,
            ),
      missingAnswers: (json['missing_answers'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      nextQuestions: (json['next_questions'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                AddPlantQuestionModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      usedAnswers: (json['used_answers'] as Map<String, dynamic>? ?? const {})
          .map((key, value) => MapEntry(key, value.toString())),
      inputMode: json['input_mode'] as String? ?? 'image_only',
      provider: json['provider'] as String? ?? 'unknown',
      rawResult: json['raw_result'] as Map<String, dynamic>? ?? const {},
    );
  }
}

class AiIdentifyArgs {
  const AiIdentifyArgs({required this.draft});

  final AddPlantDraft draft;
}

class AiIdentifyResultArgs {
  const AiIdentifyResultArgs({required this.draft, required this.result});

  final AddPlantDraft draft;
  final PlantIdentificationModel result;
}
