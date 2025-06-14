import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../providers/user_provider.dart';
import '../widgets/user_profile_setup_widget.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen(
      {super.key, required userToEdit, required bool isDialog});

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
            return const Center(child: CircularProgressIndicator());
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
            const SizedBox(height: 12),
            Text(
              locals.multipleUsersSupported,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(User user, bool isSelected, UserProvider provider) {
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
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
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
        trailing: isSelected
            ? Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 32,
              )
            : PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'select':
                      _selectUser(user, provider);
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
        onTap: isSelected ? null : () => _selectUser(user, provider),
      ),
    );
  }

  void _selectUser(User user, UserProvider provider) {
    provider.selectUser(user);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Selected ${user.name}')),
    );
  }

  void _editUser(User user) {
    final locals = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: user.name);
    final ageController = TextEditingController(text: user.age.toString());
    final weightController = TextEditingController(
      text: user.weight?.toString() ?? '',
    );
    final heightController = TextEditingController(
      text: user.height?.toString() ?? '',
    );
    String selectedGender = user.gender;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(locals.updateProfile),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                    prefixIcon: const Icon(Icons.cake),
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
                    setState(() {
                      selectedGender = value!;
                    });
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
              onPressed: () => _saveUserUpdates(
                user,
                nameController.text,
                ageController.text,
                selectedGender,
                weightController.text,
                heightController.text,
              ),
              child: Text(locals.save),
            ),
          ],
        ),
      ),
    );
  }

  void _saveUserUpdates(
    User user,
    String name,
    String ageText,
    String gender,
    String weightText,
    String heightText,
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

    final updatedUser = user.copyWith(
      name: name.trim(),
      age: age,
      gender: gender,
      weight: weight,
      height: height,
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
          SnackBar(content: Text('Error: $e')),
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
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  void _navigateToUserSetup() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const UserProfileSetup(
          isDialog: false,
          userToEdit: null,
        ),
      ),
    );
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
