import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/app_settings.dart';
import '../../data/repositories/settings_repository.dart';
import '../training/training_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _batteryController;
  late TextEditingController _powerController;
  late TextEditingController _priceController;
  bool _didLoadInitialValues = false;
  int _targetSoc = 80;
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _batteryController = TextEditingController();
    _powerController = TextEditingController();
    _priceController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoadInitialValues) {
      return;
    }
    final settings = context.read<SettingsRepository>().settings;
    _batteryController.text = settings.batteryCapacityKwh.toString();
    _powerController.text = settings.chargePowerKw.toString();
    _priceController.text = settings.pricePerKwh.toString();
    _targetSoc = settings.defaultTargetSoc;
    _themeMode = settings.themeMode;
    _didLoadInitialValues = true;
  }

  @override
  void dispose() {
    _batteryController.dispose();
    _powerController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final repository = context.read<SettingsRepository>();
    await repository.save(
      AppSettings(
        batteryCapacityKwh: double.parse(_batteryController.text),
        chargePowerKw: double.parse(_powerController.text),
        pricePerKwh: double.parse(_priceController.text),
        defaultTargetSoc: _targetSoc,
        themeMode: _themeMode,
      ),
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved locally.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _batteryController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Battery Capacity (kWh)'),
              validator: _requiredNumber,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _powerController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Charge Power (kW)'),
              validator: _requiredNumber,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Electricity Price per kWh'),
              validator: _requiredNumber,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<int>(
              value: _targetSoc,
              decoration: const InputDecoration(labelText: 'Default Target SOC'),
              items: const [70, 80, 90, 100]
                  .map((value) => DropdownMenuItem(value: value, child: Text('$value%')))
                  .toList(),
              onChanged: (value) => setState(() => _targetSoc = value ?? 80),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ThemeMode>(
              value: _themeMode,
              decoration: const InputDecoration(labelText: 'Theme'),
              items: const [
                DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
              ],
              onChanged: (value) => setState(() => _themeMode = value ?? ThemeMode.system),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _save,
              child: const Text('Save Settings'),
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TrainingScreen()),
                );
              },
              icon: const Icon(Icons.touch_app_outlined),
              label: const Text('Automation Mapping'),
            ),
          ],
        ),
      ),
    );
  }

  String? _requiredNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    if (double.tryParse(value) == null) {
      return 'Enter a valid number';
    }
    return null;
  }
}
