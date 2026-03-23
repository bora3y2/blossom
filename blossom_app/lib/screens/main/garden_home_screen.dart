import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_session.dart';
import '../../core/image_utils.dart';
import '../../models/garden_models.dart';
import '../../repositories/garden_repository.dart';
import '../../core/theme.dart';

class GardenHomeScreen extends StatefulWidget {
  const GardenHomeScreen({super.key});

  @override
  State<GardenHomeScreen> createState() => _GardenHomeScreenState();
}

class _GardenHomeScreenState extends State<GardenHomeScreen> {
  bool _didLoad = false;
  bool _isLoading = true;
  String? _errorMessage;
  List<UserPlantModel> _plants = const [];
  final Set<String> _completingTaskIds = <String>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoad) {
      return;
    }
    _didLoad = true;
    _loadGarden();
  }

  @override
  Widget build(BuildContext context) {
    final tasks = _upcomingTasks();
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? _buildErrorState()
            : RefreshIndicator(
                onRefresh: _loadGarden,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(
                    bottom: 120,
                  ), // Space for floating nav
                  children: [
                    _buildHeader(context, tasks.length),
                    const SizedBox(height: 16),
                    _buildQuickActions(context),
                    const SizedBox(height: 32),
                    if (_plants.isEmpty)
                      _buildEmptyState(context)
                    else ...[
                      _buildGardenOverview(),
                      const SizedBox(height: 32),
                      _buildDailyTasks(tasks),
                      const SizedBox(height: 32),
                      _buildRecentPlants(context),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int pendingTasksCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatHeaderDate(DateTime.now()).toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppTheme.primary.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.local_florist,
                    size: 16,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_plants.length} plants',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '|',
                    style: TextStyle(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$pendingTasksCount tasks due',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              context.push('/add_plant_1');
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: AppTheme.primary, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/add_plant_1'),
              child: _buildActionCard(
                'Add\nPlant',
                Icons.add_circle_outline,
                'https://images.unsplash.com/photo-1485909645661-8e05c8680d28?q=80&w=600&auto=format&fit=crop',
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/my_garden'),
              child: _buildActionCard(
                'My\nGarden',
                Icons.local_florist,
                'https://images.unsplash.com/photo-1416879598553-300fb2246b8d?q=80&w=600&auto=format&fit=crop',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, String imageUrl) {
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
            image: CachedNetworkImageProvider(imageUrl),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGardenOverview() {
    final indoorCount = _plants
        .where((plant) => plant.locationType == 'Indoor')
        .length;
    final outdoorCount = _plants
        .where((plant) => plant.locationType == 'Outdoor')
        .length;
    final aiCount = _plants
        .where((plant) => plant.createdVia == 'ai_image_discovery')
        .length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Garden Overview',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildOverviewCard(
                  label: 'Indoor',
                  value: indoorCount.toString(),
                  icon: Icons.chair_alt,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOverviewCard(
                  label: 'Outdoor',
                  value: outdoorCount.toString(),
                  icon: Icons.wb_sunny_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOverviewCard(
                  label: 'AI Added',
                  value: aiCount.toString(),
                  icon: Icons.auto_awesome,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primary),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.primary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyTasks(List<_UpcomingTask> tasks) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Daily Tasks',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              Text(
                '${tasks.length} TASKS REMAINING',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (tasks.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'No pending care tasks yet. Add more plants and Blossom will create reminders for you.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
            )
          else
            ...tasks
                .take(3)
                .map(
                  (task) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildTaskItem(task),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(_UpcomingTask upcomingTask) {
    final task = upcomingTask.task;
    final plant = upcomingTask.plant;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primary.withValues(alpha: 0.1),
            ),
            child: Icon(_taskIcon(task.taskType), color: AppTheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${plant.displayName} • ${_formatDueLabel(task.dueAt)}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                if (task.description != null &&
                    task.description!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      task.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primary.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _completingTaskIds.contains(task.id)
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
                ),
        ],
      ),
    );
  }

  Widget _buildRecentPlants(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Recently Added',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            itemCount: _plants.take(5).length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final plant = _plants[index];
              return GestureDetector(
                onTap: () => context.push('/garden_plant/${plant.id}'),
                child: _buildRecentPlantCard(plant),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentPlantCard(UserPlantModel userPlant) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: CachedNetworkImageProvider(
            resolvePlantImageUrl(userPlant.plant.imagePath),
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withValues(alpha: 0.75), Colors.transparent],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              userPlant.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${userPlant.locationType} • ${userPlant.careTasks.length} tasks',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppTheme.primary.withValues(alpha: 0.08),
              child: const Icon(
                Icons.eco_outlined,
                color: AppTheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your garden is empty',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your first plant to unlock care tasks and a personalized garden dashboard.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.push('/add_plant_1'),
              child: const Text('Add your first plant'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Unable to load your garden dashboard.',
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
              onPressed: _loadGarden,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadGarden() async {
    final repository = GardenRepository(AppSessionScope.of(context));
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final plants = await repository.fetchMyGarden();
      if (!mounted) {
        return;
      }
      setState(() {
        _plants = plants;
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

  List<_UpcomingTask> _upcomingTasks() {
    final tasks = <_UpcomingTask>[];
    for (final plant in _plants) {
      for (final task in plant.careTasks) {
        if (!task.isPending) {
          continue;
        }
        tasks.add(_UpcomingTask(plant: plant, task: task));
      }
    }
    tasks.sort((first, second) {
      final firstDueAt = first.task.dueAt;
      final secondDueAt = second.task.dueAt;
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

  Future<void> _completeTask(CareTaskModel task) async {
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
        _plants = _plants
            .map(
              (plant) => plant.id == updatedTask.userPlantId
                  ? plant.copyWith(
                      careTasks: [
                        ...plant.careTasks
                            .map(
                              (careTask) => careTask.id == updatedTask.id
                                  ? updatedTask
                                  : careTask,
                            )
                            .where(
                              (careTask) =>
                                  nextTask == null ||
                                  careTask.id != nextTask.id,
                            ),
                        ...(nextTask == null
                            ? const <CareTaskModel>[]
                            : <CareTaskModel>[nextTask]),
                      ],
                    )
                  : plant,
            )
            .toList();
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

  String _formatHeaderDate(DateTime dateTime) {
    const weekdays = <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${weekdays[dateTime.weekday - 1]}, ${months[dateTime.month - 1]} ${dateTime.day}';
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
      return 'Today • $timeLabel';
    }
    if (difference == 1) {
      return 'Tomorrow • $timeLabel';
    }
    if (difference == -1) {
      return 'Yesterday • $timeLabel';
    }
    return '${localDueAt.month}/${localDueAt.day} • $timeLabel';
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

class _UpcomingTask {
  const _UpcomingTask({required this.plant, required this.task});

  final UserPlantModel plant;
  final CareTaskModel task;
}
