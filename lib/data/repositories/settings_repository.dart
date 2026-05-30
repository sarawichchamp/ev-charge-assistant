import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/app_settings.dart';

class SettingsRepository extends ChangeNotifier {
  AppSettings _settings = AppSettings.defaults();

  AppSettings get settings => _settings;

  Future<void> initialize() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('settings', where: 'id = ?', whereArgs: [1]);
    if (rows.isEmpty) {
      await db.insert('settings', {'id': 1, ..._settings.toMap()});
      return;
    }
    _settings = AppSettings.fromMap(rows.first);
  }

  Future<void> save(AppSettings settings) async {
    _settings = settings;
    final db = await AppDatabase.instance.database;
    await db.update(
      'settings',
      settings.toMap(),
      where: 'id = ?',
      whereArgs: [1],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    notifyListeners();
  }
}
