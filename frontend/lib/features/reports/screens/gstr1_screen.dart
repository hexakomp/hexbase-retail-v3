import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../providers/gst_report_provider.dart';

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
String _apiFmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class Gstr1Screen extends ConsumerStatefulWidget {
  const Gstr1Screen({super.key});

  @override
  ConsumerState<Gstr1Screen> createState() => _Gstr1ScreenState();
}

class _Gstr1ScreenState extends ConsumerState<Gstr1Screen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _fromDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _toDate = DateTime.now();

  final _tabs = const [
    Tab(text: 'B2B'),
    Tab(text: 'B2C'),
    Tab(text: 'HSN Summary'),
    Tab(text: 'Tax Liability'),
  ];

  final _sections = ['b2b', 'b2c', 'hsn-summary', 'tax-liability'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _loadReport(_tabController.index);
    }
  }

  void _loadReport(int tabIndex) {
    ref
        .read(gstr1Provider.notifier)
        .load(
          fromDate: _apiFmtDate(_fromDate),
          toDate: _apiFmtDate(_toDate),
          section: _sections[tabIndex],
        );
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gstr1Provider);

    return AppScaffold(
      title: 'GSTR-1',
      body: Column(
        children: [
          // Date range picker
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
                FilledButton(
                  onPressed: () => _loadReport(_tabController.index),
                  child: const Text('Generate'),
                ),
              ],
            ),
          ),
          TabBar(controller: _tabController, isScrollable: true, tabs: _tabs),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _sections
                  .map((s) => _ReportBody(state: state))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportBody extends StatelessWidget {
  final GstReportState state;
  const _ReportBody({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.isLoading)
      return const Center(child: CircularProgressIndicator());
    if (state.error != null) {
      return Center(
        child: Text(
          'Error: ${state.error}',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }
    if (state.data == null) {
      return const Center(child: Text('Select date range and tap Generate'));
    }

    final items = state.data!['items'] as List<dynamic>? ?? [];
    if (items.isEmpty) {
      return const Center(child: Text('No data for selected period'));
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final item = items[i] as Map<String, dynamic>;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            title: Text(
              item['gstin'] as String? ?? item['rate']?.toString() ?? '—',
            ),
            subtitle: Text(
              'Taxable: ₹${item['taxable_value'] ?? item['taxable_amount'] ?? 0}',
            ),
            trailing: Text(
              'Tax: ₹${item['igst_amount'] ?? ((item['cgst_amount'] ?? 0) + (item['sgst_amount'] ?? 0))}',
            ),
          ),
        );
      },
    );
  }
}
