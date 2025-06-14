class BloodSugar {
  final String id;
  final String userId;
  final double glucose;
  final String measurementType; // fasting, postMeal, random
  final DateTime dateTime;
  final String? notes;
  final DateTime createdAt;

  BloodSugar({
    required this.id,
    required this.userId,
    required this.glucose,
    required this.measurementType,
    required this.dateTime,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'glucose': glucose,
      'measurement_type': measurementType,
      'date_time': dateTime.millisecondsSinceEpoch,
      'notes': notes,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory BloodSugar.fromMap(Map<String, dynamic> map) {
    return BloodSugar(
      // Ensure 'id' is a String. Use toString() to convert if it's not.
      id: map['id']?.toString() ?? '',
      // Ensure 'user_id' is a String.
      userId: map['user_id']?.toString() ?? '',
      // Cast to num? then toDouble() for safety.
      glucose: (map['glucose'] as num?)?.toDouble() ?? 0.0,
      // Explicitly cast to String? then provide default.
      measurementType: map['measurement_type'] as String? ?? 'random',
      // Cast to int? then provide default for millisecondsSinceEpoch.
      dateTime:
          DateTime.fromMillisecondsSinceEpoch(map['date_time'] as int? ?? 0),
      // 'notes' is already nullable, so direct cast as String? is sufficient.
      notes: map['notes'] as String?,
      // Cast to int? then provide default for millisecondsSinceEpoch.
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int? ?? 0),
    );
  }

  BloodSugar copyWith({
    String? id,
    String? userId,
    double? glucose,
    String? measurementType,
    DateTime? dateTime,
    String? notes,
    DateTime? createdAt,
  }) {
    return BloodSugar(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      glucose: glucose ?? this.glucose,
      measurementType: measurementType ?? this.measurementType,
      dateTime: dateTime ?? this.dateTime,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get category {
    switch (measurementType) {
      case 'fasting':
        if (glucose < 100) return 'normal';
        if (glucose < 126) return 'prediabetes';
        return 'diabetes';
      case 'postMeal':
        if (glucose < 140) return 'normal';
        if (glucose < 200) return 'prediabetes';
        return 'diabetes';
      default: // random
        if (glucose < 140) return 'normal';
        if (glucose < 200) return 'elevated';
        return 'high';
    }
  }

  @override
  String toString() {
    return 'BloodSugar(id: $id, glucose: $glucose, type: $measurementType, dateTime: $dateTime)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BloodSugar && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
