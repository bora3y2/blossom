import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/add_plant_models.dart';
import '../../models/ai_models.dart';
import '../../core/theme.dart';

class AddPlantStep1Screen extends StatefulWidget {
  const AddPlantStep1Screen({super.key});

  @override
  State<AddPlantStep1Screen> createState() => _AddPlantStep1ScreenState();
}

class _AddPlantStep1ScreenState extends State<AddPlantStep1Screen> {
  int _envIdx = -1;
  int _lightIdx = -1;
  int _careIdx = -1;
  int _petIdx = -1;

  static const List<String> _environmentOptions = ['Indoor', 'Outdoor'];
  static const List<String> _lightOptions = [
    'Low Light',
    'Indirect',
    'Direct Sunlight',
  ];
  static const List<String> _caringOptions = [
    'I\'m a bit forgetful',
    'I love caring for them daily',
  ];
  static const List<String> _petOptions = ['Yes, keep it safe', 'No pets here'];

  bool get _canContinue =>
      _envIdx >= 0 && _lightIdx >= 0 && _careIdx >= 0 && _petIdx >= 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.primary),
                    onPressed: () => context.pop(),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Blossom',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance close button
                ],
              ),
            ),
            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildProgressPill(true),
                  const SizedBox(width: 12),
                  _buildProgressPill(false),
                  const SizedBox(width: 12),
                  _buildProgressPill(false),
                ],
              ),
            ),
            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildQuestion(
                      'Where will your plant live?',
                      _environmentOptions,
                      _envIdx,
                      (v) => setState(() => _envIdx = v),
                    ),
                    const SizedBox(height: 32),
                    _buildQuestion(
                      'How much light does the spot get?',
                      _lightOptions,
                      _lightIdx,
                      (v) => setState(() => _lightIdx = v),
                    ),
                    const SizedBox(height: 32),
                    _buildQuestion(
                      'Describe your caring style',
                      _caringOptions,
                      _careIdx,
                      (v) => setState(() => _careIdx = v),
                    ),
                    const SizedBox(height: 32),
                    _buildQuestion(
                      'Is pet safety a priority?',
                      _petOptions,
                      _petIdx,
                      (v) => setState(() => _petIdx = v),
                    ),
                    const SizedBox(height: 64),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppTheme.backgroundLight,
                    AppTheme.backgroundLight.withValues(alpha: 0),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: _canContinue ? _continue : null,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Next', style: TextStyle(fontSize: 18)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _canContinue ? _identifyWithPhoto : null,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Identify from photo'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _continue() {
    final draft = _buildDraft();
    context.push('/add_plant_2', extra: draft);
  }

  void _identifyWithPhoto() {
    final draft = _buildDraft();
    context.push('/ai_identify', extra: AiIdentifyArgs(draft: draft));
  }

  AddPlantDraft _buildDraft() {
    final draft = AddPlantDraft(
      locationType: _environmentOptions[_envIdx],
      lightCondition: _lightOptions[_lightIdx],
      caringStyle: _caringOptions[_careIdx],
      petSafetyPriority: _petOptions[_petIdx],
    );
    return draft;
  }

  Widget _buildProgressPill(bool active) {
    return Container(
      width: 48,
      height: 10,
      decoration: BoxDecoration(
        color: active
            ? AppTheme.primary
            : AppTheme.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }

  Widget _buildQuestion(
    String title,
    List<String> options,
    int selectedIdx,
    Function(int) onSelect,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(options.length, (index) {
            final isSelected = selectedIdx == index;
            return GestureDetector(
              onTap: () => onSelect(index),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: isSelected ? AppTheme.primary : AppTheme.beigeAccent,
                    width: 2,
                  ),
                ),
                child: Text(
                  options[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
