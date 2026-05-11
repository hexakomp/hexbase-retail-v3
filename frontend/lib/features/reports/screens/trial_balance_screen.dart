import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../providers/financial_report_provider.dart';

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
String _apiFmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class TrialBalanceScreen extends ConsumerStatefulWidget {
  const TrialBalanceScreen({super.key});

  @override
  ConsumerState<TrialBalanceScreen> createState() => _TrialBalanceScreenState();
}

class _TrialBalanceScreenState extends ConsumerState<TrialBalanceScreen> {
  DateTime _asOf = DateTime.now();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _asOf,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _asOf = picked);
  }

  void _load() =>
      ref.read(trialBalanceProvider.notifier).load(_apiFmtDate(_asOf));

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trialBalanceProvider);

    return AppScaffold(
      title: 'Trial Balance',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 14),
                    label: Text('As of: ${_fmtDate(_asOf)}'),
                    onPressed: _pickDate,
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
      return const Center(child: Text('Select date and tap Generate'));

    final accounts = state.data!['accounts'] as List<dynamic>? ?? [];
    final totals = state.data!['totals'] as Map<String, dynamic>? ?? {};

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Account')),
                DataColumn(label: Text('Code')),
                DataColumn(label: Text('Debit'), numeric: true),
                DataColumn(label: Text('Credit'), numeric: true),
              ],
              rows: accounts.map((a) {
                final m = a as Map<String, dynamic>;
                return DataRow(
                  cells: [
                    DataCell(Text(m['account_name'] as String? ?? '—')),
                    DataCell(Text(m['account_code'] as String? ?? '—')),
                    DataCell(
                      Text(m['debit'] != null ? '₹${m['debit']}' : '—'),
                    ),
                    DataCell(
                      Text(m['credit'] != null ? '₹${m['credit']}' : '—'),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        Container(
          color: Theme.of(context).colorScheme.primaryContainer,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Dr: ₹${totals['total_debit'] ?? 0}'),
              Text('Cr: ₹${totals['total_credit'] ?? 0}'),
            ],
          ),
        ),
      ],
    );
  }
}
