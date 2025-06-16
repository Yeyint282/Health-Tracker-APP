import 'package:flutter/material.dart';

import '../models/user_model.dart';import '../services/database_service.dart';

class UserProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService.instance;

  List<User> _users = [];

  User? _selectedUser;

  bool _isLoading = false;

  List<User> get users => _users;

  User? get selectedUser => _selectedUser;

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

// If no user is selected but users exist, select the first one

      if (_selectedUser == null && _users.isNotEmpty) {
        _selectedUser = _users.first;
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
      await _databaseService.insertUser(user);

      await loadUsers();

// Select the newly created user

      _selectedUser = user;

      notifyListeners();
    } catch (e) {
      debugPrint('Error creating user: $e');

      rethrow;
    }
  }

  Future<void> updateUser(User user) async {
    try {
      await _databaseService.updateUser(user);

      await loadUsers();

// Update selected user if it's the one being updated

      if (_selectedUser?.id == user.id) {
        _selectedUser = user;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating user: $e');

      rethrow;
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _databaseService.deleteUser(userId);

      await loadUsers();

// If the deleted user was selected, select another one or set to null

      if (_selectedUser?.id == userId) {
        _selectedUser = _users.isNotEmpty ? _users.first : null;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting user: $e');

      rethrow;
    }
  }

  void selectUser(User user) {
    if (_selectedUser?.id != user.id) {
      _selectedUser = user;

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
