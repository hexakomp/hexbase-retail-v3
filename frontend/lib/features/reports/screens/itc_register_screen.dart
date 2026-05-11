import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../providers/gst_report_provider.dart';

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
String _apiFmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class ItcRegisterScreen extends ConsumerStatefulWidget {
  const ItcRegisterScreen({super.key});

  @override
  ConsumerState<ItcRegisterScreen> createState() => _ItcRegisterScreenState();
}

class _ItcRegisterScreenState extends ConsumerState<ItcRegisterScreen> {
  DateTime _fromDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
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
        .read(itcRegisterProvider.notifier)
        .load(fromDate: _apiFmtDate(_fromDate), toDate: _apiFmtDate(_toDate));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(itcRegisterProvider);

    return AppScaffold(
      title: 'ITC Register',
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
          Expanded(child: _buildBody(state)),
        ],
      ),
    );
  }

  Widget _buildBody(GstReportState state) {
    if (state.isLoading)
      return const Center(child: CircularProgressIndicator());
    if (state.error != null)
      return Center(
        child: Text(
          'Error: ${state.error}',
          style: const TextStyle(color: Colors.red),
        ),
      );
    if (state.data == null)
      return const Center(child: Text('Select date range and tap Generate'));

    final rows = state.data!['rows'] as List<dynamic>? ?? [];
    if (rows.isEmpty)
      return const Center(child: Text('No ITC entries for selected period'));

    return ListView.builder(
      itemCount: rows.length,
      itemBuilder: (ctx, i) {
        final row = rows[i] as Map<String, dynamic>;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            title: Text(row['vendor_name'] as String? ?? '—'),
            subtitle: Text(
              'Invoice: ${row['invoice_number'] ?? ''} | ${row['invoice_date'] ?? ''}',
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${row['igst_amount'] ?? 0}',
                  style: const TextStyle(fontSize: 11),
                ),
                Text(
                  'CGST+SGST: ₹${(row['cgst_amount'] ?? 0) + (row['sgst_amount'] ?? 0)}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
