import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../providers/setting_porvider.dart';
import '../providers/user_provider.dart';
import '../services/database_service.dart';
import '../services/pdf_export_data_services.dart'; // Import the file containing ExportTimeRange enum

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _hasHealthData = false;
  String? _lastCheckedUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfUserHasData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUserId = userProvider.selectedUser?.id;

    if (currentUserId != _lastCheckedUserId) {
      _checkIfUserHasData();
      _lastCheckedUserId = currentUserId;
    }
  }

  Future<void> _checkIfUserHasData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final selectedUser = userProvider.selectedUser;

    if (selectedUser == null) {
      setState(() {
        _hasHealthData = false;
      });
      return;
    }

    final dbService = DatabaseService.instance;
    final hasBP = await dbService.hasBloodPressureData(selectedUser.id);
    final hasBS = await dbService.hasBloodSugarData(selectedUser.id);
    final hasDA = await dbService.hasDailyActivityData(selectedUser.id);

    if (mounted) {
      setState(() {
        _hasHealthData = hasBP || hasBS || hasDA;
      });
    }
  }

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
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Management',
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(
                'Export Data',
                style: _hasHealthData // Apply style based on data availability
                    ? textTheme.bodyLarge // Enabled style
                    : textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface
                            .withOpacity(0.38)), // Disabled style
              ),
              subtitle: Text(
                'Export your health data as PDF',
                style: _hasHealthData
                    ? textTheme.bodySmall
                    : textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.38)),
              ),
              leading: Icon(
                Icons.download,
                color: _hasHealthData
                    ? colorScheme.onSurface
                    : colorScheme.onSurface.withOpacity(0.38),
              ),
              onTap: _hasHealthData ? _showExportOptionsDialog : null,
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

  void _showExportOptionsDialog() {
    final locals = AppLocalizations.of(context)!;
    showDialog<ExportTimeRange>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(locals.selectExportRange ?? 'Select Export Range'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, ExportTimeRange.oneWeek);
              },
              child: const Text('Last 1 Week'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, ExportTimeRange.twoWeeks);
              },
              child: const Text('Last 2 Weeks'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, ExportTimeRange.threeWeeks);
              },
              child: const Text('Last 3 Weeks'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, ExportTimeRange.oneMonth);
              },
              child: const Text('Last 1 Month'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, ExportTimeRange.all);
              },
              child: const Text('All Records'),
            ),
          ],
        );
      },
    ).then((ExportTimeRange? selectedRange) {
      if (selectedRange != null) {
        _performExport(selectedRange);
      }
    });
  }

  void _performExport(ExportTimeRange timeRange) async {
    final locals = AppLocalizations.of(context)!;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final selectedUser = userProvider.selectedUser;
    if (selectedUser == null || !_hasHealthData) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(selectedUser == null
                ? locals.selectUserToExportData
                : locals.noDataToExport ??
                    'No health data available for export.'),
          ),
        );
      }
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(locals.exportingData),
      ),
    );

    try {
      final dbService = DatabaseService.instance;
      final pdfExportService = PdfExportService();

      // Fetch all data for the selected user (filtering by time range happens inside PdfExportService)
      final bloodPressureData =
          await dbService.getBloodPressureDataForExport(selectedUser.id);
      final bloodSugarData =
          await dbService.getBloodSugarDataForExport(selectedUser.id);
      final dailyActivityData =
          await dbService.getDailyActivityDataForExport(selectedUser.id);

      await pdfExportService.exportHealthDataToPdf(
        bloodPressureData: bloodPressureData,
        bloodSugarData: bloodSugarData,
        dailyActivityData: dailyActivityData,
        userName: selectedUser.name,
        timeRange: timeRange,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(locals.healthDataExportedSuccessfully)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${locals.errorExportingData}: $e'),
          ),
        );
      }
    }
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
        // Re-check data after clearing all data
        _checkIfUserHasData();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data cleared successfully')),
        );

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
