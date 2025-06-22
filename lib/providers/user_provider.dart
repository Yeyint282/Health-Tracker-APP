// user_provider.dart (From previous response, keep it as is)
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

      if (_selectedUser != null) {
        final updatedSelectedUser =
            _users.firstWhereOrNull((u) => u.id == _selectedUser!.id);
        if (updatedSelectedUser != null) {
          _selectedUser = updatedSelectedUser;
        } else {
          _selectedUser = _users.isNotEmpty ? _users.first : null;
        }
      } else if (_users.isNotEmpty) {
        _selectedUser = _users.first;
      }
      _lastSelectedUserId = _selectedUser?.id;
    } catch (e) {
      debugPrint('Error loading users: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createUser(User user) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _databaseService.insertUser(user);
      _users.add(user);
      _users.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      _selectedUser = user;
      _lastSelectedUserId = user.id;
    } catch (e) {
      debugPrint('Error creating user: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUser(User updatedUser) async {
    _isLoading = true;
    notifyListeners();
    try {
      final User? originalUser = getUserById(updatedUser.id);
      final String? oldPhotoPath = originalUser?.photoPath;

      // 1. Update the database record
      await _databaseService.updateUser(updatedUser);

      // 2. Handle old photo file deletion AND cache eviction
      final bool photoWasPresent =
          oldPhotoPath != null && oldPhotoPath.isNotEmpty;
      final bool newPhotoIsDifferent = oldPhotoPath != updatedUser.photoPath;
      final bool newPhotoIsNull =
          updatedUser.photoPath == null || updatedUser.photoPath!.isEmpty;

      if (photoWasPresent && (newPhotoIsDifferent || newPhotoIsNull)) {
        // Evict the old image from Flutter's cache BEFORE deleting the file
        if (oldPhotoPath != null && oldPhotoPath.isNotEmpty) {
          final oldImageProvider = FileImage(File(oldPhotoPath));
          await oldImageProvider.evict();
          debugPrint('Evicted old photo from cache: $oldPhotoPath');
        }

        try {
          final oldFile = File(oldPhotoPath!);
          if (await oldFile.exists()) {
            await oldFile.delete();
            debugPrint('Successfully deleted old photo file: $oldPhotoPath');
          }
        } catch (e) {
          debugPrint('Error deleting old photo file: $e');
        }
      }

      // If a new photo was chosen, ensure it's also not cached stale
      // This condition ensures we only evict if a *new* valid path is set, AND it's different from the old one
      if (updatedUser.photoPath != null &&
          updatedUser.photoPath!.isNotEmpty &&
          newPhotoIsDifferent) {
        final newImageProvider = FileImage(File(updatedUser.photoPath!));
        // It might not be in cache yet, but evicting here ensures no stale data is used if it was somehow in cache from another process/run.
        await newImageProvider.evict();
        debugPrint(
            'Evicted new photo from cache (precautionary): ${updatedUser.photoPath}');
      }

      // 3. Update the in-memory list directly
      final index = _users.indexWhere((user) => user.id == updatedUser.id);
      if (index != -1) {
        _users[index] = updatedUser;
      }

      // 4. Ensure _selectedUser points to the *newly updated object instance*
      if (_selectedUser?.id == updatedUser.id) {
        _selectedUser = updatedUser;
      }
      _lastSelectedUserId = _selectedUser?.id;
    } catch (e) {
      debugPrint('Error updating user: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteUser(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final User? userToDelete = getUserById(userId);
      await _databaseService.deleteUser(userId);

      // Remove from in-memory list
      _users.removeWhere((user) => user.id == userId);

      // Evict and delete photo file
      if (userToDelete != null &&
          userToDelete.photoPath != null &&
          userToDelete.photoPath!.isNotEmpty) {
        try {
          final oldImageProvider = FileImage(File(userToDelete.photoPath!));
          await oldImageProvider.evict(); // Evict from cache
          debugPrint(
              'Evicted deleted user photo from cache: ${userToDelete.photoPath}');

          final file = File(userToDelete.photoPath!);
          if (await file.exists()) {
            await file.delete();
            debugPrint(
                'Successfully deleted user photo file: ${userToDelete.photoPath}');
          }
        } catch (e) {
          debugPrint('Error deleting user photo file: $e');
        }
      }

      // Re-adjust selected user after deletion
      if (_selectedUser?.id == userId) {
        _selectedUser = _users.isNotEmpty ? _users.first : null;
        _lastSelectedUserId = _selectedUser?.id;
      } else if (_selectedUser == null && _users.isNotEmpty) {
        _selectedUser = _users.first;
        _lastSelectedUserId = _selectedUser?.id;
      }
    } catch (e) {
      debugPrint('Error deleting user: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
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

// Extension to add firstWhereOrNull for convenience, similar to Dart 2.12+
extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}
