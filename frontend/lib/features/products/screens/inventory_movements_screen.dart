import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../providers/product_provider.dart';

class InventoryMovementsScreen extends ConsumerStatefulWidget {
  final int productId;
  final String productName;
  const InventoryMovementsScreen({
    super.key,
    required this.productId,
    this.productName = '',
  });

  @override
  ConsumerState<InventoryMovementsScreen> createState() =>
      _InventoryMovementsScreenState();
}

class _InventoryMovementsScreenState
    extends ConsumerState<InventoryMovementsScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _items = [];
  int _currentPage = 1;
  int _lastPage = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({int page = 1}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(productRepositoryProvider);
      final res = await repo.movements(widget.productId, page: page);
      final data = res['data'] as List<dynamic>;
      final meta = res['meta'] as Map<String, dynamic>;
      setState(() {
        _items = data;
        _currentPage = meta['current_page'] as int? ?? page;
        _lastPage = meta['last_page'] as int? ?? 1;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  IconData _typeIcon(String? type) {
    switch (type) {
      case 'sale':
        return Icons.arrow_upward;
      case 'purchase':
        return Icons.arrow_downward;
      case 'adjustment':
        return Icons.tune;
      case 'return_in':
        return Icons.undo;
      case 'return_out':
        return Icons.redo;
      default:
        return Icons.swap_horiz;
    }
  }

  Color _typeColor(String? type) {
    switch (type) {
      case 'sale':
        return Colors.red;
      case 'purchase':
        return Colors.green;
      case 'return_in':
        return Colors.blue;
      case 'return_out':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.productName.isEmpty
          ? 'Inventory Movements'
          : 'Movements: ${widget.productName}',
      body: Column(
        children: [
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _load(),
              child: _items.isEmpty && !_loading
                  ? const Center(child: Text('No movements found'))
                  : ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (ctx, i) {
                        final m = _items[i] as Map<String, dynamic>;
                        final type = m['movement_type'] as String?;
                        final qty = (m['quantity'] as num?)?.toDouble() ?? 0;
                        final isOut = type == 'sale' || type == 'return_out';
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _typeColor(type).withOpacity(0.15),
                            child: Icon(
                              _typeIcon(type),
                              color: _typeColor(type),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  type?.replaceAll('_', ' ').toUpperCase() ??
                                      'MOVEMENT',
                                ),
                              ),
                              Text(
                                '${isOut ? '-' : '+'}${qty.abs().toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isOut ? Colors.red : Colors.green,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            [
                              if (m['reference_no'] != null) m['reference_no'],
                              if (m['narration'] != null) m['narration'],
                              m['movement_date'] ?? '',
                            ].where((s) => s.toString().isNotEmpty).join(' · '),
                          ),
                          trailing: m['balance'] != null
                              ? Chip(
                                  label: Text(
                                    'Bal: ${(m['balance'] as num).toStringAsFixed(0)}',
                                  ),
                                  padding: EdgeInsets.zero,
                                )
                              : null,
                        );
                      },
                    ),
            ),
          ),
          if (_lastPage > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentPage > 1
                      ? () => _load(page: _currentPage - 1)
                      : null,
                ),
                Text('$_currentPage / $_lastPage'),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _currentPage < _lastPage
                      ? () => _load(page: _currentPage + 1)
                      : null,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
