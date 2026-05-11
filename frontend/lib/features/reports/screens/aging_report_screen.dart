import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../providers/aging_report_provider.dart';

class AgingReportScreen extends ConsumerStatefulWidget {
  const AgingReportScreen({super.key});

  @override
  ConsumerState<AgingReportScreen> createState() => _AgingReportScreenState();
}

class _AgingReportScreenState extends ConsumerState<AgingReportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  DateTime _asOf = DateTime.now();

  String get _asOfStr =>
      '${_asOf.year}-${_asOf.month.toString().padLeft(2, '0')}-${_asOf.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    ref.read(receivablesAgingProvider.notifier).load(_asOfStr);
    ref.read(payablesAgingProvider.notifier).load(_asOfStr);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _asOf,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _asOf = picked);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Aging Report',
      actions: [
        TextButton.icon(
          onPressed: _pickDate,
          icon: const Icon(Icons.calendar_today, size: 18),
          label: Text(_asOfStr),
        ),
      ],
      body: Column(
        children: [
          TabBar(
            controller: _tab,
            tabs: const [
              Tab(text: 'Receivables'),
              Tab(text: 'Payables'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _AgingTable(
                  key: ValueKey('rec$_asOfStr'),
                  state: ref.watch(receivablesAgingProvider),
                ),
                _AgingTable(
                  key: ValueKey('pay$_asOfStr'),
                  state: ref.watch(payablesAgingProvider),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AgingTable extends StatelessWidget {
  final AgingReportState state;

  const _AgingTable({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      return Center(child: Text('Error: ${state.error}'));
    }
    final buckets = state.items;
    if (buckets.isEmpty) {
      return const Center(child: Text('No outstanding items.'));
    }
    return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.blue.shade50),
              columns: const [
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('0-30'), numeric: true),
                DataColumn(label: Text('31-60'), numeric: true),
                DataColumn(label: Text('61-90'), numeric: true),
                DataColumn(label: Text('>90'), numeric: true),
                DataColumn(label: Text('Total'), numeric: true),
              ],
              rows: [
                ...buckets.map(
                  (b) => DataRow(
                    cells: [
                      DataCell(Text(b.entityName)),
                      DataCell(Text(_fmt(b.current))),
                      DataCell(Text(_fmt(b.days3160))),
                      DataCell(Text(_fmt(b.days6190))),
                      DataCell(
                        Text(
                          _fmt(b.over90),
                          style: b.over90 > 0
                              ? const TextStyle(color: Colors.red)
                              : null,
                        ),
                      ),
                      DataCell(
                        Text(
                          _fmt(b.total),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                // Totals row
                DataRow(
                  color: WidgetStateProperty.all(Colors.blue.shade50),
                  cells: [
                    const DataCell(
                      Text(
                        'TOTAL',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataCell(
                      Text(_fmt(buckets.fold(0.0, (s, b) => s + b.current))),
                    ),
                    DataCell(
                      Text(_fmt(buckets.fold(0.0, (s, b) => s + b.days3160))),
                    ),
                    DataCell(
                      Text(_fmt(buckets.fold(0.0, (s, b) => s + b.days6190))),
                    ),
                    DataCell(
                      Text(_fmt(buckets.fold(0.0, (s, b) => s + b.over90))),
                    ),
                    DataCell(
                      Text(
                        _fmt(buckets.fold(0.0, (s, b) => s + b.total)),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
  }

  String _fmt(double v) => v.toStringAsFixed(2);
}
