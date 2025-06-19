import 'dart:io';

import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/database_service.dart';

class UserProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService.instance;
  List<User> _users = [];
  User? _selectedUser;
  String? _lastSelectedUserId;
  bool _isLoading = false;

  List<User> get users => _users;

  User? get selectedUser => _selectedUser;

  String? get lastSelectedUserId => _lastSelectedUserId;

  bool get isLoading => _isLoading;

  bool get hasUsers => _users.isNotEmpty;

  UserProvider() {
    loadUsers();
  }

  Future<void> loadUsers() async {
    _isLoading = true;
    notifyListeners();
    try {
      _users = await _databaseService.getUsers();
      if (_selectedUser == null && _users.isNotEmpty) {
        _selectedUser = _users.first;
        _lastSelectedUserId = _users.first.id;
      }
      // After loading, if the selected user was deleted, or no users exist, clear selection
      if (_selectedUser != null &&
          !_users.any((user) => user.id == _selectedUser!.id)) {
        _selectedUser = _users.isNotEmpty ? _users.first : null;
        _lastSelectedUserId = _selectedUser?.id;
      } else if (_users.isEmpty) {
        _selectedUser = null;
        _lastSelectedUserId = null;
      }
    } catch (e) {
      debugPrint('Error loading users: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createUser(User user) async {
    try {
      // The `user` object passed here should already contain the `hasDiabetes` value
      // if it was collected from the UI (e.g., in a user creation form).
      // The `insertUser` method in DatabaseService will handle saving it to the database.
      await _databaseService.insertUser(user);
      await loadUsers(); // Load users to get the latest list
      // Assuming user.name is unique enough for selection after creation.
      // A more robust way might be to get the user directly from the DB after insertion
      // using the returned ID if your insert method provides it.
      _selectedUser = _users
          .firstWhere((u) => u.id == user.id); // Prefer ID for unique selection
      _lastSelectedUserId = _selectedUser?.id;
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating user: $e');
      rethrow;
    }
  }

  Future<void> updateUser(User updatedUser) async {
    try {
      final User? originalUser = getUserById(updatedUser.id);
      final String? oldPhotoPath = originalUser?.photoPath;

      // The `updatedUser` object passed here should already contain the updated
      // `hasDiabetes` value if it was collected from the UI.
      // The `updateUser` method in DatabaseService will handle saving it.
      await _databaseService.updateUser(updatedUser);

      final bool photoWasPresent =
          oldPhotoPath != null && oldPhotoPath.isNotEmpty;
      final bool newPhotoIsDifferent = oldPhotoPath != updatedUser.photoPath;
      final bool newPhotoIsNull =
          updatedUser.photoPath == null || updatedUser.photoPath!.isEmpty;

      if (photoWasPresent && (newPhotoIsDifferent || newPhotoIsNull)) {
        try {
          final oldFile = File(oldPhotoPath);
          if (await oldFile.exists()) {
            await oldFile.delete();
            debugPrint('Successfully deleted old photo: $oldPhotoPath');
          }
        } catch (e) {
          debugPrint('Error deleting old photo file: $e');
        }
      }

      await loadUsers(); // Refresh the user list from the database
      _selectedUser = getUserById(updatedUser.id); // Re-select the updated user
      _lastSelectedUserId = _selectedUser?.id;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating user: $e');
      rethrow;
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      final User? userToDelete = getUserById(userId);
      await _databaseService.deleteUser(userId);
      if (userToDelete != null &&
          userToDelete.photoPath != null &&
          userToDelete.photoPath!.isNotEmpty) {
        try {
          final file = File(userToDelete.photoPath!);
          if (await file.exists()) {
            await file.delete();
            debugPrint(
                'Successfully deleted user photo: ${userToDelete.photoPath}');
          }
        } catch (e) {
          debugPrint('Error deleting user photo file: $e');
        }
      }
      await loadUsers(); // Reload users after deletion
      if (_selectedUser?.id == userId) {
        _selectedUser = _users.isNotEmpty
            ? _users.first
            : null; // Select first user or null if no users left
      }
      _lastSelectedUserId = _selectedUser?.id;
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting user: $e');
      rethrow;
    }
  }

  void selectUser(User? user) {
    if (_selectedUser?.id != user?.id) {
      _selectedUser = user;
      _lastSelectedUserId = user?.id;
      notifyListeners();
    }
  }

  void clearSelectedUser() {
    _selectedUser = null;
    notifyListeners();
  }

  User? getUserById(String id) {
    try {
      return _users.firstWhere((user) => user.id == id);
    } catch (e) {
      return null;
    }
  }
}
