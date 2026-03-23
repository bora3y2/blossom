import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_session.dart';
import '../../core/image_utils.dart';
import '../../core/theme.dart';
import '../../models/garden_models.dart';
import '../../repositories/garden_repository.dart';

class GardenPlantDetailScreen extends StatefulWidget {
  const GardenPlantDetailScreen({required this.userPlantId, super.key});

  final String userPlantId;

  @override
  State<GardenPlantDetailScreen> createState() =>
      _GardenPlantDetailScreenState();
}

class _GardenPlantDetailScreenState extends State<GardenPlantDetailScreen> {
  bool _didLoad = false;
  bool _isLoading = true;
  String? _errorMessage;
  UserPlantModel? _plant;
  final Set<String> _completingTaskIds = <String>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoad) {
      return;
    }
    _didLoad = true;
    _loadPlant();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? _buildErrorState(context)
            : RefreshIndicator(
                onRefresh: _loadPlant,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 48),
                  children: [
                    _buildHeader(context),
                    if (_plant != null) ...[
                      _buildHeroImage(_plant!),
                      _buildSummary(_plant!),
                      _buildCareGuidance(_plant!),
                      _buildTaskSection(
                        title: 'Pending Tasks',
                        tasks: _pendingTasksFor(_plant!),
                        emptyLabel: 'No pending tasks for this plant.',
                        isPendingSection: true,
                      ),
                      const SizedBox(height: 24),
                      _buildTaskSection(
                        title: 'Completed Tasks',
                        tasks: _completedTasksFor(_plant!),
                        emptyLabel: 'No completed tasks yet.',
                        isPendingSection: false,
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
                return;
              }
              context.go('/my_garden');
            },
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Plant Details',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroImage(UserPlantModel plant) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: CachedNetworkImage(
            imageUrl: resolvePlantImageUrl(plant.plant.imagePath),
            fit: BoxFit.cover,
            placeholder: (context, url) =>
                const Center(child: CircularProgressIndicator()),
            errorWidget: (context, url, err) => const Icon(Icons.broken_image),
          ),
        ),
      ),
    );
  }

  Widget _buildSummary(UserPlantModel plant) {
    final pendingTasks = _pendingTasksFor(plant);
    final completedTasks = _completedTasksFor(plant);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              plant.displayName,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              plant.plant.scientificName ?? plant.plant.commonName,
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              plant.plant.shortDescription,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildStatChip(
                  icon: Icons.home_work_outlined,
                  label: plant.locationType,
                ),
                _buildStatChip(
                  icon: Icons.wb_sunny_outlined,
                  label: plant.lightCondition,
                ),
                _buildStatChip(
                  icon: Icons.schedule,
                  label: '${pendingTasks.length} pending',
                ),
                _buildStatChip(
                  icon: Icons.check_circle,
                  label: '${completedTasks.length} completed',
                ),
                _buildStatChip(
                  icon: Icons.pets,
                  label: plant.plant.petSafe ? 'Pet safe' : 'Not pet safe',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCareGuidance(UserPlantModel plant) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Care Guidance',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            _buildGuidanceRow(
              icon: Icons.water_drop,
              title: 'Water',
              body: plant.plant.waterRequirements,
            ),
            const SizedBox(height: 14),
            _buildGuidanceRow(
              icon: Icons.light_mode,
              title: 'Light',
              body: plant.plant.lightRequirements,
            ),
            const SizedBox(height: 14),
            _buildGuidanceRow(
              icon: Icons.thermostat,
              title: 'Temperature',
              body: plant.plant.temperature,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidanceRow({
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTaskSection({
    required String title,
    required List<CareTaskModel> tasks,
    required String emptyLabel,
    required bool isPendingSection,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
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
          const SizedBox(height: 16),
          if (tasks.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                emptyLabel,
                style: const TextStyle(color: Colors.black54, fontSize: 14),
              ),
            )
          else
            Column(
              children: tasks
                  .map(
                    (task) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildTaskRow(
                        task: task,
                        isPending: isPendingSection,
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskRow({required CareTaskModel task, required bool isPending}) {
    final isCompleting = _completingTaskIds.contains(task.id);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(_taskIcon(task.taskType), color: AppTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isPending
                      ? _formatDueLabel(task.dueAt)
                      : _formatCompletedLabel(task.completedAt),
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                if (task.description != null &&
                    task.description!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      task.description!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primary.withValues(alpha: 0.72),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (isPending)
            isCompleting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    onPressed: () => _completeTask(task),
                    icon: const Icon(
                      Icons.check_circle_outline,
                      color: AppTheme.primary,
                    ),
                    tooltip: 'Mark complete',
                  )
          else
            const Icon(Icons.check_circle, color: Colors.green),
        ],
      ),
    );
  }

  Widget _buildStatChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Unable to load this plant.',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPlant,
              child: const Text('Try again'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/my_garden'),
              child: const Text('Back to My Garden'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadPlant() async {
    final repository = GardenRepository(AppSessionScope.of(context));
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final plant = await repository.fetchGardenPlant(widget.userPlantId);
      if (!mounted) {
        return;
      }
      setState(() {
        _plant = plant;
      });
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
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _completeTask(CareTaskModel task) async {
    final plant = _plant;
    if (plant == null) {
      return;
    }
    final repository = GardenRepository(AppSessionScope.of(context));
    setState(() {
      _completingTaskIds.add(task.id);
    });
    try {
      final completion = await repository.completeCareTask(task.id);
      final updatedTask = completion.completedTask;
      final nextTask = completion.nextTask;
      if (!mounted) {
        return;
      }
      setState(() {
        _plant = plant.copyWith(
          careTasks: [
            ...plant.careTasks
                .map(
                  (careTask) =>
                      careTask.id == updatedTask.id ? updatedTask : careTask,
                )
                .where(
                  (careTask) => nextTask == null || careTask.id != nextTask.id,
                ),
            ...(nextTask == null
                ? const <CareTaskModel>[]
                : <CareTaskModel>[nextTask]),
          ],
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nextTask == null
                ? '${updatedTask.title} completed'
                : '${updatedTask.title} completed • next reminder scheduled',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) {
        setState(() {
          _completingTaskIds.remove(task.id);
        });
      }
    }
  }

  List<CareTaskModel> _pendingTasksFor(UserPlantModel plant) {
    final tasks = plant.careTasks.where((task) => task.isPending).toList();
    tasks.sort((first, second) {
      final firstDueAt = first.dueAt;
      final secondDueAt = second.dueAt;
      if (firstDueAt == null && secondDueAt == null) {
        return 0;
      }
      if (firstDueAt == null) {
        return 1;
      }
      if (secondDueAt == null) {
        return -1;
      }
      return firstDueAt.compareTo(secondDueAt);
    });
    return tasks;
  }

  List<CareTaskModel> _completedTasksFor(UserPlantModel plant) {
    final tasks = plant.careTasks.where((task) => !task.isPending).toList();
    tasks.sort((first, second) {
      final firstCompletedAt = first.completedAt;
      final secondCompletedAt = second.completedAt;
      if (firstCompletedAt == null && secondCompletedAt == null) {
        return 0;
      }
      if (firstCompletedAt == null) {
        return 1;
      }
      if (secondCompletedAt == null) {
        return -1;
      }
      return secondCompletedAt.compareTo(firstCompletedAt);
    });
    return tasks;
  }

  IconData _taskIcon(String taskType) {
    switch (taskType) {
      case 'water':
        return Icons.water_drop;
      case 'light':
        return Icons.light_mode;
      case 'temperature':
        return Icons.thermostat;
      case 'fertilize':
        return Icons.spa_outlined;
      default:
        return Icons.checklist;
    }
  }

  String _formatDueLabel(DateTime? dueAt) {
    if (dueAt == null) {
      return 'No due date';
    }
    final now = DateTime.now();
    final localDueAt = dueAt.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(localDueAt.year, localDueAt.month, localDueAt.day);
    final difference = dueDay.difference(today).inDays;
    final timeLabel = _formatTime(localDueAt);
    if (difference == 0) {
      return 'Due today • $timeLabel';
    }
    if (difference == 1) {
      return 'Due tomorrow • $timeLabel';
    }
    if (difference == -1) {
      return 'Overdue since yesterday • $timeLabel';
    }
    return 'Due ${localDueAt.month}/${localDueAt.day} • $timeLabel';
  }

  String _formatCompletedLabel(DateTime? completedAt) {
    if (completedAt == null) {
      return 'Completed';
    }
    final localCompletedAt = completedAt.toLocal();
    return 'Completed ${localCompletedAt.month}/${localCompletedAt.day} • ${_formatTime(localCompletedAt)}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour == 0
        ? 12
        : dateTime.hour > 12
        ? dateTime.hour - 12
        : dateTime.hour;
    final suffix = dateTime.hour >= 12 ? 'PM' : 'AM';
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute $suffix';
  }
}
