import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const _databaseName = 'ev_charge_assistant.db';
  static const _databaseVersion = 1;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    final directory = await getApplicationDocumentsDirectory();
    final databasePath = path.join(directory.path, _databaseName);
    _database = await openDatabase(
      databasePath,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
    return _database!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        battery_capacity_kwh REAL NOT NULL,
        charge_power_kw REAL NOT NULL,
        price_per_kwh REAL NOT NULL,
        default_target_soc INTEGER NOT NULL,
        theme_mode TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE charge_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        created_at TEXT NOT NULL,
        current_soc INTEGER NOT NULL,
        target_soc INTEGER NOT NULL,
        odometer_km INTEGER NOT NULL,
        energy_required_kwh REAL NOT NULL,
        price_per_kwh REAL NOT NULL,
        start_time TEXT NOT NULL,
        finish_time TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE automation_mapping (
        key TEXT PRIMARY KEY,
        label TEXT NOT NULL,
        x REAL NOT NULL,
        y REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE automation_mode (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        mode TEXT NOT NULL
      )
    ''');
  }
}
