import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart'; // Import for debugPrint
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/activity_model.dart';
import '../models/blood_pressure_model.dart';
import '../models/blood_sugar_model.dart';
import '../models/medication_model.dart'; // Ensure this model is updated with notificationType
import '../models/user_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  static DatabaseService get instance => _instance;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'health_tracker.db');
    return await openDatabase(
      path,
      version: 4, // ⭐ UPDATED DATABASE VERSION TO 4 TO TRIGGER MIGRATION ⭐
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    debugPrint('DatabaseService: Running _onCreate for version $version');

    // Create Users table
    await db.execute('''
        CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        age INTEGER NOT NULL,
        gender TEXT NOT NULL,
        weight REAL NOT NULL,
        height REAL NOT NULL,
        photo_path TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        has_diabetes INTEGER  -- <--- ADDED has_diabetes COLUMN
        )
    ''');

    // Create Blood Pressure table
    await db.execute('''
        CREATE TABLE blood_pressure (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        systolic INTEGER NOT NULL,
        diastolic INTEGER NOT NULL,
        date_time INTEGER NOT NULL,
        notes TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
   ''');

    // Create Blood Sugar table
    await db.execute('''
      CREATE TABLE blood_sugar (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      glucose REAL NOT NULL,
      measurement_type TEXT NOT NULL,
      date_time INTEGER NOT NULL,
      notes TEXT,
      created_at INTEGER NOT NULL,
      category TEXT, -- <--- ADDED category COLUMN
      FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
  ''');

    // Create Activities table
    await db.execute('''
      CREATE TABLE activities (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      type TEXT NOT NULL,
      steps INTEGER NOT NULL,
      calories REAL NOT NULL,
      distance REAL NOT NULL,
      duration INTEGER NOT NULL,
      date INTEGER NOT NULL,
      notes TEXT,
      created_at INTEGER NOT NULL,
      FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
   ''');

    // Create Medications table
    await db.execute('''
    CREATE TABLE medications (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    name TEXT NOT NULL,
    dosage TEXT NOT NULL,
    frequency TEXT NOT NULL,
    reminder_times TEXT NOT NULL,
    instructions TEXT,
    is_active INTEGER NOT NULL DEFAULT 1,
    start_date INTEGER NOT NULL,
    end_date INTEGER,
    notes TEXT,
    created_at INTEGER NOT NULL,
    notification_type TEXT NOT NULL DEFAULT 'notification', -- ⭐ NEW: ADDED THIS COLUMN HERE ⭐
    FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
    )
  ''');

    // Create indexes for better performance
    await db.execute(
        'CREATE INDEX idx_blood_pressure_user_date ON blood_pressure (user_id, date_time)');
    await db.execute(
        'CREATE INDEX idx_blood_sugar_user_date ON blood_sugar (user_id, date_time)');
    await db.execute(
        'CREATE INDEX idx_activities_user_date ON activities (user_id, date)');
    await db.execute(
        'CREATE INDEX idx_medications_user_active ON medications (user_id, is_active)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint(
        'DatabaseService: Running _onUpgrade from $oldVersion to $newVersion');

    if (oldVersion < 3) {
      // These migrations were for version 3 (from an earlier version)
      await db.execute(
          'ALTER TABLE users ADD COLUMN has_diabetes INTEGER DEFAULT 0;');
      debugPrint(
          'Database upgrade (v3): Added has_diabetes column to users table.');

      await db.execute(
          'ALTER TABLE blood_sugar ADD COLUMN category TEXT DEFAULT "unknown";');
      debugPrint(
          'Database upgrade (v3): Added category column to blood_sugar table.');
    }
    // ⭐ NEW MIGRATION FOR VERSION 4 ⭐
    if (oldVersion < 4) {
      // This block will run if upgrading from version 3 to 4, or any version < 4
      await db.execute(
          "ALTER TABLE medications ADD COLUMN notification_type TEXT NOT NULL DEFAULT 'notification';");
      debugPrint(
          'Database upgrade (v4): Added notification_type column to medications table.');
    }
  }

  Future<bool> hasBloodPressureData(String userId) async {
    final db = await database;
    final count = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM blood_pressure WHERE user_id = ?',
      [userId],
    ));
    return (count ?? 0) > 0;
  }

  Future<bool> hasBloodSugarData(String userId) async {
    final db = await database;
    final count = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM blood_sugar WHERE user_id = ?',
      [userId],
    ));
    return (count ?? 0) > 0;
  }

  Future<bool> hasDailyActivityData(String userId) async {
    final db = await database;
    final count = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM activities WHERE user_id = ?',
      [userId],
    ));
    return (count ?? 0) > 0;
  }

  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<List<User>> getUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => User.fromMap(maps[i]));
  }

  Future<User?> getUser(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    final existingUser = await getUser(user.id);
    final String? oldPhotoPath = existingUser?.photoPath;

    // Perform the update
    final int rowsAffected = await db.update(
      'users',
      user.toMap(), // user.toMap() now includes has_diabetes
      where: 'id = ?',
      whereArgs: [user.id],
    );

    if (rowsAffected > 0 && oldPhotoPath != null && oldPhotoPath.isNotEmpty) {
      if (user.photoPath == null ||
          user.photoPath!.isEmpty ||
          user.photoPath != oldPhotoPath) {
        final file = File(oldPhotoPath);
        if (await file.exists()) {
          try {
            await file.delete();
            debugPrint('Deleted old photo file: $oldPhotoPath');
          } catch (e) {
            debugPrint('Error deleting old photo file: $oldPhotoPath - $e');
          }
        } else {
          debugPrint('Old photo file not found at path: $oldPhotoPath');
        }
      }
    }
    return rowsAffected;
  }

  Future<int> deleteUser(String id) async {
    final db = await database;
    final user = await getUser(id);
    if (user != null && user.photoPath != null) {
      final file = File(user.photoPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
    return await db.delete(
      'users',
      where: 'id = ? ',
      whereArgs: [id],
    );
  }

  Future<int> insertBloodPressure(BloodPressure bloodPressure) async {
    final db = await database;
    return await db.insert('blood_pressure', bloodPressure.toMap());
  }

  Future<List<BloodPressure>> getBloodPressureReadings(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'blood_pressure',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date_time DESC',
    );
    return List.generate(maps.length, (i) => BloodPressure.fromMap(maps[i]));
  }

  Future<List<Map<String, dynamic>>> getBloodPressureDataForExport(
      String? userId) async {
    if (userId == null) return [];
    final db = await database;
    return await db.query(
      'blood_pressure',
      columns: ['date_time', 'systolic', 'diastolic', 'notes'],
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date_time ASC', // Order chronologically for reports
    );
  }

  Future<BloodPressure?> getBloodPressure(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'blood_pressure',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return BloodPressure.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateBloodPressure(BloodPressure bloodPressure) async {
    final db = await database;
    return await db.update(
      'blood_pressure',
      bloodPressure.toMap(),
      where: 'id = ?',
      whereArgs: [bloodPressure.id],
    );
  }

  Future<int> deleteBloodPressure(String id) async {
    final db = await database;
    return await db.delete(
      'blood_pressure',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertBloodSugar(BloodSugar bloodSugar) async {
    final db = await database;
    return await db.insert('blood_sugar', bloodSugar.toMap());
  }

  Future<List<BloodSugar>> getBloodSugarReadings(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'blood_sugar',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date_time DESC',
    );
    return List.generate(maps.length, (i) => BloodSugar.fromMap(maps[i]));
  }

  Future<List<Map<String, dynamic>>> getBloodSugarDataForExport(
      String? userId) async {
    // Changed to String?
    if (userId == null) return [];
    final db = await database;
    return await db.query(
      'blood_sugar',
      columns: [
        'date_time',
        'glucose',
        'measurement_type',
        'category',
        'notes'
      ],
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date_time ASC',
    );
  }

  Future<BloodSugar?> getBloodSugar(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'blood_sugar',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return BloodSugar.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateBloodSugar(BloodSugar bloodSugar) async {
    final db = await database;
    return await db.update(
      'blood_sugar',
      bloodSugar.toMap(),
      where: 'id = ?',
      whereArgs: [bloodSugar.id],
    );
  }

  Future<int> deleteBloodSugar(String id) async {
    final db = await database;
    return await db.delete(
      'blood_sugar',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertActivity(Activity activity) async {
    final db = await database;
    return await db.insert('activities', activity.toMap());
  }

  Future<List<Activity>> getActivities(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'activities',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Activity.fromMap(maps[i]));
  }

  Future<List<Map<String, dynamic>>> getDailyActivityDataForExport(
      String? userId) async {
    if (userId == null) return [];
    final db = await database;
    return await db.query(
      'activities',
      columns: [
        'date',
        'type',
        'steps',
        'calories',
        'distance',
        'duration',
        'notes'
      ],
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date ASC',
    );
  }

  Future<Activity?> getActivity(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'activities',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Activity.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateActivity(Activity activity) async {
    final db = await database;
    return await db.update(
      'activities',
      activity.toMap(),
      where: 'id = ?',
      whereArgs: [activity.id],
    );
  }

  Future<int> deleteActivity(String id) async {
    final db = await database;
    return await db.delete(
      'activities',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertMedication(Medication medication) async {
    final db = await database;
    // medication.toMap() now correctly includes 'notification_type'
    return await db.insert('medications', medication.toMap());
  }

  Future<List<Medication>> getMedications(String userId) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'medications',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) => Medication.fromMap(maps[i]));
  }

  Future<Medication?> getMedication(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'medications',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Medication.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateMedication(Medication medication) async {
    final db = await database;
    // medication.toMap() now correctly includes 'notification_type'
    return await db.update(
      'medications',
      medication.toMap(),
      where: 'id = ?',
      whereArgs: [medication.id],
    );
  }

  Future<int> deleteMedication(String id) async {
    final db = await database;
    return await db.delete(
      'medications',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<BloodPressure>> getBloodPressureReadingsInDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'blood_pressure',
      where: 'user_id = ? AND date_time >= ? AND date_time <= ?',
      whereArgs: [
        userId,
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
      ],
      orderBy: 'date_time DESC',
    );
    return List.generate(maps.length, (i) => BloodPressure.fromMap(maps[i]));
  }

  Future<List<BloodSugar>> getBloodSugarReadingsInDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'blood_sugar',
      where: 'user_id = ? AND date_time >= ? AND date_time <= ?',
      whereArgs: [
        userId,
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
      ],
      orderBy: 'date_time DESC',
    );

    return List.generate(maps.length, (i) => BloodSugar.fromMap(maps[i]));
  }

  Future<List<Activity>> getActivitiesInDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'activities',
      where: 'user_id = ? AND date >= ? AND date <= ?',
      whereArgs: [
        userId,
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
      ],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) => Activity.fromMap(maps[i]));
  }

  Future<List<Medication>> getActiveMedications(String userId) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'medications',
      where: 'user_id = ? AND is_active = 1',
      whereArgs: [userId],
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) => Medication.fromMap(maps[i]));
  }

