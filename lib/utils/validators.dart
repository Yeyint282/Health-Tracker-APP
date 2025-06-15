class Validators {
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (value.trim().length > 50) {
      return 'Name must be less than 50 characters';
    }
    return null;
  }

  static String? validateAge(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Age is required';
    }
    final age = int.tryParse(value);
    if (age == null) {
      return 'Please enter your age';
    }
    if (age < 1 || age > 120) {
      return 'Please enter a valid age (1-120)';
    }
    return null;
  }

  static String? validateWeight(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    final weight = double.tryParse(value);
    if (weight == null) {
      return 'Please enter your weight';
    }
    if (weight < 10 || weight > 500) {
      return 'Please enter a valid weight (10-500 kg)';
    }
    return null;
  }

  static String? validateHeight(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    final height = double.tryParse(value);
    if (height == null) {
      return 'Please enter your height';
    }
    if (height < 50 || height > 250) {
      return 'Please enter a valid height (50-250 cm)';
    }
    return null;
  }

  static String? validateBloodPressure(String? value,
      {required bool isSystolic}) {
    if (value == null || value.trim().isEmpty) {
      return '${isSystolic ? 'Systolic' : 'Diastolic'} pressure is required';
    }
    final pressure = int.tryParse(value);
    if (pressure == null) {
      return 'Please enter a valid number';
    }
    if (isSystolic) {
      if (pressure < 70 || pressure > 300) {
        return 'Systolic pressure should be between 70-300 mmHg';
      }
    } else {
      if (pressure < 40 || pressure > 200) {
        return 'Diastolic pressure should be between 40-200 mmHg';
      }
    }
    return null;
  }

  static String? validateBloodSugar(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Blood sugar level is required';
    }
    final glucose = double.tryParse(value);
    if (glucose == null) {
      return 'Please enter a valid number';
    }
    if (glucose < 20 || glucose > 600) {
      return 'Blood sugar should be between 20-600 mg/dL';
    }
    return null;
  }

  static String? validateSteps(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    final steps = int.tryParse(value);
    if (steps == null) {
      return 'Please enter a valid number';
    }
    if (steps < 0 || steps > 100000) {
      return 'Steps should be between 0-100,000';
    }
    return null;
  }

  static String? validateCalories(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    final calories = double.tryParse(value);
    if (calories == null) {
      return 'Please enter a valid number';
    }
    if (calories < 0 || calories > 10000) {
      return 'Calories should be between 0-10,000';
    }
    return null;
  }

  static String? validateDistance(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    final distance = double.tryParse(value);
    if (distance == null) {
      return 'Please enter a valid number';
    }
    if (distance < 0 || distance > 1000) {
      return 'Distance should be between 0-1,000 km';
    }
    return null;
  }

  static String? validateDuration(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    final duration = int.tryParse(value);
    if (duration == null) {
      return 'Please enter a valid number';
    }
    if (duration < 0 || duration > 1440) {
      return 'Duration should be between 0-1,440 minutes';
    }
    return null;
  }

  static String? validateMedicationName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Medication name is required';
    }
    if (value.trim().length < 2) {
      return 'Medication name must be at least 2 characters';
    }
    if (value.trim().length > 100) {
      return 'Medication name must be less than 100 characters';
    }
    return null;
  }

  static String? validateDosage(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Dosage is required';
    }
    if (value.trim().length < 1) {
      return 'Dosage is required';
    }
    if (value.trim().length > 50) {
      return 'Dosage must be less than 50 characters';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }
}
