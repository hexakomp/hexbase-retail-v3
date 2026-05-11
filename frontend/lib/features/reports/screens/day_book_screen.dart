import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../providers/financial_report_provider.dart';

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
String _apiFmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class DayBookScreen extends ConsumerStatefulWidget {
  const DayBookScreen({super.key});

  @override
  ConsumerState<DayBookScreen> createState() => _DayBookScreenState();
}

class _DayBookScreenState extends ConsumerState<DayBookScreen> {
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _toDate = DateTime.now();

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null)
      setState(() => isFrom ? _fromDate = picked : _toDate = picked);
  }

  void _load() => ref
      .read(dayBookProvider.notifier)
      .load(_apiFmtDate(_fromDate), _apiFmtDate(_toDate));

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dayBookProvider);

    return AppScaffold(
      title: 'Day Book',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 14),
                    label: Text(_fmtDate(_fromDate)),
                    onPressed: () => _pickDate(isFrom: true),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('to'),
                ),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 14),
                    label: Text(_fmtDate(_toDate)),
                    onPressed: () => _pickDate(isFrom: false),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _load, child: const Text('Generate')),
              ],
            ),
          ),
          if (state.isLoading) const LinearProgressIndicator(),
          Expanded(child: _buildBody(state)),
        ],
      ),
    );
  }

  Widget _buildBody(FinancialReportState state) {
    if (state.error != null)
      return Center(
        child: Text(
          'Error: ${state.error}',
          style: const TextStyle(color: Colors.red),
        ),
      );
    if (state.data == null)
      return const Center(child: Text('Select date range and tap Generate'));

    final entries = state.data!['entries'] as List<dynamic>? ?? [];
    if (entries.isEmpty)
      return const Center(child: Text('No entries for selected period'));

    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (ctx, i) {
        final e = entries[i] as Map<String, dynamic>;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          child: ListTile(
            leading: CircleAvatar(
              radius: 18,
              child: Text(
                (e['voucher_type'] as String? ?? 'X')
                    .substring(0, 1)
                    .toUpperCase(),
                style: const TextStyle(fontSize: 12),
              ),
            ),
            title: Text(
              '${e['voucher_number'] ?? ''} — ${e['narration'] ?? ''}',
            ),
            subtitle: Text(
              '${e['voucher_date'] ?? ''} · ${e['voucher_type'] ?? ''}',
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Dr: ₹${e['debit_total'] ?? 0}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'Cr: ₹${e['credit_total'] ?? 0}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class CashBookScreen extends ConsumerStatefulWidget {
  const CashBookScreen({super.key});

  @override
  ConsumerState<CashBookScreen> createState() => _CashBookScreenState();
}

class _CashBookScreenState extends ConsumerState<CashBookScreen> {
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _toDate = DateTime.now();

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null)
      setState(() => isFrom ? _fromDate = picked : _toDate = picked);
  }

  void _load() => ref
      .read(cashBookProvider.notifier)
      .load(_apiFmtDate(_fromDate), _apiFmtDate(_toDate));

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cashBookProvider);

    return AppScaffold(
      title: 'Cash Book',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 14),
                    label: Text(_fmtDate(_fromDate)),
                    onPressed: () => _pickDate(isFrom: true),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('to'),
                ),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 14),
                    label: Text(_fmtDate(_toDate)),
                    onPressed: () => _pickDate(isFrom: false),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _load, child: const Text('Generate')),
              ],
            ),
          ),
          if (state.isLoading) const LinearProgressIndicator(),
          Expanded(child: _buildBody(state)),
        ],
      ),
    );
  }

  Widget _buildBody(FinancialReportState state) {
    if (state.error != null)
      return Center(
        child: Text(
          'Error: ${state.error}',
          style: const TextStyle(color: Colors.red),
        ),
      );
    if (state.data == null)
      return const Center(child: Text('Select date range and tap Generate'));

    final entries = state.data!['entries'] as List<dynamic>? ?? [];
    final openingBalance = state.data!['opening_balance'] ?? 0;
    final closingBalance = state.data!['closing_balance'] ?? 0;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.blue.shade50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Opening: ₹$openingBalance'),
              Text(
                'Closing: ₹$closingBalance',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Expanded(
          child: entries.isEmpty
              ? const Center(child: Text('No entries for selected period'))
              : ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (ctx, i) {
                    final e = entries[i] as Map<String, dynamic>;
                    final isReceipt = (e['entry_type'] as String?) == 'receipt';
                    return ListTile(
                      leading: Icon(
                        isReceipt ? Icons.arrow_downward : Icons.arrow_upward,
                        color: isReceipt ? Colors.green : Colors.red,
                      ),
                      title: Text(e['narration'] as String? ?? '—'),
                      subtitle: Text(e['entry_date'] as String? ?? ''),
                      trailing: Text(
                        '₹${e['amount'] ?? 0}',
                        style: TextStyle(
                          color: isReceipt ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
