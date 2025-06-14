import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/activity_model.dart';
import '../providers/activity_provider.dart';
import '../providers/user_provider.dart';
import '../utils/date_formatter.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/reading_list_item_widget.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  @override
  Widget build(BuildContext context) {
    final locals = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(locals.dailyActivity),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _showStatsDialog,
          ),
        ],
      ),
      body: Consumer<ActivityProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.activities.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.directions_walk,
              title: locals.noReadings,
              subtitle: locals.addReading,
              onActionPressed: _showAddActivityDialog,
            );
          }

          return Column(
            children: [
              _buildSummaryCard(provider),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.activities.length,
                  itemBuilder: (context, index) {
                    final activity = provider.activities[index];
                    return ReadingListItem(
                      icon: _getIconForActivityType(activity.type),
                      color: _getColorForActivityType(activity.type),
                      title: _getActivityTypeText(activity.type, locals),
                      subtitle: DateFormatter.formatDate(activity.date),
                      category:
                          '${activity.steps} ${locals.steps} • ${activity.calories.toStringAsFixed(0)} ${locals.calories}',
                      notes: activity.notes,
                      onEdit: () => _showEditActivityDialog(activity),
                      onDelete: () => _deleteActivity(activity.id),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddActivityDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryCard(ActivityProvider provider) {
    final locals = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final totalStepsToday = provider.getTotalStepsForPeriod(1);
    final totalCaloriesToday = provider.getTotalCaloriesForPeriod(1);
    final totalDistanceToday = provider.getTotalDistanceForPeriod(1);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              locals.today,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.directions_walk,
                    label: locals.steps,
                    value: totalStepsToday.toString(),
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.local_fire_department,
                    label: locals.calories,
                    value: totalCaloriesToday.toStringAsFixed(0),
                    color: Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.straighten,
                    label: locals.distance,
                    value: '${totalDistanceToday.toStringAsFixed(1)} km',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _showAddActivityDialog() {
    _showActivityDialog();
  }

  void _showEditActivityDialog(Activity activity) {
    _showActivityDialog(activity: activity);
  }

  void _showActivityDialog({Activity? activity}) {
    final locals = AppLocalizations.of(context)!;
    final stepsController = TextEditingController(
      text: activity?.steps.toString() ?? '',
    );
    final caloriesController = TextEditingController(
      text: activity?.calories.toString() ?? '',
    );
    final distanceController = TextEditingController(
      text: activity?.distance.toString() ?? '',
    );
    final durationController = TextEditingController(
      text: activity?.duration.toString() ?? '',
    );
    final notesController = TextEditingController(text: activity?.notes ?? '');
    DateTime selectedDate = activity?.date ?? DateTime.now();
    String activityType = activity?.type ?? 'walking';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title:
              Text(activity == null ? locals.addReading : locals.updateReading),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: activityType,
                  decoration: InputDecoration(
                    labelText: locals.exerciseType,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'walking',
                      child: Text(locals.walking),
                    ),
                    DropdownMenuItem(
                      value: 'running',
                      child: Text(locals.running),
                    ),
                    DropdownMenuItem(
                      value: 'cycling',
                      child: Text(locals.cycling),
                    ),
                    DropdownMenuItem(
                      value: 'swimming',
                      child: Text(locals.swimming),
                    ),
                    DropdownMenuItem(
                      value: 'workout',
                      child: Text(locals.workout),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      activityType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: stepsController,
                        decoration: InputDecoration(
                          labelText: locals.steps,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: caloriesController,
                        decoration: InputDecoration(
                          labelText: locals.calories,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: distanceController,
                        decoration: const InputDecoration(
                          labelText: 'Distance (km)',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: durationController,
                        decoration: InputDecoration(
                          labelText: '${locals.duration} (min)',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(locals.date),
                  subtitle: Text(DateFormatter.formatDate(selectedDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        selectedDate = date;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: '${locals.notes} (${locals.optional})',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(locals.cancel),
            ),
            ElevatedButton(
              onPressed: () => _saveActivity(
                activity,
                activityType,
                stepsController.text,
                caloriesController.text,
                distanceController.text,
                durationController.text,
                selectedDate,
                notesController.text,
              ),
              child: Text(locals.save),
            ),
          ],
        ),
      ),
    );
  }

  void _saveActivity(
    Activity? existingActivity,
    String type,
    String stepsText,
    String caloriesText,
    String distanceText,
    String durationText,
    DateTime date,
    String notes,
  ) async {
    final steps = int.tryParse(stepsText) ?? 0;
    final calories = double.tryParse(caloriesText) ?? 0.0;
    final distance = double.tryParse(distanceText) ?? 0.0;
    final duration = int.tryParse(durationText) ?? 0;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.selectedUser?.id;

    if (userId == null) return;

    final provider = Provider.of<ActivityProvider>(context, listen: false);

    try {
      if (existingActivity != null) {
        final updatedActivity = existingActivity.copyWith(
          type: type,
          steps: steps,
          calories: calories,
          distance: distance,
          duration: duration,
          date: date,
          notes: notes.isEmpty ? null : notes,
        );
        await provider.updateActivity(updatedActivity);
      } else {
        final newActivity = Activity(
          id: const Uuid().v4(),
          userId: userId,
          type: type,
          steps: steps,
          calories: calories,
          distance: distance,
          duration: duration,
          date: date,
          notes: notes.isEmpty ? null : notes,
          createdAt: DateTime.now(),
        );
        await provider.addActivity(newActivity);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(existingActivity != null
                ? 'Activity updated'
                : 'Activity added'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _deleteActivity(String activityId) async {
    final locals = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(locals.delete),
        content: const Text('Are you sure you want to delete this activity?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(locals.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(locals.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final provider = Provider.of<ActivityProvider>(context, listen: false);
        await provider.deleteActivity(activityId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Activity deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  void _showStatsDialog() {
    final locals = AppLocalizations.of(context)!;
    final provider = Provider.of<ActivityProvider>(context, listen: false);

    if (provider.activities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(locals.noReadings)),
      );
      return;
    }

    final weeklySteps = provider.getTotalStepsForPeriod(7);
    final weeklyCalories = provider.getTotalCaloriesForPeriod(7);
    final weeklyDistance = provider.getTotalDistanceForPeriod(7);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${locals.activity} Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatRow('This Week Steps:', weeklySteps.toString()),
            _buildStatRow(
                'This Week Calories:', weeklyCalories.toStringAsFixed(0)),
            _buildStatRow('This Week Distance:',
                '${weeklyDistance.toStringAsFixed(1)} km'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(locals.cancel),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  IconData _getIconForActivityType(String type) {
    switch (type) {
      case 'walking':
        return Icons.directions_walk;
      case 'running':
        return Icons.directions_run;
      case 'cycling':
        return Icons.directions_bike;
      case 'swimming':
        return Icons.pool;
      case 'workout':
        return Icons.fitness_center;
      default:
        return Icons.directions_walk;
    }
  }

  Color _getColorForActivityType(String type) {
    switch (type) {
      case 'walking':
        return Colors.blue;
      case 'running':
        return Colors.red;
      case 'cycling':
        return Colors.green;
      case 'swimming':
        return Colors.cyan;
      case 'workout':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getActivityTypeText(String type, AppLocalizations locals) {
    switch (type) {
      case 'walking':
        return locals.walking;
      case 'running':
        return locals.running;
      case 'cycling':
        return locals.cycling;
      case 'swimming':
        return locals.swimming;
      case 'workout':
        return locals.workout;
      default:
        return type;
    }
  }
}
