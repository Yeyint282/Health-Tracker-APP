import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
import 'user_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
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
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
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
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Text(user.name.substring(0, 1).toUpperCase()),
              ),
              title: Text(user.name),
              subtitle: Text(
                  '${locals.age}: ${user.age}, ${locals.gender}: ${user.gender}'),
              onTap: () {
                userProvider.selectUser(user);
                _initializeProviders();
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const UserProfileScreen(
                userToEdit: null,
                isDialog: false,
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHomeContent() {
    final locals = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(locals.homeTitle),
        backgroundColor: theme.colorScheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const UserProfileScreen(
                    isDialog: false,
                    userToEdit: null,
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
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                user.name.substring(0, 1).toUpperCase(),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${locals.welcome}, ${user.name}!',
                    style: theme.textTheme.titleLarge,
                  ),
                  Text(
                    '${locals.age}: ${user.age} • ${locals.gender}: ${user.gender}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (userProvider.users.length > 1)
              IconButton(
                icon: const Icon(Icons.swap_horiz),
                onPressed: () {
                  userProvider.clearSelectedUser();
                },
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              locals.today,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Consumer4<BloodPressureProvider, BloodSugarProvider,
                ActivityProvider, MedicationProvider>(
              builder: (context, bpProvider, bsProvider, activityProvider,
                  medicationProvider, child) {
                return Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        icon: Icons.favorite,
                        label: locals.bloodPressure,
                        value: bpProvider.latestReading != null
                            ? '${bpProvider.latestReading!.systolic}/${bpProvider.latestReading!.diastolic}'
                            : '--',
                        color: Colors.red,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        icon: Icons.water_drop,
                        label: locals.bloodSugar,
                        value: bsProvider.latestReading != null
                            ? '${bsProvider.latestReading!.glucose.toStringAsFixed(0)}'
                            : '--',
                        color: Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        icon: Icons.directions_walk,
                        label: locals.steps,
                        value: activityProvider.latestActivity != null
                            ? '${activityProvider.latestActivity!.steps}'
                            : '0',
                        color: Colors.green,
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
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall,
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
          style: Theme.of(context).textTheme.titleLarge,
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
              icon: Icons.favorite,
              color: Colors.red,
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
              icon: Icons.water_drop,
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BloodSugarScreen()),
                );
              },
            ),
            HealthMetricCard(
              title: locals.dailyActivity,
              icon: Icons.directions_walk,
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ActivityScreen()),
                );
              },
            ),
            HealthMetricCard(
              title: locals.medications,
              icon: Icons.medication,
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MedicationScreen()),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

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
