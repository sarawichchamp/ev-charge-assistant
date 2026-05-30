import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../data/models/charge_session.dart';
import '../../data/repositories/history_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../services/automation_service.dart';
import '../../services/charge_calculator.dart';
import '../../widgets/section_card.dart';

class WorkflowScreen extends StatefulWidget {
  const WorkflowScreen({super.key});

  @override
  State<WorkflowScreen> createState() => _WorkflowScreenState();
}

class _WorkflowScreenState extends State<WorkflowScreen> {
  final _calculator = const ChargeCalculator();
  final _quickTargets = const [70, 80, 90, 100];

  int? _currentSoc;
  int? _odometerKm;
  int? _targetSoc;
  DateTime _finishTime = DateTime.now().add(const Duration(hours: 4));
  ChargeCalculation? _calculation;
  bool _isBusy = false;
  String? _statusMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _targetSoc ??= context.read<SettingsRepository>().settings.defaultTargetSoc;
  }

  Future<void> _startChargingProcess() async {
    setState(() {
      _isBusy = true;
      _statusMessage = 'Preparing permissions and automation session...';
    });

    final automation = context.read<AutomationService>();
    final settings = context.read<SettingsRepository>().settings;
    final history = context.read<HistoryRepository>();

    try {
      final permissionsGranted = await automation.ensurePermissions();
      if (!permissionsGranted) {
        setState(() {
          _statusMessage =
              'Required accessibility, overlay, or foreground permissions are missing.';
          _isBusy = false;
        });
        return;
      }

      setState(() => _statusMessage = 'Launching Deepal and reading SOC + odometer...');
      await automation.launchDeepal();
      final result = await automation.readSocAndOdometer();

      if (!result.success || result.currentSoc == null || result.odometerKm == null) {
        setState(() {
          _statusMessage = result.message ?? 'Automation could not read data from Deepal.';
          _isBusy = false;
        });
        return;
      }

      final calculation = _calculator.calculate(
        batteryCapacityKwh: settings.batteryCapacityKwh,
        chargePowerKw: settings.chargePowerKw,
        currentSoc: result.currentSoc!,
        targetSoc: _targetSoc ?? settings.defaultTargetSoc,
        finishTime: _finishTime,
      );

      setState(() {
        _currentSoc = result.currentSoc;
        _odometerKm = result.odometerKm;
        _calculation = calculation;
        _statusMessage = 'Opening Fuelio and filling the charging entry...';
      });

      await automation.launchFuelio();
      final filled = await automation.fillFuelio(
        AutomationFillRequest(
          odometerKm: result.odometerKm!,
          energyKwh: calculation.energyRequiredKwh,
          pricePerKwh: settings.pricePerKwh,
          targetSoc: _targetSoc ?? settings.defaultTargetSoc,
          currentSoc: result.currentSoc!,
        ),
      );

      if (!filled) {
        setState(() {
          _statusMessage =
              'Fuelio form fill was incomplete. Review the fields manually in Fuelio.';
          _isBusy = false;
        });
        return;
      }

      if (!mounted) {
        return;
      }

      final confirmed = await _showConfirmationDialog(
        currentSoc: result.currentSoc!,
        targetSoc: _targetSoc ?? settings.defaultTargetSoc,
        odometerKm: result.odometerKm!,
        energyRequired: calculation.energyRequiredKwh,
        pricePerKwh: settings.pricePerKwh,
      );

      if (!confirmed) {
        setState(() {
          _statusMessage = 'Charging flow cancelled before saving Fuelio entry.';
          _isBusy = false;
        });
        return;
      }

      final saved = await automation.saveFuelioEntry();
      if (!saved) {
        setState(() {
          _statusMessage =
              'Fuelio entry was filled, but the save action needs manual review.';
          _isBusy = false;
        });
        return;
      }

      await history.add(
        ChargeSession(
          createdAt: DateTime.now(),
          currentSoc: result.currentSoc!,
          targetSoc: _targetSoc ?? settings.defaultTargetSoc,
          odometerKm: result.odometerKm!,
          energyRequiredKwh: calculation.energyRequiredKwh,
          pricePerKwh: settings.pricePerKwh,
          startTime: calculation.startTime,
          finishTime: calculation.finishTime,
        ),
      );

      setState(() {
        _statusMessage = 'Fuelio saved. Open Deepal to set the schedule wheel picker.';
        _isBusy = false;
      });
    } catch (error) {
      setState(() {
        _statusMessage = 'Charging process failed: $error';
        _isBusy = false;
      });
    }
  }

  Future<bool> _showConfirmationDialog({
    required int currentSoc,
    required int targetSoc,
    required int odometerKm,
    required double energyRequired,
    required double pricePerKwh,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Fuelio Entry'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SOC: $currentSoc% -> $targetSoc%'),
                Text('Odometer: ${Formatters.odometer(odometerKm)} km'),
                Text('Energy: ${Formatters.kwh(energyRequired)} kWh'),
                Text('Price/kWh: ${Formatters.currency(pricePerKwh)}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _pickFinishTime() async {
    final initial = TimeOfDay.fromDateTime(_finishTime);
    final selected = await showTimePicker(context: context, initialTime: initial);
    if (selected == null) {
      return;
    }
    final now = DateTime.now();
    final pickedDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      selected.hour,
      selected.minute,
    );
    setState(() {
      _finishTime = pickedDateTime.isBefore(now)
          ? pickedDateTime.add(const Duration(days: 1))
          : pickedDateTime;
    });
    _recalculate();
  }

  void _recalculate() {
    final settings = context.read<SettingsRepository>().settings;
    if (_currentSoc == null || _targetSoc == null) {
      return;
    }
    setState(() {
      _calculation = _calculator.calculate(
        batteryCapacityKwh: settings.batteryCapacityKwh,
        chargePowerKw: settings.chargePowerKw,
        currentSoc: _currentSoc!,
        targetSoc: _targetSoc!,
        finishTime: _finishTime,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final settings = context.watch<SettingsRepository>().settings;
    final calculation = _calculation;

    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          title: const Text('EV Charge Assistant'),
          actions: [
            IconButton(
              tooltip: 'Open Deepal',
              onPressed: () => context.read<AutomationService>().openDeepalForSchedule(),
              icon: const Icon(Icons.open_in_new),
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        scheme.primaryContainer,
                        scheme.tertiaryContainer,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'One-tap charging workflow',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Read Deepal, calculate charge timing, prepare Fuelio, and store the session offline.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: _isBusy ? null : _startChargingProcess,
                        icon: _isBusy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.bolt),
                        label: const Text('Start Charging Process'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  title: 'Charging Inputs',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Battery ${settings.batteryCapacityKwh} kWh  •  Charge Power ${settings.chargePowerKw} kW  •  Price ${Formatters.currency(settings.pricePerKwh)} /kWh',
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _quickTargets.map((target) {
                          return ChoiceChip(
                            label: Text('$target%'),
                            selected: _targetSoc == target,
                            onSelected: (_) {
                              setState(() => _targetSoc = target);
                              _recalculate();
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Desired finish time'),
                        subtitle: Text(Formatters.time(_finishTime)),
                        trailing: FilledButton.tonal(
                          onPressed: _pickFinishTime,
                          child: const Text('Choose'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  title: 'Live Session',
                  child: Column(
                    children: [
                      _MetricRow(
                        label: 'Current SOC',
                        value: _currentSoc == null ? '--' : '${_currentSoc!}%',
                      ),
                      _MetricRow(
                        label: 'Target SOC',
                        value: _targetSoc == null ? '--' : '${_targetSoc!}%',
                      ),
                      _MetricRow(
                        label: 'Odometer',
                        value: _odometerKm == null
                            ? '--'
                            : '${Formatters.odometer(_odometerKm!)} km',
                      ),
                      _MetricRow(
                        label: 'Energy Required',
                        value: calculation == null
                            ? '--'
                            : '${Formatters.kwh(calculation.energyRequiredKwh)} kWh',
                      ),
                      _MetricRow(
                        label: 'Price per kWh',
                        value: Formatters.currency(settings.pricePerKwh),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  title: 'Schedule',
                  child: calculation == null
                      ? const Text('Schedule appears here after the first successful SOC read.')
                      : Column(
                          children: [
                            _ScheduleRow(label: 'START', value: Formatters.time(calculation.startTime)),
                            const SizedBox(height: 12),
                            _ScheduleRow(label: 'FINISH', value: Formatters.time(calculation.finishTime)),
                            const SizedBox(height: 20),
                            FilledButton.tonalIcon(
                              onPressed: () => context
                                  .read<AutomationService>()
                                  .openDeepalForSchedule(),
                              icon: const Icon(Icons.schedule_send),
                              label: const Text('Open Deepal'),
                            ),
                          ],
                        ),
                ),
                if (_statusMessage != null) ...[
                  const SizedBox(height: 16),
                  SectionCard(
                    title: 'Status',
                    child: Text(_statusMessage!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.6),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
        ],
      ),
    );
  }
}
