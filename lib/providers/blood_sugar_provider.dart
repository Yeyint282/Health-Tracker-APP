import 'package:flutter/material.dart';

import '../models/blood_sugar_model.dart';
import '../services/database_service.dart';

class BloodSugarProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService.instance;

  List<BloodSugar> _readings = [];
  bool _isLoading = false;
  String? _selectedUserId;

  List<BloodSugar> get readings => _readings;

  bool get isLoading => _isLoading;

  BloodSugar? get latestReading =>
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
      _readings = await _databaseService.getBloodSugarReadings(userId);
      _readings.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    } catch (e) {
      debugPrint('Error loading blood sugar readings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addReading(BloodSugar reading) async {
    try {
      await _databaseService.insertBloodSugar(reading);
      if (_selectedUserId == reading.userId) {
        await loadReadings(reading.userId);
      }
    } catch (e) {
      debugPrint('Error adding blood sugar reading: $e');
      rethrow;
    }
  }

  Future<void> updateReading(BloodSugar reading) async {
    try {
      await _databaseService.updateBloodSugar(reading);
      if (_selectedUserId == reading.userId) {
        await loadReadings(reading.userId);
      }
    } catch (e) {
      debugPrint('Error updating blood sugar reading: $e');
      rethrow;
    }
  }

  Future<void> deleteReading(String readingId) async {
    try {
      await _databaseService.deleteBloodSugar(readingId);
      if (_selectedUserId != null) {
        await loadReadings(_selectedUserId!);
      }
    } catch (e) {
      debugPrint('Error deleting blood sugar reading: $e');
      rethrow;
    }
  }

  List<BloodSugar> getReadingsForDateRange(DateTime start, DateTime end) {
    return _readings.where((reading) {
      return reading.dateTime
              .isAfter(start.subtract(const Duration(days: 1))) &&
          reading.dateTime.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  List<BloodSugar> getReadingsByType(String type) {
    return _readings
        .where((reading) => reading.measurementType == type)
        .toList();
  }

  double getAverageGlucose([int? days]) {
    if (_readings.isEmpty) return 0.0;

    List<BloodSugar> filteredReadings = _readings;

    if (days != null) {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      filteredReadings = _readings
          .where((reading) => reading.dateTime.isAfter(cutoffDate))
          .toList();
    }

    if (filteredReadings.isEmpty) return 0.0;

    final sum =
        filteredReadings.fold(0.0, (sum, reading) => sum + reading.glucose);
    return sum / filteredReadings.length;
  }
}
