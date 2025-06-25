class Medication {
  final String id;
  final String userId;
  final String name;
  final String dosage;
  final String frequency; // onceDaily, twiceDaily, threeTimesDaily, asNeeded
  final List<String>
      reminderTimes; // List of time strings like ["08:00", "20:00"]
  final String? instructions; // beforeMeals, afterMeals, withMeals
  final bool isActive;
  final DateTime startDate;
  final DateTime? endDate;
  final String? notes;
  final DateTime createdAt;

  // NEW: Add notificationType to store preference ('notification' or 'alarm')
  final String notificationType; // 'notification' or 'alarm'

  Medication({
    required this.id,
    required this.userId,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.reminderTimes,
    this.instructions,
    this.isActive = true,
    required this.startDate,
    this.endDate,
    this.notes,
    required this.createdAt,
    this.notificationType = 'notification', // Default to 'notification'
  });

  /// Converts a Medication object to a Map for database storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'reminder_times': reminderTimes.join(','),
      // Store list as comma-separated string
      'instructions': instructions,
      'is_active': isActive ? 1 : 0,
      // Store bool as int (1 for true, 0 for false)
      'start_date': startDate.millisecondsSinceEpoch,
      // Store DateTime as millisecondsSinceEpoch
      'end_date': endDate?.millisecondsSinceEpoch,
      'notes': notes,
      'created_at': createdAt.millisecondsSinceEpoch,
      'notification_type': notificationType,
      // NEW: Add notificationType to map
    };
  }

  /// Creates a Medication object from a Map retrieved from the database.
  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      dosage: map['dosage']?.toString() ?? '',
      frequency: map['frequency'] as String? ?? 'onceDaily',
      reminderTimes: (map['reminder_times'] as String?)?.split(',') ?? [],
      // Parse comma-separated string to list
      instructions: map['instructions'] as String?,
      isActive: (map['is_active'] as int?) == 1,
      // Parse int back to bool
      startDate:
          DateTime.fromMillisecondsSinceEpoch(map['start_date'] as int? ?? 0),
      endDate: map['end_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['end_date'] as int)
          : null,
      notes: map['notes'] as String?,
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int? ?? 0),
      notificationType: map['notification_type'] as String? ??
          'notification', // NEW: Parse notificationType from map
    );
  }

  /// Creates a copy of the Medication object with optional updated fields.
  Medication copyWith({
    String? id,
    String? userId,
    String? name,
    String? dosage,
    String? frequency,
    List<String>? reminderTimes,
    String? instructions,
    bool? isActive,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
    DateTime? createdAt,
    String? notificationType, // NEW: Add notificationType to copyWith
  }) {
    return Medication(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      instructions: instructions ?? this.instructions,
      isActive: isActive ?? this.isActive,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      notificationType:
          notificationType ?? this.notificationType, // NEW: Assign copied value
    );
  }

  @override
  String toString() {
    return 'Medication(id: $id, name: $name, dosage: $dosage, frequency: $frequency, notificationType: $notificationType,)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Medication && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
