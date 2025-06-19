import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:health_life/screens/user_profile_screen.dart';
import 'package:provider/provider.dart';

import '../providers/activity_provider.dart';
import '../providers/blood_pressure_provider.dart';
import '../providers/blood_sugar_provider.dart';
import '../providers/medication_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/health_metric_card_widget.dart';
import 'activity_screen.dart';
import 'blood_pressure_screen.dart';
import 'blood_sugar_screen.dart';
import 'medication_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
// Variable to track the time of the last back button press

  DateTime? _lastPressedAt;

  @override
  void initState() {
    super.initState();

// Ensure provider are initialized after the first frame is built

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProviders();
    });
  }

  void _initializeProviders() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final selectedUser = userProvider.selectedUser;
    if (selectedUser != null) {
      Provider.of<BloodPressureProvider>(context, listen: false)
          .setUserId(selectedUser.id);
      Provider.of<BloodSugarProvider>(context, listen: false)
          .setUserId(selectedUser.id);
      Provider.of<ActivityProvider>(context, listen: false)
          .setUserId(selectedUser.id);
      Provider.of<MedicationProvider>(context, listen: false)
          .setUserId(selectedUser.id);
      _refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
// If the pop was already handled (e.g., by another nested PopScope), just return.
        if (didPop) {
          return;
        }

// Logic for "double back to exit"
        if (_lastPressedAt == null ||
            DateTime.now().difference(_lastPressedAt!) >
                const Duration(seconds: 2)) {
          _lastPressedAt = DateTime.now();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.pressBackAgainToExit),
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (!userProvider.hasUsers) {
            return const UserProfileScreen(
              userToEdit: null,
              isDialog: false,
            );
          }
          if (userProvider.selectedUser == null) {
            return _buildUserSelectionScreen();
          }
          return _buildHomeContent();
        },
      ),
    );
  }

  Widget _buildUserSelectionScreen() {
    final locals = AppLocalizations.of(context)!;
    final userProvider = Provider.of<UserProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(locals.selectUser),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: userProvider.users.length,
        itemBuilder: (context, index) {
          final user = userProvider.users[index];
          final bool isSelected = user.id == userProvider.selectedUser?.id;
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isSelected
                  ? BorderSide(
                      color: Theme.of(context).colorScheme.primary, width: 2)
                  : BorderSide.none,
            ),
            child: ListTile(
              selected: isSelected,
              selectedTileColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.08),
              leading: CircleAvatar(
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                backgroundImage:
                    (user.photoPath != null && user.photoPath!.isNotEmpty)
                        ? FileImage(File(user.photoPath!))
                        : null,
                child: (user.photoPath == null || user.photoPath!.isEmpty)
                    ? Text(
                        user.name.isNotEmpty
                            ? user.name.substring(0, 1).toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              title: Text(
                user.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Text(
                '${locals.age}: ${user.age}, ${locals.gender}: ${user.gender}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              trailing: isSelected
                  ? Chip(
                      label: Text('Selected'),
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      labelStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                      padding: EdgeInsets.zero,
                    )
                  : null,
              onTap: () {
                userProvider.selectUser(user);
                _initializeProviders();
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildHomeContent() {
    final locals = AppLocalizations.of(context)!;

    final theme = Theme.of(context);

    final userProvider = Provider.of<UserProvider>(context);

    final user = userProvider.selectedUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(locals.homeTitle),
        backgroundColor: theme.colorScheme.surface,
        automaticallyImplyLeading: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserProfileScreen(
                    isDialog: false,
                    userToEdit: user,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserGreeting(),
              const SizedBox(height: 24),
              _buildQuickStats(),
              const SizedBox(height: 24),
              _buildHealthMetrics(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserGreeting() {
    final locals = AppLocalizations.of(context)!;

    final theme = Theme.of(context);

    final userProvider = Provider.of<UserProvider>(context);

    final user = userProvider.selectedUser!;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,

              backgroundColor: theme.colorScheme.primaryContainer,

// Conditionally display the user's photo or initial

              backgroundImage:
                  (user.photoPath != null && user.photoPath!.isNotEmpty)
                      ? FileImage(File(user.photoPath!))
                      : null,

              child: (user.photoPath == null || user.photoPath!.isEmpty)
                  ? Text(
                      user.name.isNotEmpty
                          ? user.name.substring(0, 1).toUpperCase()
                          : '?',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
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
                    '${locals.welcome}, ${user.name}!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${locals.age}: ${user.age} • ${locals.gender}: ${user.gender}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

// Show swap user icon only if there's more than one user

            if (userProvider.users.length > 1)
              IconButton(
                icon: const Icon(Icons.swap_horiz),
                color: theme.colorScheme.secondary,
                onPressed: () {
                  userProvider.clearSelectedUser();
                },
                tooltip: locals.switchUser,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    final locals = AppLocalizations.of(context)!;

    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              locals.today,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Consumer4<BloodPressureProvider, BloodSugarProvider,
                ActivityProvider, MedicationProvider>(
              builder: (context, bpProvider, bsProvider, activityProvider,
                  medicationProvider, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        icon: Icons.monitor_heart,
                        label: locals.bloodPressure,
                        value: bpProvider.latestReading != null
                            ? '${bpProvider.latestReading!.systolic}/${bpProvider.latestReading!.diastolic}'
                            : '--',
                        color: Colors.red.shade600,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        icon: Icons.bloodtype,
                        label: locals.bloodSugar,
                        value: bsProvider.latestReading != null
                            ? '${bsProvider.latestReading!.glucose.toStringAsFixed(0)}'
                            : '--',
                        color: Colors.blue.shade600,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        icon: Icons.directions_walk,
                        label: locals.steps,
                        value: activityProvider.latestActivity != null
                            ? '${activityProvider.latestActivity!.steps}'
                            : '0',
                        color: Colors.green.shade600,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, color: color, size: 36),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildHealthMetrics() {
    final locals = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          locals.healthMetrics,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            HealthMetricCard(
              title: locals.bloodPressure,
              icon: Icons.monitor_heart,
              color: Colors.red.shade600,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BloodPressureScreen(),
                  ),
                );
              },
            ),
            HealthMetricCard(
              title: locals.bloodSugar,
              icon: Icons.bloodtype,
              color: Colors.blue.shade600,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BloodSugarScreen(),
                  ),
                );
              },
            ),
            HealthMetricCard(
              title: locals.dailyActivity,
              icon: Icons.directions_walk,
              color: Colors.green.shade600,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ActivityScreen(),
                  ),
                );
              },
            ),
            HealthMetricCard(
              title: locals.medications,
              icon: Icons.medication,
              color: Colors.orange.shade600,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MedicationScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

// Refreshes data for all health metric providers.

  Future<void> _refreshData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final selectedUser = userProvider.selectedUser;

    if (selectedUser != null) {
      await Future.wait([
        Provider.of<BloodPressureProvider>(context, listen: false)
            .loadReadings(selectedUser.id),
        Provider.of<BloodSugarProvider>(context, listen: false)
            .loadReadings(selectedUser.id),
        Provider.of<ActivityProvider>(context, listen: false)
            .loadActivities(selectedUser.id),
        Provider.of<MedicationProvider>(context, listen: false)
            .loadMedications(selectedUser.id),
      ]);
    }
  }
}
