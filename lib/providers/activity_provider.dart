import 'package:flutter/material.dart';

import '../models/activity_model.dart';
import '../services/database_service.dart';

class ActivityProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService.instance;

  List<Activity> _activities = [];
  bool _isLoading = false;
  String? _selectedUserId;

  List<Activity> get activities => _activities;

  bool get isLoading => _isLoading;

  Activity? get latestActivity =>
      _activities.isNotEmpty ? _activities.first : null;

  void setUserId(String? userId) {
    if (_selectedUserId != userId) {
      _selectedUserId = userId;
      if (userId != null) {
        loadActivities(userId);
      } else {
        _activities.clear();
        notifyListeners();
      }
    }
  }

  Future<void> loadActivities(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _activities = await _databaseService.getActivities(userId);
      _activities.sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      debugPrint('Error loading activities: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addActivity(Activity activity) async {
    try {
      await _databaseService.insertActivity(activity);
      if (_selectedUserId == activity.userId) {
        await loadActivities(activity.userId);
      }
    } catch (e) {
      debugPrint('Error adding activity: $e');
      rethrow;
    }
  }

  Future<void> updateActivity(Activity activity) async {
    try {
      await _databaseService.updateActivity(activity);
      if (_selectedUserId == activity.userId) {
        await loadActivities(activity.userId);
      }
    } catch (e) {
      debugPrint('Error updating activity: $e');
      rethrow;
    }
  }

  Future<void> deleteActivity(String activityId) async {
    try {
      await _databaseService.deleteActivity(activityId);
      if (_selectedUserId != null) {
        await loadActivities(_selectedUserId!);
      }
    } catch (e) {
      debugPrint('Error deleting activity: $e');
      rethrow;
    }
  }

  List<Activity> getActivitiesForDateRange(DateTime start, DateTime end) {
    return _activities.where((activity) {
      return activity.date.isAfter(start.subtract(const Duration(days: 1))) &&
          activity.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  int getTotalStepsForPeriod([int? days]) {
    if (_activities.isEmpty) return 0;

    List<Activity> filteredActivities = _activities;

    if (days != null) {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      filteredActivities = _activities
          .where((activity) => activity.date.isAfter(cutoffDate))
          .toList();
    }

    return filteredActivities.fold(0, (sum, activity) => sum + activity.steps);
  }

  double getTotalCaloriesForPeriod([int? days]) {
    if (_activities.isEmpty) return 0.0;

    List<Activity> filteredActivities = _activities;

    if (days != null) {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      filteredActivities = _activities
          .where((activity) => activity.date.isAfter(cutoffDate))
          .toList();
    }

    return filteredActivities.fold(
        0.0, (sum, activity) => sum + activity.calories);
  }

  double getTotalDistanceForPeriod([int? days]) {
    if (_activities.isEmpty) return 0.0;

    List<Activity> filteredActivities = _activities;

    if (days != null) {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      filteredActivities = _activities
          .where((activity) => activity.date.isAfter(cutoffDate))
          .toList();
    }

    return filteredActivities.fold(
        0.0, (sum, activity) => sum + activity.distance);
  }
}
