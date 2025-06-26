import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../providers/user_provider.dart';
import '../widgets/user_profile_setup_widget.dart';

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
    final theme = Theme.of(context);

    return Scaffold(
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

          final User? selectedUser = provider.selectedUser;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 250.0,
                // Increased height for more space
                floating: false,
                pinned: true,
                stretch: true,
                // Allows stretching when over-scrolled
                backgroundColor: theme.colorScheme.primary,
                // Default background
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  // Align title to start
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                  // Adjusted padding
                  title: selectedUser != null
                      ? Text(
                          selectedUser.name,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                offset: const Offset(1, 1),
                                blurRadius: 3.0,
                                color: Colors.black.withOpacity(0.5),
                              ),
                            ],
                          ),
                        )
                      : Text(
                          locals.profileTitle,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                offset: const Offset(1, 1),
                                blurRadius: 3.0,
                                color: Colors.black.withOpacity(0.5),
                              ),
                            ],
                          ),
                        ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (selectedUser != null &&
                          selectedUser.photoPath != null &&
                          selectedUser.photoPath!.isNotEmpty)
                        Image.file(
                          File(selectedUser.photoPath!),
                          fit: BoxFit.cover,
                        )
                      else
                        Container(
                          color: theme.colorScheme.primary,
                          child: Center(
                            child: Icon(
                              Icons.person_outline,
                              size: 100,
                              color:
                                  theme.colorScheme.onPrimary.withOpacity(0.7),
                            ),
                          ),
                        ),
                      // Gradient Overlay for better readability and aesthetic
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.2),
                              // Subtle dark at top
                              Colors.black.withOpacity(0.5),
                              // Stronger dark at bottom
                            ],
                            stops: const [
                              0.5,
                              0.7,
                              1.0
                            ], // Control gradient spread
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.person_add),
                    onPressed: _navigateToUserSetup,
                    color: theme
                        .colorScheme.onPrimary, // Ensure icon color is visible
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (selectedUser != null) ...[
                        Text(
                          locals.selectedProfileDetails,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onBackground,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildMetricGrid(selectedUser, locals, theme),
                        const SizedBox(height: 32),
                        // Increased space after metrics
                        Divider(color: theme.colorScheme.outlineVariant),
                        // Themed divider
                        const SizedBox(height: 24),
                      ],
                      Text(
                        locals.manageProfiles,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onBackground,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Column(
                        children: provider.users.map((user) {
                          final isSelected =
                              provider.selectedUser?.id == user.id;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: _buildUserItem(
                                user, isSelected, provider, theme, locals),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   // Changed to extended for more detail
      //   onPressed: _navigateToUserSetup,
      //   icon: const Icon(Icons.person_add),
      //   label: Text(locals.addUser),
      //   // Add user text
      //   backgroundColor: theme.colorScheme.primary,
      //   foregroundColor: theme.colorScheme.onPrimary,
      // ),
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

  Widget _buildMetricGrid(User user, AppLocalizations locals, ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final int crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
        final double desiredHeight = 130.0;
        final double itemAspectRatio =
            (constraints.maxWidth / crossAxisCount) / desiredHeight;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: itemAspectRatio,
          ),
          itemBuilder: (context, index) {
            switch (index) {
              case 0:
                return _buildMetricItem(
                  icon: Icons.cake_outlined,
                  label: locals.age,
                  value: '${user.age}',
                  theme: theme,
                );
              case 1:
                return _buildMetricItem(
                  icon: Icons.fitness_center,
                  label: locals.weight,
                  value: user.weight != null
                      ? '${user.weight!.toStringAsFixed(1)} ${locals.kg}'
                      : locals.notSet,
                  theme: theme,
                );
              case 2:
                return _buildMetricItem(
                  icon: Icons.height,
                  label: locals.height,
                  value: user.height != null
                      ? '${user.height!.toStringAsFixed(1)} ${locals.cm}'
                      : locals.notSet,
                  theme: theme,
                );
              default:
                return const SizedBox.shrink();
            }
          },
        );
      },
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        // Slightly less opaque
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.06), // Softer shadow
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserItem(
    User user,
    bool isSelected,
    UserProvider provider,
    ThemeData theme,
    AppLocalizations locals,
  ) {
    Key avatarKey =
        ValueKey('user_avatar_${user.id}_${user.photoPath ?? 'no_photo'}');

    return GestureDetector(
      onTap: isSelected ? null : () => _selectUser(user, provider),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? theme.colorScheme.primary
                      .withOpacity(0.25) // Softer selected shadow
                  : theme.colorScheme.shadow.withOpacity(0.08),
              // Softer general shadow
              blurRadius: isSelected ? 10 : 6,
              offset: Offset(0, isSelected ? 5 : 3),
            ),
          ],
          border: isSelected
              ? Border.all(color: theme.colorScheme.primary, width: 2)
              : null,
        ),
        child: Row(
          children: [
            CircleAvatar(
              key: avatarKey,
              radius: 30,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.8),
              // Slightly transparent for depth
              backgroundImage:
                  (user.photoPath != null && user.photoPath!.isNotEmpty)
                      ? FileImage(File(user.photoPath!))
                      : null,
              child: (user.photoPath == null || user.photoPath!.isEmpty)
                  ? Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${locals.age}: ${user.age} • ${_getGenderText(user.gender, locals)}',
                    style: TextStyle(
                      color: isSelected
                          ? theme.colorScheme.onPrimaryContainer
                              .withOpacity(0.8)
                          : theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.primary,
                  size: 32,
                ),
              ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'select':
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
                  enabled: !isSelected,
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
      barrierDismissible: false,
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
                                // if (currentImageFile != null ||
                                //     (user.photoPath != null &&
                                //         user.photoPath!.isNotEmpty))
                                //   ListTile(
                                //     leading: const Icon(
                                //       Icons.delete,
                                //       color: Colors.red,
                                //     ),
                                //     title: Text(
                                //       locals.removePhoto,
                                //       style: const TextStyle(color: Colors.red),
                                //     ),
                                //     onTap: () {
                                //       imageFileNotifier.value =
                                //           null; // Set to null
                                //       Navigator.pop(context);
                                //     },
                                //   ),
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
  }

  void _saveUserUpdates(
    User originalUser,
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

    String? photoPathToSave;
    if (newImageFile == null) {
      photoPathToSave = null;
    } else {
      photoPathToSave = newImageFile.path;
    }

    final updatedUser = originalUser.copyWith(
      name: name.trim(),
      age: age,
      gender: gender,
      weight: weight,
      height: height,
      photoPath: photoPathToSave,
      createdAt: originalUser.createdAt,
      updatedAt: DateTime.now(),
    );

    debugPrint(
        'DEBUG: _saveUserUpdates - Final updatedUser.photoPath: ${updatedUser.photoPath}');

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
      // The provider's listeners will handle refreshing the UI
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
