import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/blood_pressure_model.dart';
import '../providers/blood_pressure_provider.dart';
import '../providers/user_provider.dart';
import '../utils/date_formatter.dart';
import '../widgets/chart_widget.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/reading_list_item_widget.dart';

class BloodPressureScreen extends StatefulWidget {
  const BloodPressureScreen({super.key});

  @override
  State<BloodPressureScreen> createState() => _BloodPressureScreenState();
}

class _BloodPressureScreenState extends State<BloodPressureScreen> {
  @override
  Widget build(BuildContext context) {
    final locals = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(locals.bloodPressure),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _showChartDialog,
          ),
        ],
      ),
      body: Consumer<BloodPressureProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.readings.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.favorite,
              title: locals.noReadings,
              subtitle: locals.addReading,
              onActionPressed: _showAddReadingDialog,
            );
          }

          return Column(
            children: [
              _buildSummaryCard(provider),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.readings.length,
                  itemBuilder: (context, index) {
                    final reading = provider.readings[index];
                    return ReadingListItem(
                      icon: Icons.favorite,
                      color: _getColorForCategory(reading.category),
                      title:
                          '${reading.systolic}/${reading.diastolic} ${locals.mmHg}',
                      subtitle: DateFormatter.formatDateTime(reading.dateTime),
                      category: _getCategoryText(reading.category, locals),
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

  Widget _buildSummaryCard(BloodPressureProvider provider) {
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
                  Icons.favorite,
                  color: _getColorForCategory(latestReading.category),
                  size: 32,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${latestReading.systolic}/${latestReading.diastolic} ${locals.mmHg}',
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

  void _showAddReadingDialog() {
    _showReadingDialog();
  }

  void _showEditReadingDialog(BloodPressure reading) {
    _showReadingDialog(reading: reading);
  }

  void _showReadingDialog({BloodPressure? reading}) {
    final locals = AppLocalizations.of(context)!;
    final systolicController = TextEditingController(
      text: reading?.systolic.toString() ?? '',
    );
    final diastolicController = TextEditingController(
      text: reading?.diastolic.toString() ?? '',
    );
    final notesController = TextEditingController(text: reading?.notes ?? '');
    DateTime selectedDateTime = reading?.dateTime ?? DateTime.now();

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
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: systolicController,
                        decoration: InputDecoration(
                          labelText: locals.systolic,
                          suffixText: locals.mmHg,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: diastolicController,
                        decoration: InputDecoration(
                          labelText: locals.diastolic,
                          suffixText: locals.mmHg,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
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
                systolicController.text,
                diastolicController.text,
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
    BloodPressure? existingReading,
    String systolicText,
    String diastolicText,
    DateTime dateTime,
    String notes,
  ) async {
    final systolic = int.tryParse(systolicText);
    final diastolic = int.tryParse(diastolicText);

    if (systolic == null || diastolic == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid numbers')),
      );
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.selectedUser?.id;

    if (userId == null) return;

    final provider = Provider.of<BloodPressureProvider>(context, listen: false);

    try {
      if (existingReading != null) {
        final updatedReading = existingReading.copyWith(
          systolic: systolic,
          diastolic: diastolic,
          dateTime: dateTime,
          notes: notes.isEmpty ? null : notes,
        );
        await provider.updateReading(updatedReading);
      } else {
        final newReading = BloodPressure(
          id: const Uuid().v4(),
          userId: userId,
          systolic: systolic,
          diastolic: diastolic,
          dateTime: dateTime,
          notes: notes.isEmpty ? null : notes,
          createdAt: DateTime.now(),
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

  void _deleteReading(String readingId) async {
    final locals = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(locals.delete),
        content: Text(locals.confirmDeleteUser),
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
            Provider.of<BloodPressureProvider>(context, listen: false);
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
    final provider = Provider.of<BloodPressureProvider>(context, listen: false);

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
                '${locals.bloodPressure} ${locals.viewCharts}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ChartWidget(
                  readings: provider.readings
                      .map((r) => ChartData(
                            date: r.dateTime,
                            systolic: r.systolic.toDouble(),
                            diastolic: r.diastolic.toDouble(),
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
      case 'elevated':
        return Colors.orange;
      case 'high':
        return Colors.red;
      case 'crisis':
        return Colors.red.shade900;
      default:
        return Colors.grey;
    }
  }

  String _getCategoryText(String category, AppLocalizations locals) {
    switch (category) {
      case 'normal':
        return locals.normal;
      case 'elevated':
        return locals.elevated;
      case 'high':
        return locals.high;
      case 'crisis':
        return locals.crisis;
      default:
        return category;
    }
  }
}
