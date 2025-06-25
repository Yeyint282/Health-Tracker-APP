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
  late MedicationProvider
      _medicationProvider; // ⭐ NEW: Declare provider instance here ⭐

  @override
  void initState() {
    super.initState();
    // ⭐ FIX: Initialize provider instance here, when context is active ⭐
    _medicationProvider =
        Provider.of<MedicationProvider>(context, listen: false);

    _medicationProviderListener = () {
      if (mounted) {
        _updateNextReminderTime();
      }
    };
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use the stored provider instance to add the listener
      _medicationProvider.addListener(_medicationProviderListener);
      if (mounted) {
        _updateNextReminderTime();
      }
    });
  }

  @override
  void dispose() {
    // ⭐ FIX: Use the stored provider instance to remove the listener ⭐
    _medicationProvider.removeListener(_medicationProviderListener);
    super.dispose();
  }

  /// Recalculates and updates the display of the next upcoming medication reminder time.
  void _updateNextReminderTime() {
    // ⭐ FIX: Add mounted check here first thing ⭐
    if (!mounted) return;

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

            // Construct a TZDateTime for today's date at this reminder time, in the local timezone.
            tz.TZDateTime scheduledTZDateTime = tz.TZDateTime(
              tz.local,
              now.year,
              now.month,
              now.day,
              hour,
              minute,
            );

            // If the scheduled time for today has already passed, consider it for tomorrow.
            if (scheduledTZDateTime.isBefore(now)) {
              scheduledTZDateTime = scheduledTZDateTime.add(
                const Duration(days: 1),
              );
            }

            // If this is the first time found, or it's earlier than the current earliest, update.
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
    // ⭐ FIX: Add mounted check before setState ⭐
    if (!mounted) return;
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
          // Display the alarm icon and the next reminder time if available.
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
                          color: Theme.of(context).colorScheme.onPrimary,
                          // Match app bar text color (on AppBar's primary)
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

  /// Builds a summary card displaying the count of active medications.
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

  /// Builds an individual card for a medication, displaying its details.
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

  /// Shows a dialog for adding a new medication.
  void _showAddMedicationDialog() {
    _showMedicationDialog();
  }

  /// Shows a dialog for editing an existing medication.
  void _showEditMedicationDialog(Medication medication) {
    _showMedicationDialog(medication: medication);
  }

  /// Generic method to show the medication add/edit dialog.
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
    String selectedNotificationType =
        medication?.notificationType ?? 'notification';

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
                      reminderTimes.clear(); // Clear times if frequency changes
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
                  DropdownButtonFormField<String>(
                    value: selectedNotificationType,
                    decoration: const InputDecoration(
                      labelText: 'Notification Type',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'notification',
                        child: Text('Notification'),
                      ),
                      DropdownMenuItem(
                        value: 'alarm',
                        child: Text('Alarm'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedNotificationType = value!;
                      });
                    },
                  ),
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
                selectedNotificationType,
              ),
              child: Text(locals.save),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows a time picker and adds the selected time to the reminderTimes list.
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
          reminderTimes.sort();
        }
      });
    }
  }

  /// Saves or updates a medication and schedules/cancels associated notifications.
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
    String notificationType,
  ) async {
    if (name.isEmpty || dosage.isEmpty) {
      if (!mounted) return;
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
          notificationType: notificationType,
        );
        await provider.updateMedication(medicationToSave);
      } else {
        medicationToSave = Medication(
          id: const Uuid().v4(),
          userId: userId,
          name: name,
          dosage: dosage,
          frequency: frequency,
          reminderTimes: reminderTimes,
          instructions: instructions,
          startDate: startDate,
          endDate: endDate,
          notes: notes.isEmpty ? null : notes,
          createdAt: DateTime.now(),
          notificationType: notificationType,
        );
        await provider.addMedication(medicationToSave);
      }

      if (medicationToSave.isActive) {
        await _scheduleMedicationNotifications(medicationToSave);
      }
      _updateNextReminderTime();

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(existingMedication != null
              ? 'Medication updated'
              : 'Medication added'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving medication: $e')),
      );
    }
  }

  /// Toggles the active status of a medication and manages its notifications.
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

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medication status updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error toggling status: $e')),
      );
    }
  }

  /// Deletes a medication after user confirmation and cancels its notifications.
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

    if (!mounted) return; // Important check after async dialog

    if (confirmed == true) {
      try {
        await _cancelMedicationNotifications(medication);
        final provider =
            Provider.of<MedicationProvider>(context, listen: false);
        await provider.deleteMedication(medication.id);
        _updateNextReminderTime();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medication deleted')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting medication: $e')),
        );
      }
    }
  }

  /// Helper method to schedule notifications for all reminder times of a medication.
  /// It generates a unique ID for each notification and passes the notification type.
  Future<void> _scheduleMedicationNotifications(Medication medication) async {
    // Note: Accessing AppLocalizations.of(context) here might still
    // be an issue if context is unmounted. Ideally, locals should be captured
    // at the beginning of _saveMedication and passed down if _scheduleMedicationNotifications
    // is called after context might be invalid. For now, rely on mounted checks
    // in the calling methods.
    final locals = AppLocalizations.of(context)!;

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
        body: locals.timeToTakeYourMedicine,
        scheduledTime: time,
        payload: 'medications/${medication.id}',
        notificationType: medication.notificationType,
      );
      debugPrint(
          'MedicationScreen: Requested notification for ${medication.name} (ID: $notificationId) at ${time.format(context)} as ${medication.notificationType}');
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

  /// Helper method to cancel all notifications associated with a medication.
  /// It reconstructs the unique IDs to ensure all relevant notifications are cancelled.
  Future<void> _cancelMedicationNotifications(Medication medication) async {
    for (int i = 0; i < medication.reminderTimes.length; i++) {
      final notificationId = _generateNotificationId(medication.id, i);
      await NotificationService.cancelNotification(notificationId);
      debugPrint(
          'MedicationScreen: Cancelled notification for ${medication.name} (ID: $notificationId)');
    }
  }

  /// Generates a unique integer ID for a notification based on medication ID and reminder index.
  /// Uses the hash code of the medication ID to ensure uniqueness across different medications.
  int _generateNotificationId(String medicationId, int reminderIndex) {
    final medIdHash = medicationId.hashCode;
    return (medIdHash + reminderIndex) & 0x7FFFFFFF;
  }

  /// Helper to get localized frequency text.
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

  /// Helper to get localized instructions text.
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
