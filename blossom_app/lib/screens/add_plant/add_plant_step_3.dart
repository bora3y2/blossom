import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_session.dart';
import '../../core/image_utils.dart';
import '../../models/add_plant_models.dart';
import '../../repositories/garden_repository.dart';
import '../../core/theme.dart';

class AddPlantStep3Screen extends StatefulWidget {
  const AddPlantStep3Screen({required this.selection, super.key});

  final AddPlantSelectionArgs? selection;

  @override
  State<AddPlantStep3Screen> createState() => _AddPlantStep3ScreenState();
}

class _AddPlantStep3ScreenState extends State<AddPlantStep3Screen> {
  bool _isSaving = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final selection = widget.selection;
    if (selection == null) {
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
                  'No plant was selected.',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                  textAlign: TextAlign.center,
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
    final plant = selection.plant;
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: CircleAvatar(
            backgroundColor: AppTheme.primary.withValues(alpha: 0.05),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
              onPressed: () => context.pop(),
            ),
          ),
        ),
        title: const Text(
          'Add Plant',
          style: TextStyle(
            color: AppTheme.primary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: const [
          SizedBox(width: 56), // balance leading
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildProgressDash(false),
                  const SizedBox(width: 12),
                  _buildProgressDash(false),
                  const SizedBox(width: 12),
                  _buildProgressDash(true),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: ListView(
                  children: [
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
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primary,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Care Detail for '${plant.commonName}'",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                      textAlign: TextAlign.left,
                    ),
                    const SizedBox(height: 16),
                    _buildCareItem(
                      icon: Icons.water_drop,
                      title: 'Water',
                      subtitle: plant.waterRequirements,
                    ),
                    _buildCareItem(
                      icon: Icons.light_mode,
                      title: 'Light',
                      subtitle: plant.lightRequirements,
                    ),
                    _buildCareItem(
                      icon: Icons.thermostat,
                      title: 'Temperature',
                      subtitle: plant.temperature,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.pets, color: AppTheme.primary, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            plant.petSafe
                                ? 'Safe for pets'
                                : 'Not considered pet safe',
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.redAccent),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                onPressed: _isSaving ? null : () => _savePlant(selection),
                child: Text(_isSaving ? 'Adding...' : 'Add to my garden'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePlant(AddPlantSelectionArgs selection) async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      final repository = GardenRepository(AppSessionScope.of(context));
      final savedPlant = await repository.addPlantToGarden(
        selection.draft.toGardenPayload(plantId: selection.plant.id),
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

  Widget _buildProgressDash(bool isActive) {
    return Container(
      height: 8,
      width: 48,
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.primary
            : AppTheme.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }

  Widget _buildCareItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: AppTheme.primary.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }
}
