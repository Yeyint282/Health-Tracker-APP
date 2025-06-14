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
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      // Store reminderTimes as a comma-separated string for simplicity in Map
      'reminder_times': reminderTimes.join(','),
      'instructions': instructions,
      'is_active': isActive ? 1 : 0, // Store bool as int for database
      'start_date': startDate.millisecondsSinceEpoch,
      'end_date': endDate?.millisecondsSinceEpoch,
      'notes': notes,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      // Ensure 'id' is a String.
      id: map['id']?.toString() ?? '',
      // Ensure 'user_id' is a String.
      userId: map['user_id']?.toString() ?? '',
      // Ensure 'name' is a String.
      name: map['name']?.toString() ?? '',
      // Ensure 'dosage' is a String.
      dosage: map['dosage']?.toString() ?? '',
      // Explicitly cast to String? then provide default.
      frequency: map['frequency'] as String? ?? 'onceDaily',
      // Safely get reminder_times, split if it's a string, otherwise empty list.
      reminderTimes: (map['reminder_times'] as String?)?.split(',') ?? [],
      // 'instructions' is nullable String, safe to cast directly.
      instructions: map['instructions'] as String?,
      // Convert int (0 or 1) back to bool. Use as int? for safety.
      isActive: (map['is_active'] as int?) == 1,
      // Cast to int? for millisecondsSinceEpoch, provide default.
      startDate:
          DateTime.fromMillisecondsSinceEpoch(map['start_date'] as int? ?? 0),
      // Handle nullable endDate: cast to int? before passing.
      endDate: map['end_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['end_date'] as int)
          : null,
      // 'notes' is nullable String, safe to cast directly.
      notes: map['notes'] as String?,
      // Cast to int? for millisecondsSinceEpoch, provide default.
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int? ?? 0),
    );
  }

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
    );
  }

  @override
  String toString() {
    return 'Medication(id: $id, name: $name, dosage: $dosage, frequency: $frequency)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Medication && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
