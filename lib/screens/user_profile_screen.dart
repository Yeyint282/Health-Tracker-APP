import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../providers/user_provider.dart';
import '../widgets/user_profile_setup_widget.dart'; // Ensure this path is correct

class UserProfileScreen extends StatefulWidget {
  final User? userToEdit;
  final bool isDialog;

  const UserProfileScreen({super.key, this.userToEdit, this.isDialog = false});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).loadUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final locals = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(locals.profileTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _navigateToUserSetup,
          ),
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.users.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              _buildWelcomeCard(provider),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.users.length,
                  itemBuilder: (context, index) {
                    final user = provider.users[index];
                    final isSelected = provider.selectedUser?.id == user.id;
                    return _buildUserCard(user, isSelected, provider);
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToUserSetup,
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildEmptyState() {
    final locals = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_add,
              size: 80,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              locals.noUsers,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              locals.createFirstUser,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _navigateToUserSetup,
              icon: const Icon(Icons.person_add),
              label: Text(locals.getStarted),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(UserProvider provider) {
    final locals = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.health_and_safety,
                  color: theme.colorScheme.primary,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${locals.welcome} ${provider.selectedUser?.name ?? ''}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(
    User user,
    bool isSelected,
    UserProvider provider,
  ) {
    final locals = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 8 : 2,
      color: isSelected ? theme.colorScheme.primaryContainer : null,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: theme.colorScheme.primary,
          backgroundImage:
              (user.photoPath != null && user.photoPath!.isNotEmpty)
                  ? FileImage(File(user.photoPath!))
                  : null,
          child: (user.photoPath == null || user.photoPath!.isEmpty)
              ? Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          user.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isSelected ? theme.colorScheme.onPrimaryContainer : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${locals.age}: ${user.age} • ${_getGenderText(user.gender, locals)}',
              style: TextStyle(
                color: isSelected
                    ? theme.colorScheme.onPrimaryContainer.withOpacity(0.8)
                    : theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            if (user.weight != null || user.height != null) ...[
              const SizedBox(height: 4),
              Text(
                '${user.weight != null ? '${user.weight!.toStringAsFixed(0)} ${locals.kg}' : ''}'
                '${user.weight != null && user.height != null ? ' • ' : ''}'
                '${user.height != null ? '${user.height!.toStringAsFixed(0)} ${locals.cm}' : ''}',
                style: TextStyle(
                  color: isSelected
                      ? theme.colorScheme.onPrimaryContainer.withOpacity(0.8)
                      : theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ],
        ),
        // MODIFICATION START
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) // Only show the checkmark if selected
              Padding(
                padding: const EdgeInsets.only(right: 8.0), // Add some spacing
                child: Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.primary,
                  size: 32,
                ),
              ),
            // The PopupMenuButton is now always visible for all users
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'select':
                    // Only allow selection if not already selected
                    if (!isSelected) {
                      _selectUser(user, provider);
                    }
                    break;
                  case 'edit':
                    _editUser(user);
                    break;
                  case 'delete':
                    _deleteUser(user.id, provider);
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'select',
                  enabled: !isSelected, // Disable if already selected
                  child: Row(
                    children: [
                      const Icon(Icons.person),
                      const SizedBox(width: 8),
                      Text(locals.selectUser),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(Icons.edit),
                      const SizedBox(width: 8),
                      Text(locals.edit),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(locals.deleteUser,
                          style: const TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        // Set onTap to null if selected, preventing re-selection by tapping the card body
        onTap: isSelected ? null : () => _selectUser(user, provider),
        // MODIFICATION END
      ),
    );
  }

  void _selectUser(User user, UserProvider provider) {
    provider.selectUser(user);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Selected ${user.name}')),
    );
  }

  Future<File?> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  void _editUser(User user) async {
    final locals = AppLocalizations.of(context)!;

    final nameController = TextEditingController(text: user.name);
    final ageController = TextEditingController(text: user.age.toString());
    final weightController = TextEditingController(
      text: user.weight?.toString() ?? '',
    );
    final heightController = TextEditingController(
      text: user.height?.toString() ?? '',
    );
    String? selectedGender = user.gender;

    final ValueNotifier<File?> imageFileNotifier = ValueNotifier<File?>(
      (user.photoPath != null && user.photoPath!.isNotEmpty)
          ? File(user.photoPath!)
          : null,
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(locals.updateProfile),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder<File?>(
                valueListenable: imageFileNotifier,
                builder: (context, currentImageFile, child) {
                  return GestureDetector(
                    onTap: () async {
                      await showModalBottomSheet(
                        context: context,
                        builder: (BuildContext context) {
                          return SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                ListTile(
                                  leading: const Icon(Icons.photo_library),
                                  title: Text(locals.photoLibrary),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    final picked =
                                        await _pickImage(ImageSource.gallery);
                                    if (picked != null) {
                                      imageFileNotifier.value = picked;
                                    }
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.photo_camera),
                                  title: Text(locals.camera),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    final picked =
                                        await _pickImage(ImageSource.camera);
                                    if (picked != null) {
                                      imageFileNotifier.value = picked;
                                    }
                                  },
                                ),
                                if (currentImageFile != null)
                                  ListTile(
                                    leading: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    title: Text(
                                      locals.removePhoto,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                    onTap: () {
                                      imageFileNotifier.value = null;
                                      Navigator.pop(context);
                                    },
                                  ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      backgroundImage: currentImageFile != null
                          ? FileImage(currentImageFile)
                          : null,
                      child: currentImageFile == null
                          ? Icon(
                              Icons.camera_alt,
                              size: 40,
                              color: Theme.of(context).colorScheme.onPrimary,
                            )
                          : null,
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: locals.name,
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ageController,
                decoration: InputDecoration(
                  labelText: locals.age,
                  prefixIcon: const Icon(Icons.cake_outlined),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedGender,
                decoration: InputDecoration(
                  labelText: locals.gender,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'male',
                    child: Text(locals.male),
                  ),
                  DropdownMenuItem(
                    value: 'female',
                    child: Text(locals.female),
                  ),
                  DropdownMenuItem(
                    value: 'other',
                    child: Text(locals.other),
                  ),
                ],
                onChanged: (value) {
                  selectedGender = value;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return locals.pleaseSelectGender;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: weightController,
                decoration: InputDecoration(
                  labelText: locals.enterWeight,
                  prefixIcon: const Icon(Icons.fitness_center),
                  suffixText: locals.kg,
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: heightController,
                decoration: InputDecoration(
                  labelText: locals.enterHeight,
                  prefixIcon: const Icon(Icons.height),
                  suffixText: locals.cm,
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(locals.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              _saveUserUpdates(
                user,
                nameController.text,
                ageController.text,
                selectedGender ?? 'other',
                weightController.text,
                heightController.text,
                imageFileNotifier.value,
              );
            },
            child: Text(locals.save),
          ),
        ],
      ),
    );

    imageFileNotifier.dispose();

    if (mounted) {
      Provider.of<UserProvider>(context, listen: false).loadUsers();
    }
  }

  void _saveUserUpdates(
    User originalUser, // Renamed for clarity
    String name,
    String ageText,
    String gender,
    String weightText,
    String heightText,
    File? newImageFile,
  ) async {
    if (name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required')),
      );
      return;
    }

    final age = int.tryParse(ageText);
    if (age == null || age < 1 || age > 120) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid age')),
      );
      return;
    }
    final weight = weightText.isEmpty ? null : double.tryParse(weightText);
    final height = heightText.isEmpty ? null : double.tryParse(heightText);

    final String? newPhotoPath = newImageFile?.path;

    final updatedUser = originalUser.copyWith(
      name: name.trim(),
      age: age,
      gender: gender,
      weight: weight,
      height: height,
      photoPath: newPhotoPath,
      updatedAt: DateTime.now(),
    );

    try {
      final provider = Provider.of<UserProvider>(context, listen: false);
      await provider.updateUser(updatedUser);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating user: $e')),
        );
      }
    }
  }

  void _deleteUser(String userId, UserProvider provider) async {
    final locals = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(locals.deleteUser),
        content: Text(locals.confirmDeleteUser),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(locals.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(locals.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await provider.deleteUser(userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(locals.userDeleted)),
          );
          // The UserProvider's deleteUser now handles selection logic
          // and loadUsers will also ensure a valid user is selected or null.
          // No need for a separate selectUser(null) call here directly.
          // Provider.of<UserProvider>(context, listen: false).loadUsers(); // Already called by deleteUser internally
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting user: $e')),
          );
        }
      }
    }
  }

  void _navigateToUserSetup() {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => const UserProfileSetup(
          isDialog: false,
          userToEdit: null,
        ),
      ),
    )
        .then((_) {
      Provider.of<UserProvider>(context, listen: false).loadUsers();
    });
  }

  String _getGenderText(String gender, AppLocalizations locals) {
    switch (gender) {
      case 'male':
        return locals.male;
      case 'female':
        return locals.female;
      case 'other':
        return locals.other;
      default:
        return gender;
    }
  }
}
