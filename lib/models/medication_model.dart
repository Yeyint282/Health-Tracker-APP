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
      'reminder_times': reminderTimes.join(','),
      'instructions': instructions,
      'is_active': isActive ? 1 : 0,
      'start_date': startDate.millisecondsSinceEpoch,
      'end_date': endDate?.millisecondsSinceEpoch,
      'notes': notes,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      name: map['name'] ?? '',
      dosage: map['dosage'] ?? '',
      frequency: map['frequency'] ?? 'onceDaily',
      reminderTimes: map['reminder_times']?.toString().split(',') ?? [],
      instructions: map['instructions'],
      isActive: map['is_active'] == 1,
      startDate: DateTime.fromMillisecondsSinceEpoch(map['start_date'] ?? 0),
      endDate: map['end_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['end_date'])
          : null,
      notes: map['notes'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] ?? 0),
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
