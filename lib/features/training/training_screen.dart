import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/automation_mapping.dart';
import '../../data/repositories/automation_repository.dart';
import '../../services/automation_service.dart';

class TrainingScreen extends StatelessWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<AutomationRepository>();
    final mapping = repository.mapping;

    return Scaffold(
      appBar: AppBar(title: const Text('Automation Mapping')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<AutomationMode>(
            segments: const [
              ButtonSegment(
                value: AutomationMode.textRecognition,
                label: Text('Mode A'),
                icon: Icon(Icons.text_fields),
              ),
              ButtonSegment(
                value: AutomationMode.trainingFallback,
                label: Text('Mode B'),
                icon: Icon(Icons.ads_click),
              ),
            ],
            selected: {mapping.mode},
            onSelectionChanged: (selection) {
              repository.saveMode(selection.first);
              context.read<AutomationService>().saveAutomationMode(selection.first.name);
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'When text recognition fails, switch to fallback mappings and teach each important screen coordinate.',
          ),
          const SizedBox(height: 8),
          const Text(
            'Use the target icon to open the related app first, then tap the exact UI position when the overlay appears.',
          ),
          const SizedBox(height: 16),
          ...AutomationRepository.requiredKeys.map((entry) {
            final point = repository.pointByKey(entry.$1);
            return _MappingTile(
              mappingKey: entry.$1,
              label: entry.$2,
              point: point,
            );
          }),
        ],
      ),
    );
  }
}

class _MappingTile extends StatelessWidget {
  const _MappingTile({
    required this.mappingKey,
    required this.label,
    required this.point,
  });

  final String mappingKey;
  final String label;
  final AutomationPoint? point;

  Future<void> _startCapture(BuildContext context) async {
    final shouldStart = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(label),
            content: const Text(
              'The app will open the related target app. Move to the correct screen if needed, then tap the exact location once the overlay appears.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Start Capture'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldStart || !context.mounted) {
      return;
    }

    await context.read<AutomationService>().openTrainingOverlay(mappingKey);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(label),
        subtitle: Text(
          point == null ? 'Not trained yet' : 'x: ${point!.x}, y: ${point!.y}',
        ),
        trailing: Wrap(
          spacing: 8,
          children: [
            IconButton(
              tooltip: 'Open target app and capture',
              onPressed: () => _startCapture(context),
              icon: const Icon(Icons.filter_center_focus),
            ),
            IconButton(
              tooltip: 'Edit coordinates',
              onPressed: () => _showEditor(context),
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditor(BuildContext context) async {
    final xController = TextEditingController(text: point?.x.toString() ?? '');
    final yController = TextEditingController(text: point?.y.toString() ?? '');
    final repository = context.read<AutomationRepository>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(label),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: xController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'X coordinate'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: yController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Y coordinate'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved == true) {
      final point = AutomationPoint(
        key: mappingKey,
        label: label,
        x: double.tryParse(xController.text) ?? 0,
        y: double.tryParse(yController.text) ?? 0,
      );
      await repository.savePoint(point);
      await context.read<AutomationService>().saveMappingPoint(
            mappingKey: point.key,
            label: point.label,
            x: point.x,
            y: point.y,
          );
    }
  }
}
