class Activity {
  final String id;
  final String userId;
  final String type; // walking, running, cycling, swimming, workout
  final int steps;
  final double calories;
  final double distance; // in km
  final int duration; // in minutes
  final DateTime date;
  final String? notes;
  final DateTime createdAt;

  Activity({
    required this.id,
    required this.userId,
    required this.type,
    required this.steps,
    required this.calories,
    required this.distance,
    required this.duration,
    required this.date,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'steps': steps,
      'calories': calories,
      'distance': distance,
      'duration': duration,
      'date': date.millisecondsSinceEpoch,
      'notes': notes,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Activity.fromMap(Map<String, dynamic> map) {
    return Activity(
      // Ensure 'id' is treated as a String. If it comes as an int from the map,
      // convert it to a String. Provide a default or throw if essential.
      id: map['id']?.toString() ?? '',
      userId: map['user_id'] as String,
      type: map['type'] as String? ?? 'walking',
      // Explicitly cast and provide default
      steps: (map['steps'] as num?)?.toInt() ?? 0,
      // Use num for flexibility then toInt
      calories: (map['calories'] as num?)?.toDouble() ?? 0.0,
      // Use num then toDouble
      distance: (map['distance'] as num?)?.toDouble() ?? 0.0,
      // Use num then toDouble
      duration: (map['duration'] as num?)?.toInt() ?? 0,
      // Use num then toInt
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int? ?? 0),
      // Cast to int? then provide default
      notes: map['notes'] as String?,
      // Already correct
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          map['created_at'] as int? ?? 0), // Cast to int? then provide default
    );
  }

  Activity copyWith({
    String? id,
    String? userId,
    String? type,
    int? steps,
    double? calories,
    double? distance,
    int? duration,
    DateTime? date,
    String? notes,
    DateTime? createdAt,
  }) {
    return Activity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      steps: steps ?? this.steps,
      calories: calories ?? this.calories,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Activity(id: $id, type: $type, steps: $steps, calories: $calories, date: $date)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Activity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
