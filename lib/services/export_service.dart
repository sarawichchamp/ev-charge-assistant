import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../data/models/charge_session.dart';

class ExportService {
  Future<File> exportHistory(List<ChargeSession> sessions) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(path.join(
      directory.path,
      'ev_charge_history_${DateTime.now().millisecondsSinceEpoch}.csv',
    ));

    final rows = <List<Object?>>[
      [
        'DateTime',
        'Current SOC',
        'Target SOC',
        'Odometer (km)',
        'Energy Required (kWh)',
        'Price per kWh',
        'Start Time',
        'Finish Time',
      ],
      ...sessions.map(
        (session) => [
          session.createdAt.toIso8601String(),
          session.currentSoc,
          session.targetSoc,
          session.odometerKm,
          session.energyRequiredKwh.toStringAsFixed(2),
          session.pricePerKwh.toStringAsFixed(2),
          session.startTime.toIso8601String(),
          session.finishTime.toIso8601String(),
        ],
      ),
    ];

    await file.writeAsString(const ListToCsvConverter().convert(rows));
    return file;
  }
}
