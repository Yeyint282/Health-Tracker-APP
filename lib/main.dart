import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:health_life/providers/setting_porvider.dart';
import 'package:health_life/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'providers/activity_provider.dart';
import 'providers/blood_pressure_provider.dart';
import 'providers/blood_sugar_provider.dart';
import 'providers/medication_provider.dart';
import 'providers/user_provider.dart';
import 'screens/splash_screen.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await NotificationService.initialize();
  await NotificationService.requestPermissions();
  await DatabaseService.instance.database;
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(
    const DigitalHealthTrackerApp(),
  );
}

class DigitalHealthTrackerApp extends StatelessWidget {
  const DigitalHealthTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => BloodPressureProvider()),
        ChangeNotifierProvider(create: (_) => BloodSugarProvider()),
        ChangeNotifierProvider(create: (_) => ActivityProvider()),
        ChangeNotifierProvider(create: (_) => MedicationProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return MaterialApp(
            title: 'Digital Health Tracker',
            debugShowCheckedModeBanner: false,
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            locale: settings.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', ''),
              Locale('my', ''),
            ],
            home: const SplashScreen(),
          );
        },
      ),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4CAF50), // Green for health
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardTheme(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4CAF50), // Green for health
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        systemOverlayStyle:
            SystemUiOverlayStyle.light, // Light icons on dark app bar
      ),
      cardTheme: CardTheme(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
}
