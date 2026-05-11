import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../providers/product_provider.dart';
import 'inventory_movements_screen.dart';
import 'stock_adjustment_dialog.dart';

class StockSummaryScreen extends ConsumerStatefulWidget {
  final int productId;
  final String productName;
  const StockSummaryScreen({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  ConsumerState<StockSummaryScreen> createState() => _StockSummaryScreenState();
}

class _StockSummaryScreenState extends ConsumerState<StockSummaryScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _summary;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(productRepositoryProvider);
      final res = await repo.stockSummary(widget.productId);
      setState(() {
        _summary = res['data'] as Map<String, dynamic>?;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppScaffold(
      title: 'Stock: ${widget.productName}',
      actions: [
        IconButton(
          icon: const Icon(Icons.tune),
          tooltip: 'Adjust Stock',
          onPressed: () async {
            final adjusted = await showDialog<bool>(
              context: context,
              builder: (_) => StockAdjustmentDialog(
                productId: widget.productId,
                productName: widget.productName,
              ),
            );
            if (adjusted == true) _load();
          },
        ),
      ],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            )
          : _summary == null
          ? const Center(child: Text('No stock data'))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Stock',
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${(_summary!['current_stock'] as num?)?.toStringAsFixed(2) ?? '0.00'} ${_summary!['unit'] ?? ''}',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color:
                                  (_summary!['current_stock'] as num? ?? 0) <= 0
                                  ? Colors.red
                                  : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    title: 'Valuation',
                    rows: [
                      _InfoRow(
                        'Weighted Avg Cost (WAC)',
                        '₹ ${(_summary!['wac'] as num?)?.toStringAsFixed(2) ?? '-'}',
                      ),
                      _InfoRow(
                        'Stock Value',
                        '₹ ${(_summary!['stock_value'] as num?)?.toStringAsFixed(2) ?? '-'}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    title: 'Thresholds',
                    rows: [
                      _InfoRow(
                        'Reorder Level',
                        '${(_summary!['reorder_level'] as num?)?.toStringAsFixed(0) ?? '-'}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.history),
                    label: const Text('View Movement History'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InventoryMovementsScreen(
                          productId: widget.productId,
                          productName: widget.productName,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<_InfoRow> rows;
  const _InfoCard({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const Divider(),
            ...rows,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
