import 'package:flutter/material.dart';

import '../models/blood_pressure_model.dart';
import '../services/database_service.dart';

class BloodPressureProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService.instance;

  List<BloodPressure> _readings = [];
  bool _isLoading = false;
  String? _selectedUserId;

  List<BloodPressure> get readings => _readings;

  bool get isLoading => _isLoading;

  BloodPressure? get latestReading =>
      _readings.isNotEmpty ? _readings.first : null;

  void setUserId(String? userId) {
    if (_selectedUserId != userId) {
      _selectedUserId = userId;
      if (userId != null) {
        loadReadings(userId);
      } else {
        _readings.clear();
        notifyListeners();
      }
    }
  }

  Future<void> loadReadings(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _readings = await _databaseService.getBloodPressureReadings(userId);
      _readings.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    } catch (e) {
      debugPrint('Error loading blood pressure readings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addReading(BloodPressure reading) async {
    try {
      await _databaseService.insertBloodPressure(reading);
      if (_selectedUserId == reading.userId) {
        await loadReadings(reading.userId);
      }
    } catch (e) {
      debugPrint('Error adding blood pressure reading: $e');
      rethrow;
    }
  }

  Future<void> updateReading(BloodPressure reading) async {
    try {
      await _databaseService.updateBloodPressure(reading);
      if (_selectedUserId == reading.userId) {
        await loadReadings(reading.userId);
      }
    } catch (e) {
      debugPrint('Error updating blood pressure reading: $e');
      rethrow;
    }
  }

  Future<void> deleteReading(String readingId) async {
    try {
      await _databaseService.deleteBloodPressure(readingId);
      if (_selectedUserId != null) {
        await loadReadings(_selectedUserId!);
      }
    } catch (e) {
      debugPrint('Error deleting blood pressure reading: $e');
      rethrow;
    }
  }

  List<BloodPressure> getReadingsForDateRange(DateTime start, DateTime end) {
    return _readings.where((reading) {
      return reading.dateTime
              .isAfter(start.subtract(const Duration(days: 1))) &&
          reading.dateTime.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  Map<String, int> getCategoryCount() {
    final counts = <String, int>{
      'normal': 0,
      'elevated': 0,
      'high': 0,
      'crisis': 0,
    };

    for (final reading in _readings) {
      counts[reading.category] = (counts[reading.category] ?? 0) + 1;
    }

    return counts;
  }
}
