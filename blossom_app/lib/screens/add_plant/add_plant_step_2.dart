import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_session.dart';
import '../../core/image_utils.dart';
import '../../models/add_plant_models.dart';
import '../../models/plant_models.dart';
import '../../repositories/plant_repository.dart';
import '../../core/theme.dart';

class AddPlantStep2Screen extends StatefulWidget {
  const AddPlantStep2Screen({required this.draft, super.key});

  final AddPlantDraft? draft;

  @override
  State<AddPlantStep2Screen> createState() => _AddPlantStep2ScreenState();
}

class _AddPlantStep2ScreenState extends State<AddPlantStep2Screen> {
  late Future<List<PlantModel>> _plantsFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _plantsFuture = PlantRepository(AppSessionScope.of(context)).fetchCatalog(draft: widget.draft);
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: CircleAvatar(
            backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildProgressDash(false),
                const SizedBox(width: 12),
                _buildProgressDash(true),
                const SizedBox(width: 12),
                _buildProgressDash(false),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<PlantModel>>(
              future: _plantsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Unable to load plant suggestions.',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.primary.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _plantsFuture = PlantRepository(
                                  AppSessionScope.of(context),
                                ).fetchCatalog(draft: widget.draft);
                              });
                            },
                            child: const Text('Try again'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final plants = snapshot.data ?? const <PlantModel>[];
                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          children: [
                            const Text(
                              'Suggestions for your space',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Choose a plant that fits the conditions you selected.',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.primary.withValues(alpha: 0.6),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (draft == null) ...[
                              const SizedBox(height: 12),
                              Text(
                                'Your add-plant answers are missing. Go back and answer step 1 again.',
                                style: TextStyle(
                                  color: AppTheme.primary.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final plant = plants[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index == plants.length - 1 ? 32 : 16,
                            ),
                            child: _buildPlantCard(context, plant, draft),
                          );
                        }, childCount: plants.length),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressDash(bool isActive) {
    return Container(
      height: 6,
      width: 48,
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.primary
            : AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }

  Widget _buildPlantCard(
    BuildContext context,
    PlantModel plant,
    AddPlantDraft? draft,
  ) {
    return GestureDetector(
      onTap: draft == null
          ? null
          : () => context.push(
              '/add_plant_3',
              extra: AddPlantSelectionArgs(draft: draft, plant: plant),
            ),
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          image: DecorationImage(
            image: CachedNetworkImageProvider(
              resolvePlantImageUrl(plant.imagePath),
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                AppTheme.primary.withValues(alpha: 0.9),
                AppTheme.primary.withValues(alpha: 0.2),
                Colors.transparent,
              ],
            ),
          ),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                plant.commonName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                (plant.scientificName ?? '').toUpperCase(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Select Plant',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
