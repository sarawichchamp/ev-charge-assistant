import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/automation_mapping.dart';

class AutomationRepository extends ChangeNotifier {
  AutomationMapping _mapping = const AutomationMapping(
    mode: AutomationMode.textRecognition,
    points: [],
  );

  AutomationMapping get mapping => _mapping;

  static const requiredKeys = [
    ('deepal_battery_percentage', 'Battery Percentage'),
    ('deepal_vehicle_status_button', 'Vehicle Status Button'),
    ('deepal_odometer', 'Odometer'),
    ('fuelio_odometer_field', 'Fuelio Odometer Field'),
    ('fuelio_energy_field', 'Fuelio Energy Field'),
    ('fuelio_price_field', 'Fuelio Price Field'),
    ('fuelio_confirm_button', 'Fuelio Confirm Button'),
    ('fuelio_save_button', 'Fuelio Save Button'),
  ];

  Future<void> initialize() async {
    final db = await AppDatabase.instance.database;
    final pointRows = await db.query('automation_mapping');
    final modeRows = await db.query('automation_mode', where: 'id = ?', whereArgs: [1]);

    _mapping = AutomationMapping(
      mode: modeRows.isEmpty
          ? AutomationMode.textRecognition
          : AutomationMode.values.firstWhere(
              (mode) => mode.name == modeRows.first['mode'],
              orElse: () => AutomationMode.textRecognition,
            ),
      points: pointRows.map(AutomationPoint.fromMap).toList(),
    );

    if (modeRows.isEmpty) {
      await db.insert('automation_mode', {'id': 1, 'mode': _mapping.mode.name});
    }
  }

  Future<void> saveMode(AutomationMode mode) async {
    _mapping = _mapping.copyWith(mode: mode);
    final db = await AppDatabase.instance.database;
    await db.update('automation_mode', {'mode': mode.name}, where: 'id = ?', whereArgs: [1]);
    notifyListeners();
  }

  Future<void> savePoint(AutomationPoint point) async {
    final db = await AppDatabase.instance.database;
    await db.insert(
      'automation_mapping',
      point.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    final updated = [..._mapping.points.where((item) => item.key != point.key), point]
      ..sort((a, b) => a.label.compareTo(b.label));
    _mapping = _mapping.copyWith(points: updated);
    notifyListeners();
  }

  AutomationPoint? pointByKey(String key) {
    for (final point in _mapping.points) {
      if (point.key == key) {
        return point;
      }
    }
    return null;
  }
}
