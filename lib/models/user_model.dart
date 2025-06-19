// user_model.dart
class User {
  final String id;
  final String name;
  final int age;
  final String gender;
  final double? weight;
  final double? height;
  final String? photoPath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool? hasDiabetes; // <--- ADD THIS FIELD

  User({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    this.weight,
    this.height,
    this.photoPath,
    required this.createdAt,
    required this.updatedAt,
    this.hasDiabetes, // <--- ADD TO CONSTRUCTOR
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'weight': weight,
      'height': height,
      'photo_path': photoPath,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'has_diabetes': hasDiabetes == true
          ? 1
          : (hasDiabetes == false
              ? 0
              : null), // <--- HANDLE TO MAP (SQLite often uses 0/1 for bool)
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      // Ensure 'id' is a String. Use toString() to convert if it's not.
      id: map['id']?.toString() ?? '',
      // Ensure 'name' is a String.
      name: map['name']?.toString() ?? '',
      // Cast to num? then toInt() for safety, provide default.
      age: (map['age'] as num?)?.toInt() ?? 0,
      // Ensure 'gender' is a String.
      gender: map['gender']?.toString() ?? '',
      // Cast to num? then toDouble() for safety, allow null.
      weight: (map['weight'] as num?)?.toDouble(),
      // Cast to num? then toDouble() for safety, allow null.
      height: (map['height'] as num?)?.toDouble(),
      // Cast to int? then provide default for millisecondsSinceEpoch.
      // Read from map
      photoPath: map['photo_path']?.toString(),
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int? ?? 0),
      // Cast to int? then provide default for millisecondsSinceEpoch.
      updatedAt:
          DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int? ?? 0),
      hasDiabetes: map['has_diabetes'] == 1
          ? true
          : (map['has_diabetes'] == 0 ? false : null), // <--- HANDLE FROM MAP
    );
  }

  User copyWith({
    String? id,
    String? name,
    int? age,
    String? gender,
    double? weight,
    double? height,
    String? photoPath,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? hasDiabetes, // <--- ADD TO copyWith
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      photoPath: photoPath ?? this.photoPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      hasDiabetes: hasDiabetes ?? this.hasDiabetes, // <--- ADD TO copyWith
    );
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, age: $age, gender: $gender, weight: $weight, height: $height, photoPath: $photoPath, hasDiabetes: $hasDiabetes)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
