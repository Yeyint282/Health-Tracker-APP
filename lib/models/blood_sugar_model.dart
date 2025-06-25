class BloodSugar {
  final String id;
  final String userId;
  final double glucose;
  final String measurementType;
  final DateTime dateTime;
  final String? notes;
  final DateTime createdAt;
  final String category;

  BloodSugar({
    required this.id,
    required this.userId,
    required this.glucose,
    required this.measurementType,
    required this.dateTime,
    this.notes,
    required this.createdAt,
    required this.category, // <--- Add to constructor
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
      'category': category, // <--- Add to map conversion
    };
  }

  factory BloodSugar.fromMap(Map<String, dynamic> map) {
    return BloodSugar(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      glucose: (map['glucose'] as num?)?.toDouble() ?? 0.0,
      measurementType: map['measurement_type'] as String? ?? 'random',
      dateTime:
          DateTime.fromMillisecondsSinceEpoch(map['date_time'] as int? ?? 0),
      notes: map['notes'] as String?,
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int? ?? 0),
      category: map['category']?.toString() ?? 'unknown', // <--- Read from map
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
    String? category,
  }) {
    return BloodSugar(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      glucose: glucose ?? this.glucose,
      measurementType: measurementType ?? this.measurementType,
      dateTime: dateTime ?? this.dateTime,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
    );
  }

  @override
  String toString() {
    return 'BloodSugar(id: $id, glucose: $glucose, type: $measurementType, dateTime: $dateTime, category: $category)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BloodSugar && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
