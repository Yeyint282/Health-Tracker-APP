import 'package:flutter/material.dart';

import '../models/medication_model.dart';
import '../services/database_service.dart';

class MedicationProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService.instance;

  List<Medication> _medications = [];
  bool _isLoading = false;
  String? _selectedUserId;

  List<Medication> get medications => _medications;

  List<Medication> get activeMedications =>
      _medications.where((med) => med.isActive).toList();

  bool get isLoading => _isLoading;

  void setUserId(String? userId) {
    if (_selectedUserId != userId) {
      _selectedUserId = userId;
      if (userId != null) {
        loadMedications(userId);
      } else {
        _medications.clear();
        notifyListeners();
      }
    }
  }

  Future<void> loadMedications(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _medications = await _databaseService.getMedications(userId);
      _medications.sort((a, b) => a.name.compareTo(b.name));
    } catch (e) {
      debugPrint('Error loading medications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addMedication(Medication medication) async {
    try {
      await _databaseService.insertMedication(medication);
      if (_selectedUserId == medication.userId) {
        await loadMedications(medication.userId);
      }
    } catch (e) {
      debugPrint('Error adding medication: $e');
      rethrow;
    }
  }

  Future<void> updateMedication(Medication medication) async {
    try {
      await _databaseService.updateMedication(medication);
      if (_selectedUserId == medication.userId) {
        await loadMedications(medication.userId);
      }
    } catch (e) {
      debugPrint('Error updating medication: $e');
      rethrow;
    }
  }

  Future<void> deleteMedication(String medicationId) async {
    try {
      await _databaseService.deleteMedication(medicationId);
      if (_selectedUserId != null) {
        await loadMedications(_selectedUserId!);
      }
    } catch (e) {
      debugPrint('Error deleting medication: $e');
      rethrow;
    }
  }

  Future<void> toggleMedicationStatus(String medicationId) async {
    try {
      final medication =
          _medications.firstWhere((med) => med.id == medicationId);
      final updatedMedication =
          medication.copyWith(isActive: !medication.isActive);
      await updateMedication(updatedMedication);
    } catch (e) {
      debugPrint('Error toggling medication status: $e');
      rethrow;
    }
  }

  List<Medication> getMedicationsWithReminders() {
    return _medications
        .where((med) => med.isActive && med.reminderTimes.isNotEmpty)
        .toList();
  }

  int getActiveMedicationCount() {
    return activeMedications.length;
  }
}
