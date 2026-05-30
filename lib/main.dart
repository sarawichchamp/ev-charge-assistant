import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/repositories/automation_repository.dart';
import 'data/repositories/history_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'services/automation_service.dart';
import 'services/export_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settingsRepository = SettingsRepository();
  final historyRepository = HistoryRepository();
  final automationRepository = AutomationRepository();
  final automationService = AutomationService();
  final exportService = ExportService();

  await Future.wait([
    settingsRepository.initialize(),
    historyRepository.initialize(),
    automationRepository.initialize(),
    automationService.initialize(),
  ]);

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: settingsRepository),
        Provider.value(value: historyRepository),
        Provider.value(value: automationRepository),
        Provider.value(value: automationService),
        Provider.value(value: exportService),
      ],
      child: const EvChargeAssistantApp(),
    ),
  );
}
