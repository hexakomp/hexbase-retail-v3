import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../providers/purchase_order_provider.dart';

class PurchaseOrderFormScreen extends ConsumerStatefulWidget {
  final int? orderId;
  const PurchaseOrderFormScreen({super.key, this.orderId});

  @override
  ConsumerState<PurchaseOrderFormScreen> createState() =>
      _PurchaseOrderFormScreenState();
}

class _PurchaseOrderFormScreenState
    extends ConsumerState<PurchaseOrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _orderData;

  final _dateController = TextEditingController();
  final _deliveryDateController = TextEditingController();
  final _notesController = TextEditingController();
  String _supplyType = 'intra';
  final List<Map<String, dynamic>> _lines = [];

  bool get _isEdit => widget.orderId != null;
  bool get _isDraft => _orderData == null || _orderData!['status'] == 'draft';

  @override
  void initState() {
    super.initState();
    if (_isEdit) _loadOrder();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _deliveryDateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadOrder() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(purchaseOrderRepositoryProvider);
      final data = await repo.get(widget.orderId!);
      final order = data['data'] as Map<String, dynamic>;
      setState(() {
        _orderData = order;
        _dateController.text = (order['po_date'] as String).substring(0, 10);
        if (order['expected_delivery_date'] != null) {
          _deliveryDateController.text =
              (order['expected_delivery_date'] as String).substring(0, 10);
        }
        _notesController.text = order['notes'] as String? ?? '';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lines.isEmpty) {
      setState(() => _error = 'Add at least one line item.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(purchaseOrderRepositoryProvider);
      final payload = {
        'po_date': _dateController.text,
        if (_deliveryDateController.text.isNotEmpty)
          'expected_delivery_date': _deliveryDateController.text,
        'notes': _notesController.text,
        'supply_type': _supplyType,
        'lines': _lines,
      };
      if (_isEdit) {
        await repo.update(widget.orderId!, payload);
      } else {
        await repo.create(payload);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _cancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Purchase Order'),
        content: const Text(
          'Are you sure you want to cancel this purchase order?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(purchaseOrderRepositoryProvider).cancel(widget.orderId!);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _addLine() => setState(() {
    _lines.add({
      'product_id': 0,
      'description': '',
      'quantity': 1.0,
      'unit_price': 0.0,
      'gst_rate': 18,
    });
  });

  @override
  Widget build(BuildContext context) {
    final status = _orderData?['status'] as String? ?? 'draft';

    return AppScaffold(
      title: _isEdit ? 'Purchase Order' : 'New Purchase Order',
      actions: _isEdit && _isDraft
          ? [
              IconButton(
                icon: const Icon(Icons.cancel_outlined),
                tooltip: 'Cancel PO',
                onPressed: _cancelOrder,
              ),
            ]
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null)
                    Card(
                      color: Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  if (status != 'draft')
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        border: Border.all(color: Colors.blue),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Status: ${status.toUpperCase()}',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  TextFormField(
                    controller: _dateController,
                    decoration: const InputDecoration(
                      labelText: 'PO Date *',
                      hintText: 'YYYY-MM-DD',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: !_isDraft,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                    onTap: () async {
                      if (!_isDraft) return;
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null)
                        _dateController.text =
                            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _deliveryDateController,
                    decoration: const InputDecoration(
                      labelText: 'Expected Delivery Date',
                      hintText: 'YYYY-MM-DD',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: !_isDraft,
                    onTap: () async {
                      if (!_isDraft) return;
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null)
                        _deliveryDateController.text =
                            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _supplyType,
                    decoration: const InputDecoration(
                      labelText: 'Supply Type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'intra',
                        child: Text('Intra-State'),
                      ),
                      DropdownMenuItem(
                        value: 'inter',
                        child: Text('Inter-State'),
                      ),
                      DropdownMenuItem(value: 'import', child: Text('Import')),
                    ],
                    onChanged: _isDraft
                        ? (v) => setState(() => _supplyType = v!)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: !_isDraft,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Line Items',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (_isDraft)
                        TextButton.icon(
                          onPressed: _addLine,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Line'),
                        ),
                    ],
                  ),
                  ..._lines.asMap().entries.map((entry) {
                    final i = entry.key;
                    final line = entry.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Line ${i + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                if (_isDraft)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () =>
                                        setState(() => _lines.removeAt(i)),
                                  ),
                              ],
                            ),
                            TextFormField(
                              initialValue: line['description'] as String,
                              decoration: const InputDecoration(
                                labelText: 'Description',
                              ),
                              onChanged: (v) => _lines[i]['description'] = v,
                              readOnly: !_isDraft,
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue: line['quantity'].toString(),
                                    decoration: const InputDecoration(
                                      labelText: 'Qty',
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (v) => _lines[i]['quantity'] =
                                        double.tryParse(v) ?? 1.0,
                                    readOnly: !_isDraft,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: line['unit_price'].toString(),
                                    decoration: const InputDecoration(
                                      labelText: 'Rate',
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (v) => _lines[i]['unit_price'] =
                                        double.tryParse(v) ?? 0.0,
                                    readOnly: !_isDraft,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: line['gst_rate'].toString(),
                                    decoration: const InputDecoration(
                                      labelText: 'GST%',
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (v) => _lines[i]['gst_rate'] =
                                        int.tryParse(v) ?? 18,
                                    readOnly: !_isDraft,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  if (_isDraft)
                    ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save),
                      label: Text(_isEdit ? 'Update' : 'Save Draft'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
