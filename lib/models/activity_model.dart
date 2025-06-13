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
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      type: map['type'] ?? 'walking',
      steps: map['steps']?.toInt() ?? 0,
      calories: map['calories']?.toDouble() ?? 0.0,
      distance: map['distance']?.toDouble() ?? 0.0,
      duration: map['duration']?.toInt() ?? 0,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] ?? 0),
      notes: map['notes'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] ?? 0),
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
