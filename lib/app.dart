import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/models/automation_mapping.dart';
import 'data/repositories/automation_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'services/automation_service.dart';
import 'features/home/home_screen.dart';

class EvChargeAssistantApp extends StatefulWidget {
  const EvChargeAssistantApp({super.key});

  @override
  State<EvChargeAssistantApp> createState() => _EvChargeAssistantAppState();
}

class _EvChargeAssistantAppState extends State<EvChargeAssistantApp> {
  StreamSubscription<dynamic>? _automationSubscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _automationSubscription ??=
        context.read<AutomationService>().events.listen(_handleAutomationEvent);
  }

  Future<void> _handleAutomationEvent(dynamic event) async {
    if (event is! Map || event['type'] != 'mappingSaved') {
      return;
    }

    final mappingKey = event['mappingKey'] as String?;
    final x = (event['x'] as num?)?.toDouble();
    final y = (event['y'] as num?)?.toDouble();
    if (mappingKey == null || x == null || y == null) {
      return;
    }

    final label = AutomationRepository.requiredKeys
        .firstWhere(
          (entry) => entry.$1 == mappingKey,
          orElse: () => (mappingKey, mappingKey),
        )
        .$2;

    await context.read<AutomationRepository>().savePoint(
          AutomationPoint(
            key: mappingKey,
            label: label,
            x: x,
            y: y,
          ),
        );
  }

  @override
  void dispose() {
    _automationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsRepository>().settings;
    return MaterialApp(
      title: 'EV Charge Assistant',
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const HomeScreen(),
    );
  }
}
