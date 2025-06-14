class BloodPressure {
  final String id;
  final String userId;
  final int systolic;
  final int diastolic;
  final DateTime dateTime;
  final String? notes;
  final DateTime createdAt;

  BloodPressure({
    required this.id,
    required this.userId,
    required this.systolic,
    required this.diastolic,
    required this.dateTime,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'systolic': systolic,
      'diastolic': diastolic,
      'date_time': dateTime.millisecondsSinceEpoch,
      'notes': notes,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory BloodPressure.fromMap(Map<String, dynamic> map) {
    return BloodPressure(
      // Ensure 'id' is a String. Use toString() to convert if it's not.
      id: map['id']?.toString() ?? '',
      // Ensure 'user_id' is a String.
      userId: map['user_id']?.toString() ?? '',
      // Cast to num? then toInt() for safety.
      systolic: (map['systolic'] as num?)?.toInt() ?? 0,
      // Cast to num? then toInt() for safety.
      diastolic: (map['diastolic'] as num?)?.toInt() ?? 0,
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

  BloodPressure copyWith({
    String? id,
    String? userId,
    int? systolic,
    int? diastolic,
    DateTime? dateTime,
    String? notes,
    DateTime? createdAt,
  }) {
    return BloodPressure(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      systolic: systolic ?? this.systolic,
      diastolic: diastolic ?? this.diastolic,
      dateTime: dateTime ?? this.dateTime,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get category {
    if (systolic < 120 && diastolic < 80) {
      return 'normal';
    } else if (systolic < 130 && diastolic < 80) {
      return 'elevated';
    } else if ((systolic >= 130 && systolic < 140) ||
        (diastolic >= 80 && diastolic < 90)) {
      return 'high';
    } else {
      return 'crisis';
    }
  }

  @override
  String toString() {
    return 'BloodPressure(id: $id, systolic: $systolic, diastolic: $diastolic, dateTime: $dateTime)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BloodPressure && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
