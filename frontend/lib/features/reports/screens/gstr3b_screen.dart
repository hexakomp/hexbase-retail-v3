import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../providers/gst_report_provider.dart';

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
String _apiFmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class Gstr3bScreen extends ConsumerStatefulWidget {
  const Gstr3bScreen({super.key});

  @override
  ConsumerState<Gstr3bScreen> createState() => _Gstr3bScreenState();
}

class _Gstr3bScreenState extends ConsumerState<Gstr3bScreen> {
  DateTime _fromDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _toDate = DateTime.now();

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isFrom)
          _fromDate = picked;
        else
          _toDate = picked;
      });
    }
  }

  void _load() {
    ref
        .read(gstr3bProvider.notifier)
        .load(fromDate: _apiFmtDate(_fromDate), toDate: _apiFmtDate(_toDate));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gstr3bProvider);

    return AppScaffold(
      title: 'GSTR-3B Support',
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

    final data = state.data!;
    final outward = data['outward_supplies'] as Map<String, dynamic>? ?? {};
    final inward = data['inward_supplies'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionCard(
            title: '3.1 Outward Supplies',
            rows: [
              _Row('Taxable', outward['taxable_value']),
              _Row('IGST', outward['igst']),
              _Row('CGST', outward['cgst']),
              _Row('SGST', outward['sgst']),
              _Row('Cess', outward['cess']),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: '4. ITC Available',
            rows: [
              _Row('Taxable', inward['taxable_value']),
              _Row('IGST', inward['igst']),
              _Row('CGST', inward['cgst']),
              _Row('SGST', inward['sgst']),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Net GST Liability',
            rows: [
              _Row('IGST', (outward['igst'] ?? 0) - (inward['igst'] ?? 0)),
              _Row('CGST', (outward['cgst'] ?? 0) - (inward['cgst'] ?? 0)),
              _Row('SGST', (outward['sgst'] ?? 0) - (inward['sgst'] ?? 0)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Row {
  final String label;
  final dynamic value;
  const _Row(this.label, this.value);
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<_Row> rows;
  const _SectionCard({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Card(
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
            ...rows.map(
              (r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(r.label),
                    Text(
                      '₹${(r.value ?? 0).toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
