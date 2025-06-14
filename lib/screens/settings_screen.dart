import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../providers/setting_porvider.dart';
import '../providers/user_provider.dart';
import '../services/database_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final locals = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(locals.settingsTitle),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildAppearanceSection(settingsProvider, locals),
              const SizedBox(height: 24),
              _buildLanguageSection(settingsProvider, locals),
              const SizedBox(height: 24),
              _buildNotificationSection(settingsProvider, locals),
              const SizedBox(height: 24),
              _buildDataSection(locals),
              const SizedBox(height: 24),
              _buildAboutSection(locals),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppearanceSection(
      SettingsProvider provider, AppLocalizations locals) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appearance',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(locals.darkMode),
              subtitle: const Text('Switch between light and dark themes'),
              value: provider.isDarkMode,
              onChanged: (value) => provider.toggleDarkMode(),
              secondary: Icon(
                provider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSection(
      SettingsProvider provider, AppLocalizations locals) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              locals.language,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(locals.english),
              leading: Radio<String>(
                value: 'en',
                groupValue: provider.locale.languageCode,
                onChanged: (value) {
                  if (value != null) {
                    provider.setLocale(Locale(value));
                  }
                },
              ),
              onTap: () => provider.setLocale(const Locale('en')),
            ),
            ListTile(
              title: Text(locals.myanmar),
              leading: Radio<String>(
                value: 'my',
                groupValue: provider.locale.languageCode,
                onChanged: (value) {
                  if (value != null) {
                    provider.setLocale(Locale(value));
                  }
                },
              ),
              onTap: () => provider.setLocale(const Locale('my')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSection(
      SettingsProvider provider, AppLocalizations locals) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              locals.notifications,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(locals.notifications),
              subtitle: const Text('Enable medication and health reminders'),
              value: provider.notificationsEnabled,
              onChanged: (value) => provider.toggleNotifications(),
              secondary: const Icon(Icons.notifications),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSection(AppLocalizations locals) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Management',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Export Data'),
              subtitle: const Text('Export your health data'),
              leading: const Icon(Icons.download),
              onTap: _exportData,
            ),
            ListTile(
              title: const Text('Import Data'),
              subtitle: const Text('Import health data from backup'),
              leading: const Icon(Icons.upload),
              onTap: _importData,
            ),
            ListTile(
              title: const Text('Clear All Data'),
              subtitle: const Text('Delete all health data (irreversible)'),
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              onTap: _showClearDataDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(AppLocalizations locals) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              locals.aboutApp,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(locals.appTitle),
              subtitle: Text(locals.version),
              leading: const Icon(Icons.info),
            ),
            ListTile(
              title: Text(locals.offlineMode),
              subtitle: Text(locals.dataStoredLocally),
              leading: const Icon(Icons.offline_bolt),
            ),
            ListTile(
              title: const Text('Privacy'),
              subtitle: Text(locals.yourDataIsSecure),
              leading: const Icon(Icons.privacy_tip),
            ),
          ],
        ),
      ),
    );
  }

  void _exportData() {
    // TODO: Implement data export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export feature coming soon')),
    );
  }

  void _importData() {
    // TODO: Implement data import
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Import feature coming soon')),
    );
  }

  void _showClearDataDialog() {
    final locals = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all your health data, user profiles, and settings. This action cannot be undone.\n\nAre you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(locals.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _clearAllData();
            },
            child: const Text('Clear All Data'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllData() async {
    try {
      // Clear database
      await DatabaseService.instance.clearAllData();

      // Clear providers
      if (mounted) {
        Provider.of<UserProvider>(context, listen: false).clearSelectedUser();
        Provider.of<SettingsProvider>(context, listen: false).resetSettings();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data cleared successfully')),
        );

        // Navigate back to setup
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error clearing data: $e')),
        );
      }
    }
  }
}
