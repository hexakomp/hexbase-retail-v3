import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../providers/gst_report_provider.dart';

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
String _apiFmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class TaxRegisterScreen extends ConsumerStatefulWidget {
  final bool isSales;
  const TaxRegisterScreen({super.key, this.isSales = true});

  @override
  ConsumerState<TaxRegisterScreen> createState() => _TaxRegisterScreenState();
}

class _TaxRegisterScreenState extends ConsumerState<TaxRegisterScreen> {
  DateTime _fromDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _toDate = DateTime.now();

  StateNotifierProvider<TaxRegisterNotifier, GstReportState> get _provider =>
      widget.isSales ? salesTaxRegisterProvider : purchaseTaxRegisterProvider;

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
        .read(_provider.notifier)
        .load(fromDate: _apiFmtDate(_fromDate), toDate: _apiFmtDate(_toDate));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_provider);
    final title = widget.isSales
        ? 'Sales Tax Register'
        : 'Purchase Tax Register';

    return AppScaffold(
      title: title,
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
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                state.error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Expanded(
            child: state.data == null
                ? const Center(
                    child: Text('Select date range and tap Generate'),
                  )
                : _buildTable(state.data!),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(Map<String, dynamic> data) {
    final rows = data['rows'] as List<dynamic>? ?? [];
    if (rows.isEmpty)
      return const Center(child: Text('No records for selected period'));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        columns: const [
          DataColumn(label: Text('Invoice #')),
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Party')),
          DataColumn(label: Text('Taxable'), numeric: true),
          DataColumn(label: Text('CGST'), numeric: true),
          DataColumn(label: Text('SGST'), numeric: true),
          DataColumn(label: Text('IGST'), numeric: true),
          DataColumn(label: Text('Total'), numeric: true),
        ],
        rows: rows.map((r) {
          final m = r as Map<String, dynamic>;
          return DataRow(
            cells: [
              DataCell(Text(m['invoice_number'] as String? ?? '—')),
              DataCell(Text(m['invoice_date'] as String? ?? '—')),
              DataCell(Text(m['party_name'] as String? ?? '—')),
              DataCell(Text('₹${m['taxable_amount'] ?? 0}')),
              DataCell(Text('₹${m['cgst_amount'] ?? 0}')),
              DataCell(Text('₹${m['sgst_amount'] ?? 0}')),
              DataCell(Text('₹${m['igst_amount'] ?? 0}')),
              DataCell(Text('₹${m['total_amount'] ?? 0}')),
            ],
          );
        }).toList(),
      ),
    );
  }
}
