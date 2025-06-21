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
    notifyListeners(); // Notify listeners that loading has started
    try {
      _users = await _databaseService.getUsers();

      // If no user is currently selected AND there are users available,
      // try to select the first user.
      if (_selectedUser == null && _users.isNotEmpty) {
        _selectedUser = _users.first;
        _lastSelectedUserId = _users.first.id;
      }
      // If a user *was* selected, but they are no longer in the list (e.g., deleted by another process),
      // or if there are no users left, clear the selection or select the first available.
      else if (_selectedUser != null &&
          !_users.any((user) => user.id == _selectedUser!.id)) {
        _selectedUser = _users.isNotEmpty ? _users.first : null;
        _lastSelectedUserId = _selectedUser?.id;
      } else if (_users.isEmpty) {
        _selectedUser = null;
        _lastSelectedUserId = null;
      }
    } catch (e) {
      debugPrint('Error loading users: $e');
      // Optionally, handle error state for UI (e.g., _hasError = true)
    } finally {
      _isLoading = false;
      notifyListeners(); // Notify listeners that loading has finished and data updated
    }
  }

  Future<void> createUser(User user) async {
    _isLoading = true; // Set loading true during operation
    notifyListeners();
    try {
      // The `user` object passed here should already contain the `hasDiabetes` value
      // if it was collected from the UI (e.g., in a user creation form).
      // The `insertUser` method in DatabaseService will handle saving it to the database.
      await _databaseService.insertUser(user);
      await loadUsers(); // Reload users to get the latest list from DB, including the new user
      // After loading, ensure the newly created user is selected.
      // This relies on `loadUsers` having updated `_users` and then we find it.
      // Assuming `user.id` is stable after insertion, this is robust.
      _selectedUser = _users.firstWhere((u) => u.id == user.id,
          orElse: () => _users
              .first); // Fallback to first user if new user not found (unlikely)
      _lastSelectedUserId = _selectedUser?.id;
      // notifyListeners() is called by loadUsers, but calling it here ensures
      // immediate UI update for selection change if loadUsers finished before this line.
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating user: $e');
      rethrow; // Re-throw to allow UI to handle specific errors if needed
    } finally {
      _isLoading = false;
      // notifyListeners(); // Already called if loadUsers is successful, or by rethrow.
    }
  }

  Future<void> updateUser(User updatedUser) async {
    _isLoading = true; // Set loading true during operation
    notifyListeners();
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
          final oldFile =
              File(oldPhotoPath!); // oldPhotoPath is guaranteed not null here
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
      notifyListeners(); // Notify listeners for final state update
    } catch (e) {
      debugPrint('Error updating user: $e');
      rethrow;
    } finally {
      _isLoading = false;
      // notifyListeners(); // Called if loadUsers is successful, or by rethrow.
    }
  }

  Future<void> deleteUser(String userId) async {
    _isLoading = true; // Set loading true during operation
    notifyListeners();
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
      // If the deleted user was the selected user, re-select the first user or null.
      if (_selectedUser?.id == userId) {
        _selectedUser = _users.isNotEmpty
            ? _users.first
            : null; // Select first user or null if no users left
        _lastSelectedUserId = _selectedUser?.id;
      }
      notifyListeners(); // Notify listeners for final state update
    } catch (e) {
      debugPrint('Error deleting user: $e');
      rethrow;
    } finally {
      _isLoading = false;
      // notifyListeners(); // Called if loadUsers is successful, or by rethrow.
    }
  }

  void selectUser(User? user) {
    // Only update and notify if the selected user has actually changed.
    if (_selectedUser?.id != user?.id) {
      _selectedUser = user;
      _lastSelectedUserId = user?.id;
      notifyListeners();
    }
  }

  void clearSelectedUser() {
    if (_selectedUser != null) {
      _selectedUser = null;
      _lastSelectedUserId = null;
      notifyListeners();
    }
  }

  User? getUserById(String id) {
    try {
      return _users.firstWhere((user) => user.id == id);
    } catch (e) {
      return null;
    }
  }
}
