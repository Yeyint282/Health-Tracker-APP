import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/blood_sugar_model.dart'; // Ensure this model has a 'category' field
import '../providers/blood_sugar_provider.dart';
import '../providers/user_provider.dart'; // This provider must contain the User model with 'hasDiabetes'
import '../utils/date_formatter.dart';
import '../widgets/chart_widget.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/reading_list_item_widget.dart';
// Make sure this is 'reading_list_item_widget.dart'

class BloodSugarScreen extends StatefulWidget {
  const BloodSugarScreen({super.key});

  @override
  State<BloodSugarScreen> createState() => _BloodSugarScreenState();
}

class _BloodSugarScreenState extends State<BloodSugarScreen> {
  String _selectedMeasurementType = 'random';

  @override
  Widget build(BuildContext context) {
    final locals = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(locals.bloodSugar),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _showChartDialog,
          ),
        ],
      ),
      body: Consumer<BloodSugarProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.readings.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.water_drop,
              title: locals.noReadings,
              subtitle: locals.addReading,
              onActionPressed: _showAddReadingDialog,
            );
          }

          return Column(
            children: [
              _buildSummaryCard(provider),
              _buildFilterChips(),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.readings.length,
                  itemBuilder: (context, index) {
                    final reading = provider.readings[index];
                    return ReadingListItem(
                      icon: Icons.water_drop,
                      color: _getColorForCategory(reading.category),
                      title:
                          '${reading.glucose.toStringAsFixed(0)} ${locals.mgdL}',
                      subtitle: DateFormatter.formatDateTime(reading.dateTime),
                      category:
                          '${_getMeasurementTypeText(reading.measurementType, locals)} - ${_getCategoryText(reading.category, locals)}',
                      notes: reading.notes,
                      onEdit: () => _showEditReadingDialog(reading),
                      onDelete: () => _deleteReading(reading.id),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddReadingDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryCard(BloodSugarProvider provider) {
    final locals = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final latestReading = provider.latestReading;

    if (latestReading == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              locals.lastReading,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.water_drop,
                  color: _getColorForCategory(latestReading.category),
                  size: 32,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${latestReading.glucose.toStringAsFixed(0)} ${locals.mgdL}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _getCategoryText(latestReading.category, locals),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _getColorForCategory(latestReading.category),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  DateFormatter.formatDate(latestReading.dateTime),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final locals = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildMeasurementTypeChip('random', locals.random),
          const SizedBox(width: 8),
          _buildMeasurementTypeChip('fasting', 'Fasting'),
          const SizedBox(width: 8),
          _buildMeasurementTypeChip('postMeal', 'Post Meal'),
        ],
      ),
    );
  }

  Widget _buildMeasurementTypeChip(String type, String label) {
    final isSelected = _selectedMeasurementType == type;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedMeasurementType = selected ? type : 'random';
        });
      },
    );
  }

  void _showAddReadingDialog() {
    _showReadingDialog();
  }

  void _showEditReadingDialog(BloodSugar reading) {
    _showReadingDialog(reading: reading);
  }

  void _showReadingDialog({BloodSugar? reading}) {
    final locals = AppLocalizations.of(context)!;
    final glucoseController = TextEditingController(
      text: reading?.glucose.toString() ?? '',
    );
    final notesController = TextEditingController(text: reading?.notes ?? '');
    DateTime selectedDateTime = reading?.dateTime ?? DateTime.now();
    String measurementType = reading?.measurementType ?? 'random';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title:
              Text(reading == null ? locals.addReading : locals.updateReading),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: glucoseController,
                  decoration: InputDecoration(
                    labelText: locals.bloodSugar,
                    suffixText: locals.mgdL,
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: measurementType,
                  decoration: const InputDecoration(
                    labelText: 'Measurement Type',
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'random',
                      child: Text(locals.random),
                    ),
                    const DropdownMenuItem(
                      value: 'fasting',
                      child: Text('Fasting'),
                    ),
                    const DropdownMenuItem(
                      value: 'postMeal',
                      child: Text('Post Meal'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      measurementType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(locals.date),
                  subtitle: Text(DateFormatter.formatDate(selectedDateTime)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDateTime,
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        selectedDateTime = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          selectedDateTime.hour,
                          selectedDateTime.minute,
                        );
                      });
                    }
                  },
                ),
                ListTile(
                  title: Text(locals.time),
                  subtitle: Text(DateFormatter.formatTime(selectedDateTime)),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                    );
                    if (time != null) {
                      setState(() {
                        selectedDateTime = DateTime(
                          selectedDateTime.year,
                          selectedDateTime.month,
                          selectedDateTime.day,
                          time.hour,
                          time.minute,
                        );
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
              onPressed: () => _saveReading(
                reading,
                glucoseController.text,
                measurementType,
                selectedDateTime,
                notesController.text,
              ),
              child: Text(locals.save),
            ),
          ],
        ),
      ),
    );
  }

  void _saveReading(
    BloodSugar? existingReading,
    String glucoseText,
    String measurementType,
    DateTime dateTime,
    String notes,
  ) async {
    final glucose = double.tryParse(glucoseText);

    if (glucose == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid number')),
      );
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.selectedUser?.id;
    final userAge = userProvider.selectedUser?.age;
    final userHasDiabetes =
        userProvider.selectedUser?.hasDiabetes; // Get user's diabetes status

    if (userId == null || userAge == null) {
      // Handle case where user or age is not available
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User information not available')),
      );
      return;
    }

    // Determine the category based on glucose, measurement type, user's age, and diabetes status
    final category = _getCategoryFromGlucose(
        glucose, measurementType, userAge, userHasDiabetes);

    final provider = Provider.of<BloodSugarProvider>(context, listen: false);

    try {
      if (existingReading != null) {
        final updatedReading = existingReading.copyWith(
          glucose: glucose,
          measurementType: measurementType,
          dateTime: dateTime,
          notes: notes.isEmpty ? null : notes,
          category: category, // Update category
        );
        await provider.updateReading(updatedReading);
      } else {
        final newReading = BloodSugar(
          id: const Uuid().v4(),
          userId: userId,
          glucose: glucose,
          measurementType: measurementType,
          dateTime: dateTime,
          notes: notes.isEmpty ? null : notes,
          createdAt: DateTime.now(),
          category: category, // Set category
        );
        await provider.addReading(newReading);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                existingReading != null ? 'Reading updated' : 'Reading added'),
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

  // New helper function to determine blood sugar category
  String _getCategoryFromGlucose(
      double glucose, String measurementType, int userAge, bool? hasDiabetes) {
    // If hasDiabetes is null, we'll treat them as non-diabetic by default.
    final isDiabetic = hasDiabetes ?? false;

    if (measurementType == 'fasting') {
      // Fasting Blood Sugar Levels
      if (userAge >= 6 && userAge <= 12) {
        // Children
        if (glucose >= 70 && glucose <= 100) return 'normal';
        if (glucose > 100 && glucose <= 125)
          return 'prediabetes'; // Assuming prediabetes range
        if (glucose > 125) return 'diabetes';
      } else if (userAge >= 13 && userAge <= 19) {
        // Teens
        if (glucose >= 70 && glucose <= 105) return 'normal';
        if (glucose > 105 && glucose <= 125)
          return 'prediabetes'; // Assuming prediabetes range
        if (glucose > 125) return 'diabetes';
      } else if (userAge >= 20 && userAge <= 64) {
        // Adults
        if (glucose >= 70 && glucose <= 99) return 'normal';
        if (glucose > 99 && glucose <= 125)
          return 'prediabetes'; // Assuming prediabetes range
        if (glucose > 125) return 'diabetes';
      } else if (userAge >= 65) {
        // Seniors
        if (glucose >= 80 && glucose <= 120) return 'normal';
        if (glucose > 120 && glucose <= 125)
          return 'prediabetes'; // Assuming prediabetes range
        if (glucose > 125) return 'diabetes';
      }
      // Fallback for fasting if age range not explicitly covered or outside defined normal
      // Or if it's below the normal range for fasting, it could be 'low'.
      if (glucose < 70) return 'low';
      return 'high'; // If it falls out of defined normal, it's generally a concern.
    } else if (measurementType == 'postMeal') {
      // Post-meal (2 hours after meal) Blood Sugar Levels
      if (isDiabetic) {
        // For people with diabetes (Type 1 or Type 2) - American Diabetes Association (ADA) target
        // Goal: generally < 180 mg/dL (2 hours after meal)
        if (glucose < 80)
          return 'low'; // Optionally add a 'low' category for post-meal if too low
        if (glucose >= 80 && glucose < 180)
          return 'normal'; // Normal for diabetics after meal
        if (glucose >= 180 && glucose < 250)
          return 'elevated'; // Elevated but not critical
        if (glucose >= 250) return 'high'; // Significantly high
      } else {
        // For non-diabetics
        // Goal: generally < 140 mg/dL (2 hours after meal)
        if (glucose < 70) return 'low'; // Could be too low
        if (glucose >= 70 && glucose < 140) return 'normal';
        if (glucose >= 140 && glucose <= 199)
          return 'prediabetes'; // Indicates prediabetes if consistently high post-meal
        if (glucose >= 200)
          return 'diabetes'; // A single reading >=200 post-meal can indicate diabetes
      }
    } else {
      // Random Blood Sugar Levels (without regard to meal times)
      // General guidelines for non-fasting, non-specific readings
      if (glucose < 70) return 'low'; // Generally too low
      if (glucose >= 70 && glucose < 140) return 'normal';
      if (glucose >= 140 && glucose <= 199)
        return 'elevated'; // Elevated, but not necessarily diabetes
      if (glucose >= 200) return 'high'; // Potentially high/diabetes
    }
    return 'unknown'; // Default if none of the conditions are met
  }

  void _deleteReading(String readingId) async {
    final locals = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(locals.delete),
        content: Text(locals.confirmDeleteUser),
        // This might be better as locals.confirmDeleteReading
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
        final provider =
            Provider.of<BloodSugarProvider>(context, listen: false);
        await provider.deleteReading(readingId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reading deleted')),
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

  void _showChartDialog() {
    final locals = AppLocalizations.of(context)!;
    final provider = Provider.of<BloodSugarProvider>(context, listen: false);

    if (provider.readings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(locals.noReadings)),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(16),
          height: 400,
          child: Column(
            children: [
              Text(
                '${locals.bloodSugar} ${locals.viewCharts}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ChartWidget(
                  readings: provider.readings
                      .map((r) => ChartData(
                            date: r.dateTime,
                            glucose: r.glucose,
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(locals.cancel),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColorForCategory(String category) {
    switch (category) {
      case 'normal':
        return Colors.green;
      case 'prediabetes': // New category for pre-diabetes range
        return Colors.orange;
      case 'elevated': // Keep elevated for non-fasting elevated
        return Colors.orange;
      case 'diabetes': // New category for diabetes
        return Colors.red;
      case 'high': // Keep high for generic high, or use diabetes specifically
        return Colors.red;
      case 'low': // For low blood sugar
        return Colors.blue; // Or another distinct color like purple/indigo
      default:
        return Colors.grey;
    }
  }

  String _getCategoryText(String category, AppLocalizations locals) {
    switch (category) {
      case 'normal':
        return locals.normal;
      case 'prediabetes': // New text for pre-diabetes
        return locals.prediabetes ??
            'Prediabetes'; // Add to AppLocalizations if needed
      case 'elevated':
        return locals.elevated;
      case 'diabetes': // New text for diabetes
        return locals.diabetes ??
            'Diabetes'; // Add to AppLocalizations if needed
      case 'high':
        return locals.high;
      case 'low': // New text for low blood sugar
        return locals.low ?? 'Low'; // Add to AppLocalizations if needed
      default:
        return category;
    }
  }

  String _getMeasurementTypeText(String type, AppLocalizations locals) {
    switch (type) {
      case 'random':
        return locals.random;
      case 'fasting':
        return 'Fasting';
      case 'postMeal':
        return 'Post Meal';
      default:
        return type;
    }
  }
}
