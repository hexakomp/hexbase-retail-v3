import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../providers/financial_report_provider.dart';

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
String _apiFmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class BalanceSheetScreen extends ConsumerStatefulWidget {
  const BalanceSheetScreen({super.key});

  @override
  ConsumerState<BalanceSheetScreen> createState() => _BalanceSheetScreenState();
}

class _BalanceSheetScreenState extends ConsumerState<BalanceSheetScreen> {
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
      ref.read(balanceSheetProvider.notifier).load(_apiFmtDate(_asOf));

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(balanceSheetProvider);

    return AppScaffold(
      title: 'Balance Sheet',
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

    final assets = state.data!['assets'] as List<dynamic>? ?? [];
    final liabilities = state.data!['liabilities'] as List<dynamic>? ?? [];
    final equity = state.data!['equity'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _Side(
              title: 'Assets',
              accounts: assets,
              color: Colors.blue.shade50,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                _Side(
                  title: 'Liabilities',
                  accounts: liabilities,
                  color: Colors.orange.shade50,
                ),
                const SizedBox(height: 12),
                _Side(
                  title: 'Equity',
                  accounts: equity,
                  color: Colors.purple.shade50,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Side extends StatelessWidget {
  final String title;
  final List<dynamic> accounts;
  final Color color;

  const _Side({
    required this.title,
    required this.accounts,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    double total = 0;
    for (final a in accounts) {
      total += ((a as Map<String, dynamic>)['balance'] ?? 0).toDouble();
    }

    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            ...accounts.map((a) {
              final m = a as Map<String, dynamic>;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      m['account_name'] as String? ?? '—',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '₹${m['balance'] ?? 0}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              );
            }),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '₹$total',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
