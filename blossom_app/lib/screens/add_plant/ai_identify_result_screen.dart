import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_session.dart';
import '../../core/image_utils.dart';
import '../../models/ai_models.dart';
import '../../repositories/garden_repository.dart';
import '../../core/theme.dart';

class AiIdentifyResultScreen extends StatefulWidget {
  const AiIdentifyResultScreen({required this.args, super.key});

  final AiIdentifyResultArgs? args;

  @override
  State<AiIdentifyResultScreen> createState() => _AiIdentifyResultScreenState();
}

class _AiIdentifyResultScreenState extends State<AiIdentifyResultScreen> {
  final TextEditingController _customNameController = TextEditingController();

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _customNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args;
    if (args == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'No AI result to show.',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => context.go('/add_plant_1'),
                  child: const Text('Start again'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final result = args.result;
    final plant = result.plant;
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'AI Result',
          style: TextStyle(
            color: AppTheme.primary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: AppTheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            result.createdNewPlant
                                ? 'AI identified a new plant and added it to the shared catalog.'
                                : 'AI matched this plant to an existing catalog entry.',
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 224,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      image: DecorationImage(
                        image: CachedNetworkImageProvider(
                          resolvePlantImageUrl(plant.imagePath),
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    plant.commonName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primary,
                    ),
                  ),
                  if (plant.scientificName != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      plant.scientificName!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: AppTheme.primary.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    plant.shortDescription,
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  _buildCareItem(
                    'Water',
                    plant.waterRequirements,
                    Icons.water_drop,
                  ),
                  _buildCareItem(
                    'Light',
                    plant.lightRequirements,
                    Icons.light_mode,
                  ),
                  _buildCareItem(
                    'Temperature',
                    plant.temperature,
                    Icons.thermostat,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _customNameController,
                    decoration: InputDecoration(
                      labelText: 'Plant nickname (optional)',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  if (result.missingAnswers.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Some guided answers are missing, so add to garden is disabled.',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ],
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton(
                onPressed: result.missingAnswers.isNotEmpty || _isSaving
                    ? null
                    : () => _saveToGarden(args),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: Text(
                  _isSaving ? 'Adding...' : 'Add to my garden',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCareItem(String title, String subtitle, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  Text(subtitle),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveToGarden(AiIdentifyResultArgs args) async {
    final repository = GardenRepository(AppSessionScope.of(context));
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      final savedPlant = await repository.addPlantToGarden(
        args.draft.toGardenPayload(
          plantId: args.result.plant.id,
          customName: _customNameController.text.trim().isEmpty
              ? null
              : _customNameController.text.trim(),
          createdVia: 'ai_image_discovery',
        ),
      );
      if (!mounted) {
        return;
      }
      context.go('/garden_plant/${savedPlant.id}');
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = '$error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
