import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';

import '../models/medication_model.dart';
import '../providers/medication_provider.dart';
import '../providers/user_provider.dart';
import '../services/notification_service.dart';
import '../widgets/empty_state_widget.dart';

class MedicationScreen extends StatefulWidget {
  const MedicationScreen({super.key});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  String? _nextReminderTimeDisplay;
  late VoidCallback _medicationProviderListener;

  @override
  void initState() {
    super.initState();
    // Initialize the listener.
    _medicationProviderListener = () {
      _updateNextReminderTime();
    };
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MedicationProvider>(context, listen: false)
          .addListener(_medicationProviderListener);
      _updateNextReminderTime();
    });
  }

  @override
  void dispose() {
    Provider.of<MedicationProvider>(context, listen: false)
        .removeListener(_medicationProviderListener);
    super.dispose();
  }

  void _updateNextReminderTime() {
    final provider = Provider.of<MedicationProvider>(context, listen: false);
    final medications = provider.medications;

    tz.TZDateTime? nextScheduledTime;
    final now =
        tz.TZDateTime.now(tz.local); // Get current time in the local timezone
    for (final medication in medications) {
      if (medication.isActive && medication.frequency != 'asNeeded') {
        for (final timeString in medication.reminderTimes) {
          try {
            final timeParts = timeString.split(':');
            final hour = int.parse(timeParts[0]);
            final minute = int.parse(timeParts[1]);
            tz.TZDateTime scheduledTZDateTime = tz.TZDateTime(
              tz.local,
              now.year,
              now.month,
              now.day,
              hour,
              minute,
            );
            if (scheduledTZDateTime.isBefore(now)) {
              scheduledTZDateTime = scheduledTZDateTime.add(
                const Duration(days: 1),
              );
            }
            if (nextScheduledTime == null ||
                scheduledTZDateTime.isBefore(nextScheduledTime)) {
              nextScheduledTime = scheduledTZDateTime;
            }
          } catch (e) {
            debugPrint('Error parsing time string $timeString: $e');
          }
        }
      }
    }
    setState(() {
      if (nextScheduledTime != null) {
        _nextReminderTimeDisplay =
            TimeOfDay.fromDateTime(nextScheduledTime).format(context);
      } else {
        _nextReminderTimeDisplay = null; // No upcoming reminders found
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final locals = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(locals.medications),
        actions: [
          if (_nextReminderTimeDisplay != null)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.alarm), // Alarm icon
                  const SizedBox(width: 8), // Small space between icon and text
                  Text(
                    _nextReminderTimeDisplay!,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .secondary, // Match app bar text color
                          fontWeight: FontWeight.bold, // Make it stand out
                        ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Consumer<MedicationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.medications.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.medication,
              title: 'No medications added',
              subtitle: 'Add your first medication',
              onActionPressed: _showAddMedicationDialog,
            );
          }
          return Column(
            children: [
              _buildSummaryCard(provider),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.medications.length,
                  itemBuilder: (context, index) {
                    final medication = provider.medications[index];
                    return _buildMedicationCard(medication);
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMedicationDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryCard(MedicationProvider provider) {
    final theme = Theme.of(context);
    final activeCount = provider.getActiveMedicationCount();
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              Icons.medication,
              color: theme.colorScheme.primary,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Medications',
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(
                    '$activeCount ${activeCount == 1 ? 'medication' : 'medications'}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationCard(Medication medication) {
    final theme = Theme.of(context);
    final locals = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.medication,
                  color: medication.isActive ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medication.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${medication.dosage} • ${_getFrequencyText(medication.frequency, locals)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showEditMedicationDialog(medication);
                        break;
                      case 'toggle':
                        _toggleMedicationStatus(medication);
                        break;
                      case 'delete':
                        _deleteMedication(medication);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text(locals.edit),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child:
                          Text(medication.isActive ? 'Deactivate' : 'Activate'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(locals.delete),
                    ),
                  ],
                ),
              ],
            ),
            if (medication.reminderTimes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: medication.reminderTimes.map((time) {
                  return Chip(
                    label: Text(time),
                    backgroundColor: theme.colorScheme.surfaceVariant,
                  );
                }).toList(),
              ),
            ],
            if (medication.instructions != null) ...[
              const SizedBox(height: 8),
              Text(
                _getInstructionsText(medication.instructions!, locals),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (medication.notes != null) ...[
              const SizedBox(height: 8),
              Text(
                medication.notes!,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddMedicationDialog() {
    _showMedicationDialog();
  }

  void _showEditMedicationDialog(Medication medication) {
    _showMedicationDialog(medication: medication);
  }

  void _showMedicationDialog({Medication? medication}) {
    final locals = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: medication?.name ?? '');
    final dosageController =
        TextEditingController(text: medication?.dosage ?? '');
    final notesController =
        TextEditingController(text: medication?.notes ?? '');
    String frequency = medication?.frequency ?? 'onceDaily';
    String? instructions = medication?.instructions;
    List<String> reminderTimes = List.from(medication?.reminderTimes ?? []);
    DateTime startDate = medication?.startDate ?? DateTime.now();
    DateTime? endDate = medication?.endDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title:
              Text(medication == null ? 'Add Medication' : 'Edit Medication'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: locals.medicationName,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: dosageController,
                  decoration: InputDecoration(
                    labelText: locals.dosage,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: frequency,
                  decoration: InputDecoration(
                    labelText: locals.frequency,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'onceDaily',
                      child: Text(locals.onceDaily),
                    ),
                    DropdownMenuItem(
                      value: 'twiceDaily',
                      child: Text(locals.twiceDaily),
                    ),
                    DropdownMenuItem(
                      value: 'threeTimesDaily',
                      child: Text(locals.threeTimesDaily),
                    ),
                    DropdownMenuItem(
                      value: 'asNeeded',
                      child: Text(locals.asNeeded),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      frequency = value!;
                      reminderTimes.clear();
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  value: instructions,
                  decoration: const InputDecoration(
                    labelText: 'Instructions (Optional)',
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('None'),
                    ),
                    DropdownMenuItem(
                      value: 'beforeMeals',
                      child: Text(locals.beforeMeals),
                    ),
                    DropdownMenuItem(
                      value: 'afterMeals',
                      child: Text(locals.afterMeals),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      instructions = value;
                    });
                  },
                ),
                if (frequency != 'asNeeded') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text('Reminder Times:'),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () =>
                            _addReminderTime(setState, reminderTimes),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Time'),
                      ),
                    ],
                  ),
                  if (reminderTimes.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      children: reminderTimes.map((time) {
                        return Chip(
                          label: Text(time),
                          onDeleted: () {
                            setState(() {
                              reminderTimes.remove(time);
                            });
                          },
                        );
                      }).toList(),
                    ),
                ],
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
              onPressed: () => _saveMedication(
                medication,
                nameController.text,
                dosageController.text,
                frequency,
                reminderTimes,
                instructions,
                startDate,
                endDate,
                notesController.text,
              ),
              child: Text(locals.save),
            ),
          ],
        ),
      ),
    );
  }

  void _addReminderTime(
      StateSetter setState, List<String> reminderTimes) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      final timeString =
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (!reminderTimes.contains(timeString)) {
          reminderTimes.add(timeString);
          reminderTimes.sort(); // Keep times sorted for consistent display
        }
      });
    }
  }

  void _saveMedication(
    Medication? existingMedication,
    String name,
    String dosage,
    String frequency,
    List<String> reminderTimes,
    String? instructions,
    DateTime startDate,
    DateTime? endDate,
    String notes,
  ) async {
    if (name.isEmpty || dosage.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in required fields')),
      );
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.selectedUser?.id;

    if (userId == null) {
      debugPrint('Error: User ID is null. Cannot save medication.');
      return;
    }

    final provider = Provider.of<MedicationProvider>(context, listen: false);
    Medication medicationToSave;

    try {
      if (existingMedication != null) {
        await _cancelMedicationNotifications(existingMedication);
        medicationToSave = existingMedication.copyWith(
          name: name,
          dosage: dosage,
          frequency: frequency,
          reminderTimes: reminderTimes,
          instructions: instructions,
          startDate: startDate,
          endDate: endDate,
          notes: notes.isEmpty ? null : notes,
        );
        await provider.updateMedication(medicationToSave);
      } else {
        // If adding a new medication
        medicationToSave = Medication(
          id: const Uuid().v4(),
          // Generate a new unique ID
          userId: userId,
          name: name,
          dosage: dosage,
          frequency: frequency,
          reminderTimes: reminderTimes,
          instructions: instructions,
          startDate: startDate,
          endDate: endDate,
          notes: notes.isEmpty ? null : notes,
          createdAt: DateTime.now(), // Set creation timestamp
        );
        await provider.addMedication(medicationToSave);
      }

      if (medicationToSave.isActive) {
        await _scheduleMedicationNotifications(medicationToSave);
      }
      _updateNextReminderTime();

      if (mounted) {
        Navigator.pop(context); // Close the dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(existingMedication != null
                ? 'Medication updated'
                : 'Medication added'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving medication: $e')),
        );
      }
    }
  }

  void _toggleMedicationStatus(Medication medication) async {
    try {
      final provider = Provider.of<MedicationProvider>(context, listen: false);
      await provider.toggleMedicationStatus(medication.id);
      final updatedMedication =
          provider.medications.firstWhere((m) => m.id == medication.id);
      if (updatedMedication.isActive) {
        await _scheduleMedicationNotifications(updatedMedication);
      } else {
        await _cancelMedicationNotifications(updatedMedication);
      }
      _updateNextReminderTime();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medication status updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error toggling status: $e')),
        );
      }
    }
  }

  void _deleteMedication(Medication medication) async {
    final locals = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(locals.delete),
        content: const Text('Are you sure you want to delete this medication?'),
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
        await _cancelMedicationNotifications(medication);
        final provider =
            Provider.of<MedicationProvider>(context, listen: false);
        await provider.deleteMedication(medication.id);
        _updateNextReminderTime();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Medication deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting medication: $e')),
          );
        }
      }
    }
  }

  Future<void> _scheduleMedicationNotifications(Medication medication) async {
    for (int i = 0; i < medication.reminderTimes.length; i++) {
      final timeParts = medication.reminderTimes[i].split(':');
      final time = TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );
      final notificationId = _generateNotificationId(medication.id, i);
      await NotificationService.scheduleDailyActivityNotification(
        id: notificationId,
        title: 'Medication Reminder: ${medication.name}',
        body: 'Time to take your medicine.',
        scheduledTime: time,
        payload: 'medications/${medication.id}',
      );
      debugPrint(
          'MedicationScreen: Requested notification for ${medication.name} (ID: $notificationId) at ${time.format(context)}');
    }
    final pendingNotifications =
        await NotificationService.getPendingNotifications();
    debugPrint(
        'MedicationScreen: Currently ${pendingNotifications.length} pending notifications.');
    for (var pending in pendingNotifications) {
      debugPrint(
          '  Pending: ID=${pending.id}, Title=${pending.title}, Payload=${pending.payload}');
    }
  }

  Future<void> _cancelMedicationNotifications(Medication medication) async {
    for (int i = 0; i < medication.reminderTimes.length; i++) {
      final notificationId = _generateNotificationId(medication.id, i);
      await NotificationService.cancelNotification(notificationId);
      debugPrint(
          'MedicationScreen: Cancelled notification for ${medication.name} (ID: $notificationId)');
    }
  }

  int _generateNotificationId(String medicationId, int reminderIndex) {
    final medIdHash = medicationId.hashCode;
    return (medIdHash + reminderIndex) & 0x7FFFFFFF;
  }

  String _getFrequencyText(String frequency, AppLocalizations locals) {
    switch (frequency) {
      case 'onceDaily':
        return locals.onceDaily;
      case 'twiceDaily':
        return locals.twiceDaily;
      case 'threeTimesDaily':
        return locals.threeTimesDaily;
      case 'asNeeded':
        return locals.asNeeded;
      default:
        return frequency;
    }
  }

  String _getInstructionsText(String instructions, AppLocalizations locals) {
    switch (instructions) {
      case 'beforeMeals':
        return locals.beforeMeals;
      case 'afterMeals':
        return locals.afterMeals;
      case 'withMeals':
        return locals.withMeals;
      default:
        return instructions;
    }
  }
}
