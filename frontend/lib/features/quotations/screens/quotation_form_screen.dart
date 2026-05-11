import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/searchable_dropdown.dart';
import '../../customers/providers/customer_provider.dart';
import '../../products/providers/product_provider.dart';
import '../providers/quotation_provider.dart';

class QuotationFormScreen extends ConsumerStatefulWidget {
  final int? quotationId;
  const QuotationFormScreen({super.key, this.quotationId});

  @override
  ConsumerState<QuotationFormScreen> createState() =>
      _QuotationFormScreenState();
}

class _QuotationFormScreenState extends ConsumerState<QuotationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _saving = false;
  String? _error;

  Map<String, dynamic>? _selectedCustomer;
  final _validUntil = TextEditingController();
  final _notes = TextEditingController();
  final _termsConditions = TextEditingController();

  final List<_LineData> _lines = [];

  bool get _isEdit => widget.quotationId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _loadQuotation();
  }

  Future<void> _loadQuotation() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(quotationRepositoryProvider);
      final res = await repo.get(widget.quotationId!);
      final d = res['data'] as Map<String, dynamic>;
      final customer = d['customer'] as Map<String, dynamic>?;
      if (customer != null) _selectedCustomer = customer;
      _validUntil.text = d['valid_until'] as String? ?? '';
      _notes.text = d['notes'] as String? ?? '';
      _termsConditions.text = d['terms_conditions'] as String? ?? '';

      final lines = d['lines'] as List<dynamic>? ?? [];
      for (final l in lines) {
        final line = l as Map<String, dynamic>;
        final product = line['product'] as Map<String, dynamic>?;
        _lines.add(
          _LineData(
            productId: line['product_id'] as int?,
            productName: product?['name'] as String? ?? '',
            description: line['description'] as String? ?? '',
            quantity: (line['quantity'] as num?)?.toDouble() ?? 1,
            unitPrice: (line['unit_price'] as num?)?.toDouble() ?? 0,
            gstRate: (line['gst_rate'] as num?)?.toInt() ?? 0,
            discountPercent:
                (line['discount_percent'] as num?)?.toDouble() ?? 0,
          ),
        );
      }
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _addLine() => setState(() => _lines.add(_LineData()));
  void _removeLine(int i) => setState(() => _lines.removeAt(i));

  double get _grandTotal => _lines.fold(0.0, (sum, l) => sum + l.total);

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomer == null) {
      setState(() => _error = 'Please select a customer');
      return;
    }
    if (_lines.isEmpty) {
      setState(() => _error = 'Add at least one line item');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repo = ref.read(quotationRepositoryProvider);
      final data = {
        'customer_id': _selectedCustomer!['id'],
        'valid_until': _validUntil.text.trim(),
        'notes': _notes.text.trim(),
        'terms_conditions': _termsConditions.text.trim(),
        'lines': _lines.map((l) => l.toJson()).toList(),
      };
      if (_isEdit) {
        await repo.update(widget.quotationId!, data);
      } else {
        await repo.create(data);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _validUntil.dispose();
    _notes.dispose();
    _termsConditions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: _isEdit ? 'Edit Quotation' : 'New Quotation',
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
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ),

                  // Customer picker
                  SearchableDropdown<Map<String, dynamic>>(
                    label: 'Customer',
                    hint: 'Search customer…',
                    value: _selectedCustomer,
                    displayText: (c) => c['name'] as String? ?? '',
                    onSearch: (query) async {
                      final repo = ref.read(customerRepositoryProvider);
                      final res = await repo.list(search: query, perPage: 10);
                      return (res['data'] as List<dynamic>)
                          .map((c) => c as Map<String, dynamic>)
                          .toList();
                    },
                    onSelected: (c) => setState(() => _selectedCustomer = c),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _validUntil,
                    decoration: const InputDecoration(
                      labelText: 'Valid Until *',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(
                          const Duration(days: 30),
                        ),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (d != null) {
                        _validUntil.text = d.toIso8601String().split('T').first;
                      }
                    },
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Line items header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Line Items',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add Line'),
                        onPressed: _addLine,
                      ),
                    ],
                  ),

                  for (int i = 0; i < _lines.length; i++)
                    _LineItemCard(
                      key: ValueKey(i),
                      data: _lines[i],
                      index: i,
                      onRemove: () => _removeLine(i),
                      onChanged: () => setState(() {}),
                      productSearch: (q) async {
                        final repo = ref.read(productRepositoryProvider);
                        final res = await repo.list(search: q, perPage: 10);
                        return (res['data'] as List<dynamic>)
                            .map((p) => p as Map<String, dynamic>)
                            .toList();
                      },
                    ),

                  if (_lines.isNotEmpty) ...[
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Grand Total: ',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '? ${_grandTotal.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  TextFormField(
                    controller: _notes,
                    decoration: const InputDecoration(labelText: 'Notes'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _termsConditions,
                    decoration: const InputDecoration(
                      labelText: 'Terms & Conditions',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _isEdit ? 'Update Quotation' : 'Create Quotation',
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

// -- Line Data Model -----------------------------------------------------------

class _LineData {
  int? productId;
  String productName;
  String description;
  double quantity;
  double unitPrice;
  int gstRate;
  double discountPercent;

  _LineData({
    this.productId,
    this.productName = '',
    this.description = '',
    this.quantity = 1,
    this.unitPrice = 0,
    this.gstRate = 0,
    this.discountPercent = 0,
  });

  double get total {
    final base = quantity * unitPrice * (1 - discountPercent / 100);
    return base * (1 + gstRate / 100);
  }

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'description': description,
    'quantity': quantity,
    'unit_price': unitPrice,
    'gst_rate': gstRate,
    'discount_percent': discountPercent,
  };
}

// -- Line Item Card ------------------------------------------------------------

class _LineItemCard extends ConsumerStatefulWidget {
  final _LineData data;
  final int index;
  final VoidCallback onRemove;
  final VoidCallback onChanged;
  final Future<List<Map<String, dynamic>>> Function(String query) productSearch;

  const _LineItemCard({
    super.key,
    required this.data,
    required this.index,
    required this.onRemove,
    required this.onChanged,
    required this.productSearch,
  });

  @override
  ConsumerState<_LineItemCard> createState() => _LineItemCardState();
}

class _LineItemCardState extends ConsumerState<_LineItemCard> {
  late TextEditingController _qty;
  late TextEditingController _price;
  late TextEditingController _desc;
  late TextEditingController _disc;

  @override
  void initState() {
    super.initState();
    _qty = TextEditingController(text: widget.data.quantity.toString());
    _price = TextEditingController(text: widget.data.unitPrice.toString());
    _desc = TextEditingController(text: widget.data.description);
    _disc = TextEditingController(text: widget.data.discountPercent.toString());
  }

  @override
  void dispose() {
    _qty.dispose();
    _price.dispose();
    _desc.dispose();
    _disc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Item ${widget.index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '? ${widget.data.total.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: widget.onRemove,
                ),
              ],
            ),
            SearchableDropdown<Map<String, dynamic>>(
              label: 'Product',
              hint: 'Search product…',
              value: widget.data.productId != null
                  ? {
                      'id': widget.data.productId,
                      'name': widget.data.productName,
                    }
                  : null,
              displayText: (p) => p['name'] as String? ?? '',
              onSearch: widget.productSearch,
              onSelected: (p) {
                if (p == null) return;
                setState(() {
                  widget.data.productId = p['id'] as int?;
                  widget.data.productName = p['name'] as String? ?? '';
                  final price =
                      (p['selling_price'] as num?)?.toDouble() ??
                      widget.data.unitPrice;
                  widget.data.unitPrice = price;
                  widget.data.gstRate =
                      (p['gst_rate'] as num?)?.toInt() ?? widget.data.gstRate;
                  _price.text = price.toString();
                });
                widget.onChanged();
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _desc,
              decoration: const InputDecoration(
                labelText: 'Description',
                isDense: true,
              ),
              onChanged: (v) {
                widget.data.description = v;
                widget.onChanged();
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _qty,
                    decoration: const InputDecoration(
                      labelText: 'Qty',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      widget.data.quantity = double.tryParse(v) ?? 1;
                      widget.onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _price,
                    decoration: const InputDecoration(
                      labelText: 'Price',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      widget.data.unitPrice = double.tryParse(v) ?? 0;
                      widget.onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: widget.data.gstRate,
                    decoration: const InputDecoration(
                      labelText: 'GST%',
                      isDense: true,
                    ),
                    items: [0, 5, 12, 18, 28]
                        .map(
                          (r) => DropdownMenuItem(value: r, child: Text('$r%')),
                        )
                        .toList(),
                    onChanged: (v) {
                      setState(() => widget.data.gstRate = v ?? 0);
                      widget.onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _disc,
                    decoration: const InputDecoration(
                      labelText: 'Disc%',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      widget.data.discountPercent = double.tryParse(v) ?? 0;
                      widget.onChanged();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