// Database maintenance

  Future<void> deleteAllUserData(String userId) async {
    final db = await database;
    final user = await getUser(userId);
    if (user != null && user.photoPath != null) {
      final file = File(user.photoPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }

    await db.transaction((txn) async {
      await txn
          .delete('blood_pressure', where: 'user_id = ?', whereArgs: [userId]);
      await txn
          .delete('blood_sugar', where: 'user_id = ?', whereArgs: [userId]);
      await txn.delete('activities', where: 'user_id = ?', whereArgs: [userId]);
      await txn
          .delete('medications', where: 'user_id = ?', whereArgs: [userId]);
      await txn.delete('users', where: 'id = ?', whereArgs: [userId]);
    });
  }

  Future<void> clearAllData() async {
    final db = await database;
    final users = await getUsers();
    for (final user in users) {
      if (user.photoPath != null) {
        final file = File(user.photoPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
    }
    await db.transaction((txn) async {
      await txn.delete('blood_pressure');
      await txn.delete('blood_sugar');
      await txn.delete('activities');
      await txn.delete('medications');
      await txn.delete('users');
    });
  }

  Future<Map<String, int>> getDatabaseStats() async {
    final db = await database;
    final userCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM users'),
        ) ??
        0;
    final bpCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM blood_pressure'),
        ) ??
        0;
    final bsCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM blood_sugar'),
        ) ??
        0;
    final activityCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM activities'),
        ) ??
        0;
    final medicationCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM medications'),
        ) ??
        0;

    return {
      'users': userCount,
      'bloodPressureReadings': bpCount,
      'bloodSugarReadings': bsCount,
      'activities': activityCount,
      'medications': medicationCount,
    };
  }

  Future<void> closeDatabase() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  Future<void> resetDatabase() async {
    await closeDatabase();
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'health_tracker.db');
    await deleteDatabase(path);
    _database = await _initDatabase(); // Re-initialize the database
  }
}
