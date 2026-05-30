import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/charge_session.dart';

enum HistorySort {
  newestFirst,
  oldestFirst,
  highestEnergy,
  lowestEnergy,
}

class HistoryRepository extends ChangeNotifier {
  final List<ChargeSession> _items = [];

  List<ChargeSession> get items => List.unmodifiable(_items);

  Future<void> initialize() async {
    await refresh();
  }

  Future<void> refresh() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('charge_history', orderBy: 'created_at DESC');
    _items
      ..clear()
      ..addAll(rows.map(ChargeSession.fromMap));
    notifyListeners();
  }

  Future<void> add(ChargeSession session) async {
    final db = await AppDatabase.instance.database;
    await db.insert(
      'charge_history',
      session.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await refresh();
  }

  Future<void> delete(int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('charge_history', where: 'id = ?', whereArgs: [id]);
    await refresh();
  }
}
