class AppConstants {
  // App Info
  static const String appName = 'Digital Health Tracker';
  static const String appVersion = '1.0.0';

  // Database
  static const String databaseName = 'health_tracker.db';
  static const int databaseVersion = 1;

  // Shared Preferences Keys
  static const String keyDarkMode = 'isDarkMode';
  static const String keyLanguage = 'languageCode';
  static const String keyNotifications = 'notificationsEnabled';
  static const String keySelectedUserId = 'selectedUserId';

  // Blood Pressure Categories
  static const Map<String, String> bloodPressureCategories = {
    'normal': 'Normal',
    'elevated': 'Elevated',
    'high': 'High',
    'crisis': 'Hypertensive Crisis',
  };

  // Blood Sugar Categories
  static const Map<String, String> bloodSugarCategories = {
    'normal': 'Normal',
    'predicates': 'Predicates',
    'diabetes': 'Diabetes',
    'elevated': 'Elevated',
    'high': 'High',
  };

  // Activity Types
  static const List<String> activityTypes = [
    'walking',
    'running',
    'cycling',
    'swimming',
    'workout',
  ];

  // Medication Frequencies
  static const List<String> medicationFrequencies = [
    'onceDaily',
    'twiceDaily',
    'threeTimesDaily',
    'asNeeded',
  ];

  // Measurement Types
  static const List<String> glucoseMeasurementTypes = [
    'fasting',
    'postMeal',
    'random',
  ];

  // Gender Options
  static const List<String> genderOptions = [
    'male',
    'female',
    'other',
  ];

  // Default Colors
  static const Map<String, int> defaultColors = {
    'primary': 0xFF4CAF50,
    'bloodPressure': 0xFFF44336,
    'bloodSugar': 0xFF2196F3,
    'activity': 0xFF4CAF50,
    'medication': 0xFFFF9800,
  };
}
