import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/utils/formatters.dart';
import '../../data/models/charge_session.dart';
import '../../data/repositories/history_repository.dart';
import '../../services/export_service.dart';
import '../../widgets/section_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _searchController = TextEditingController();
  HistorySort _sort = HistorySort.newestFirst;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ChargeSession> _applyFilters(List<ChargeSession> sessions) {
    final query = _searchController.text.trim().toLowerCase();
    var filtered = sessions.where((session) {
      if (query.isEmpty) {
        return true;
      }
      return session.odometerKm.toString().contains(query) ||
          session.currentSoc.toString().contains(query) ||
          session.targetSoc.toString().contains(query) ||
          Formatters.dateTime(session.createdAt).toLowerCase().contains(query);
    }).toList();

    switch (_sort) {
      case HistorySort.newestFirst:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case HistorySort.oldestFirst:
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case HistorySort.highestEnergy:
        filtered.sort((a, b) => b.energyRequiredKwh.compareTo(a.energyRequiredKwh));
        break;
      case HistorySort.lowestEnergy:
        filtered.sort((a, b) => a.energyRequiredKwh.compareTo(b.energyRequiredKwh));
        break;
    }
    return filtered;
  }

  Future<void> _export(List<ChargeSession> sessions) async {
    final file = await context.read<ExportService>().exportHistory(sessions);
    await Share.shareXFiles([XFile(file.path)], text: 'EV Charge Assistant history export');
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<HistoryRepository>();
    final items = _applyFilters(repository.items);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            tooltip: 'Export CSV',
            onPressed: repository.items.isEmpty ? null : () => _export(repository.items),
            icon: const Icon(Icons.file_download_outlined),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search by date, SOC, or odometer',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Sort by'),
                const SizedBox(width: 12),
                DropdownButton<HistorySort>(
                  value: _sort,
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() => _sort = value);
                  },
                  items: const [
                    DropdownMenuItem(
                      value: HistorySort.newestFirst,
                      child: Text('Newest first'),
                    ),
                    DropdownMenuItem(
                      value: HistorySort.oldestFirst,
                      child: Text('Oldest first'),
                    ),
                    DropdownMenuItem(
                      value: HistorySort.highestEnergy,
                      child: Text('Highest energy'),
                    ),
                    DropdownMenuItem(
                      value: HistorySort.lowestEnergy,
                      child: Text('Lowest energy'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: items.isEmpty
                  ? const Center(child: Text('No charging history yet.'))
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return SectionCard(
                          title: '${item.currentSoc}% -> ${item.targetSoc}%',
                          trailing: IconButton(
                            tooltip: 'Delete',
                            onPressed: item.id == null
                                ? null
                                : () => repository.delete(item.id!),
                            icon: const Icon(Icons.delete_outline),
                          ),
                          child: Column(
                            children: [
                              _historyRow('Date', Formatters.dateTime(item.createdAt)),
                              _historyRow('Odometer', '${Formatters.odometer(item.odometerKm)} km'),
                              _historyRow('Energy', '${Formatters.kwh(item.energyRequiredKwh)} kWh'),
                              _historyRow('Price', Formatters.currency(item.pricePerKwh)),
                              _historyRow('Start', Formatters.time(item.startTime)),
                              _historyRow('Finish', Formatters.time(item.finishTime)),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _historyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value),
        ],
      ),
    );
  }
}
