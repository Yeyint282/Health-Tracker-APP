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
import '../services/notification_service.dart'; // Import NotificationService
import '../widgets/health_metric_card_widget.dart';
import 'activity_screen.dart';
import 'blood_pressure_screen.dart';
import 'blood_sugar_screen.dart';
import 'medication_screen.dart';
import 'settings_screen.dart';

// Unique IDs for the new fixed daily reminders
const int GOOD_MORNING_REMINDER_ID = 200;
const int GOOD_NIGHT_REMINDER_ID = 201;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Variable to track the time of the last back button press
  DateTime? _lastPressedAt;
  bool _isSelectingUser = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProviders();
      _scheduleDailyFixedReminders(); // Schedule the fixed daily reminders
    });
  }

  /// Initializes all health metric providers with the selected user's ID
  /// and then refreshes their data.
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
      _refreshData(); // Load initial data for selected user
    }
  }

  /// Schedules fixed daily notifications for "Good Morning!" and "Good Night!".
  /// These are not conditional on user activity, unlike the specific activity reminders.
  Future<void> _scheduleDailyFixedReminders() async {
    // Schedule "Good Morning!" at 8:00 AM Myanmar Time
    await NotificationService.scheduleDailyActivityNotification(
      id: GOOD_MORNING_REMINDER_ID,
      title: 'Good Morning!',
      body: 'Start your day with a nutritious breakfast',
      scheduledTime: const TimeOfDay(hour: 8, minute: 0),
      // 8:00 AM
      payload: 'good_morning_reminder',
    );
    debugPrint('HomeScreen: Scheduled Good Morning reminder for 8:00 AM.');

    // Schedule "Good Night!" at 11:00 PM Myanmar Time
    await NotificationService.scheduleDailyActivityNotification(
      id: GOOD_NIGHT_REMINDER_ID,
      title: 'Good Night!',
      body: 'Time to sleep',
      scheduledTime: const TimeOfDay(hour: 23, minute: 0),
      // 11:00 PM
      payload: 'good_night_reminder',
    );
    debugPrint('HomeScreen: Scheduled Good Night reminder for 11:00 PM.');

    // Optional: Log all pending notifications to verify
    final pending = await NotificationService.getPendingNotifications();
    debugPrint(
        'HomeScreen: Total pending notifications after fixed reminders setup: ${pending.length}');
    for (var p in pending) {
      debugPrint('  Pending: ID=${p.id}, Title=${p.title}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
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
          // If no users exist, navigate to the user profile creation screen.
          if (!userProvider.hasUsers) {
            return const UserProfileScreen(
              userToEdit: null,
              isDialog: false,
            );
          }
          // If no user is selected or user selection is active, show user selection screen.
          if (userProvider.selectedUser == null || _isSelectingUser) {
            return _buildUserSelectionScreen();
          }
          // Otherwise, show the main home content.
          return _buildHomeContent();
        },
      ),
    );
  }

  /// Builds the user selection screen when multiple users are available.
  Widget _buildUserSelectionScreen() {
    final locals = AppLocalizations.of(context)!;
    final userProvider = Provider.of<UserProvider>(context);
    final canGoBack = userProvider.selectedUser !=
        null; // True if a user was previously selected

    return Scaffold(
      appBar: AppBar(
        leading: canGoBack
            ? IconButton(
                onPressed: () {
                  setState(() {
                    _isSelectingUser = false; // Exit user selection mode
                  });
                },
                icon: const Icon(Icons.arrow_back),
              )
            : null,
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
              trailing: isSelected ? const Icon(Icons.check_circle) : null,
              onTap: () {
                userProvider.selectUser(user);
                _initializeProviders(); // Re-initialize providers for the newly selected user
                if (!canGoBack) {
                  // If coming from an initial no-user state, exit selection
                  setState(() {
                    _isSelectingUser = false;
                  });
                }
              },
            ),
          );
        },
      ),
    );
  }

  /// Builds the main content of the home screen, displaying user greeting and health metrics.
  Widget _buildHomeContent() {
    final locals = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.selectedUser;
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(locals.homeTitle),
        backgroundColor: theme.colorScheme.surface,
        automaticallyImplyLeading: true,
        // Show back button if applicable (e.g., after selecting user)
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
        onRefresh: _refreshData, // Allows pulling down to refresh data
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          // Always allow scrolling even if content is small
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

  /// Builds the greeting card displaying user information.
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
                  setState(() {
                    _isSelectingUser = true; // Enter user selection mode
                  });
                },
                tooltip: locals.switchUser,
              ),
          ],
        ),
      ),
    );
  }

  /// Builds a section with quick stats for blood pressure, blood sugar, and steps.
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
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const BloodPressureScreen()),
                          );
                        },
                        child: _buildStatItem(
                          icon: Icons.monitor_heart,
                          label: locals.bloodPressure,
                          value: bpProvider.latestReading != null
                              ? '${bpProvider.latestReading!.systolic}/${bpProvider.latestReading!.diastolic}'
                              : '--',
                          color: Colors.red.shade600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const BloodSugarScreen()),
                          );
                        },
                        child: _buildStatItem(
                          icon: Icons.bloodtype,
                          label: locals.bloodSugar,
                          value: bsProvider.latestReading != null
                              ? '${bsProvider.latestReading!.glucose.toStringAsFixed(0)}'
                              : '--',
                          color: Colors.blue.shade600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ActivityScreen()),
                          );
                        },
                        child: _buildStatItem(
                          icon: Icons.directions_walk,
                          label: locals.steps,
                          value: activityProvider.latestActivity != null
                              ? '${activityProvider.latestActivity!.steps}'
                              : '0',
                          color: Colors.green.shade600,
                        ),
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

  /// Helper widget to build a single statistic item.
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

  /// Builds the grid of health metric cards.
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
          // Occupy only the space needed
          physics: const NeverScrollableScrollPhysics(),
          // Disable gridview scrolling
          crossAxisCount: 2,
          // 2 columns in the grid
          crossAxisSpacing: 16,
          // Spacing between columns
          mainAxisSpacing: 16,
          // Spacing between rows
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
      // Use Future.wait to load data concurrently for better performance.
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
      debugPrint(
          'HomeScreen: All health data refreshed for user ${selectedUser.id}');
    }
  }
}
