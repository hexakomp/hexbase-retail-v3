import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../providers/financial_report_provider.dart';

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
String _apiFmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class ProfitLossScreen extends ConsumerStatefulWidget {
  const ProfitLossScreen({super.key});

  @override
  ConsumerState<ProfitLossScreen> createState() => _ProfitLossScreenState();
}

class _ProfitLossScreenState extends ConsumerState<ProfitLossScreen> {
  DateTime _fromDate = DateTime(DateTime.now().year, 4, 1);
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

  void _load() {
    ref
        .read(profitLossProvider.notifier)
        .load(_apiFmtDate(_fromDate), _apiFmtDate(_toDate));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profitLossProvider);

    return AppScaffold(
      title: 'Profit & Loss',
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

    final income = state.data!['income'] as List<dynamic>? ?? [];
    final expenses = state.data!['expenses'] as List<dynamic>? ?? [];
    final netProfit = state.data!['net_profit'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _AccountGroup(
            title: 'Income',
            accounts: income,
            color: Colors.green.shade50,
          ),
          const SizedBox(height: 12),
          _AccountGroup(
            title: 'Expenses',
            accounts: expenses,
            color: Colors.red.shade50,
          ),
          const SizedBox(height: 12),
          Card(
            color: netProfit >= 0 ? Colors.green.shade100 : Colors.red.shade100,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    netProfit >= 0 ? 'Net Profit' : 'Net Loss',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '₹${netProfit.abs()}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: netProfit >= 0
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountGroup extends StatelessWidget {
  final String title;
  final List<dynamic> accounts;
  final Color color;

  const _AccountGroup({
    required this.title,
    required this.accounts,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    double total = 0;
    for (final a in accounts) {
      final m = a as Map<String, dynamic>;
      total += (m['balance'] ?? 0).toDouble();
    }

    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const Divider(),
            ...accounts.map((a) {
              final m = a as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(m['account_name'] as String? ?? '—'),
                    Text('₹${m['balance'] ?? 0}'),
                  ],
                ),
              );
            }),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total $title',
                  style: const TextStyle(fontWeight: FontWeight.bold),
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
