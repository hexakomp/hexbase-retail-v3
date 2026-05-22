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

  @override
  void dispose() {
    _validUntil.dispose();
    _notes.dispose();
    _termsConditions.dispose();
    super.dispose();
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

      final rawLines = d['lines'] as List<dynamic>? ?? [];
      _lines.clear();
      for (final l in rawLines) {
        final line = l as Map<String, dynamic>;
        final product = line['product'] as Map<String, dynamic>?;
        _lines.add(
          _LineData(
            productId: line['product_id'] as int?,
            productName: product?['name'] as String? ?? '',
            description: line['description'] as String? ?? '',
            quantity: (line['quantity'] as num?)?.toDouble() ?? 1.0,
            unitPrice: (line['unit_price'] as num?)?.toDouble() ?? 0.0,
            discountPercent:
                (line['discount_percent'] as num?)?.toDouble() ?? 0.0,
            gstRate: (line['gst_rate'] as num?)?.toInt() ?? 0,
            hsnSac: line['hsn_sac'] as String? ?? '',
            unit: line['unit'] as String? ?? '',
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomer == null) {
      setState(() => _error = 'Please select a customer.');
      return;
    }
    if (_lines.isEmpty) {
      setState(() => _error = 'Add at least one line item.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repo = ref.read(quotationRepositoryProvider);
      final payload = <String, dynamic>{
        'customer_id': _selectedCustomer!['id'],
        'valid_until': _validUntil.text.isEmpty ? null : _validUntil.text,
        'notes': _notes.text.isEmpty ? null : _notes.text,
        'terms_conditions': _termsConditions.text.isEmpty
            ? null
            : _termsConditions.text,
        'lines': _lines
            .map(
              (l) => {
                'product_id': l.productId,
                'description': l.description,
                'quantity': l.quantity,
                'unit_price': l.unitPrice,
                'discount_percent': l.discountPercent,
                'gst_rate': l.gstRate,
                'hsn_sac': l.hsnSac,
                'unit': l.unit,
              },
            )
            .toList(),
      };

      if (_isEdit) {
        await repo.update(widget.quotationId!, payload);
      } else {
        await repo.create(payload);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  Future<List<Map<String, dynamic>>> _searchCustomers(String q) async {
    final repo = ref.read(customerRepositoryProvider);
    final res = await repo.list(search: q, perPage: 20);
    final data = res['data'] as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> _searchProducts(String q) async {
    final repo = ref.read(productRepositoryProvider);
    final res = await repo.list(search: q, perPage: 20);
    final data = res['data'] as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  void _addLine() => setState(() => _lines.add(_LineData()));

  void _removeLine(int index) => setState(() => _lines.removeAt(index));

  double get _taxableTotal => _lines.fold(0.0, (s, l) => s + l.taxableAmount);

  double get _gstTotal => _lines.fold(0.0, (s, l) => s + l.gstAmount);

  double get _grandTotal => _taxableTotal + _gstTotal;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: _isEdit ? 'Edit Quotation' : 'New Quotation',
      actions: [
        if (_saving)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save'),
          ),
      ],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Error banner
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

                  // Customer selector
                  SearchableDropdown<Map<String, dynamic>>(
                    label: 'Customer *',
                    hint: 'Search customer…',
                    value: _selectedCustomer,
                    displayText: (c) => c['name'] as String? ?? '',
                    onSearch: _searchCustomers,
                    onSelected: (c) => setState(() => _selectedCustomer = c),
                  ),
                  const SizedBox(height: 12),

                  // Valid Until
                  TextFormField(
                    controller: _validUntil,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Valid Until',
                      hintText: 'YYYY-MM-DD',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate:
                            DateTime.tryParse(_validUntil.text) ??
                            DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        _validUntil.text =
                            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Notes
                  TextFormField(
                    controller: _notes,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),

                  // Terms & Conditions
                  TextFormField(
                    controller: _termsConditions,
                    decoration: const InputDecoration(
                      labelText: 'Terms & Conditions',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),

                  // Line items header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Line Items',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      TextButton.icon(
                        onPressed: _addLine,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Line'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Line items
                  ..._lines.asMap().entries.map((entry) {
                    final i = entry.key;
                    final line = entry.value;
                    return _LineItemCard(
                      key: ValueKey(i),
                      index: i,
                      line: line,
                      onRemove: () => _removeLine(i),
                      onChanged: () => setState(() {}),
                      searchProducts: _searchProducts,
                    );
                  }),

                  const SizedBox(height: 16),

                  // Totals
                  if (_lines.isNotEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _TotalRow(
                              label: 'Taxable Amount',
                              value: _taxableTotal,
                            ),
                            _TotalRow(label: 'GST', value: _gstTotal),
                            const Divider(),
                            _TotalRow(
                              label: 'Grand Total',
                              value: _grandTotal,
                              bold: true,
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.save),
                    label: Text(_isEdit ? 'Update Quotation' : 'Save Draft'),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

// ── Line Data ─────────────────────────────────────────────────────────────────

class _LineData {
  int? productId;
  String productName;
  String description;
  double quantity;
  double unitPrice;
  double discountPercent;
  int gstRate;
  String hsnSac;
  String unit;

  _LineData({
    this.productId,
    this.productName = '',
    this.description = '',
    this.quantity = 1.0,
    this.unitPrice = 0.0,
    this.discountPercent = 0.0,
    this.gstRate = 18,
    this.hsnSac = '',
    this.unit = '',
  });

  double get taxableAmount =>
      quantity * unitPrice * (1 - discountPercent / 100);
  double get gstAmount => taxableAmount * gstRate / 100;
  double get lineTotal => taxableAmount + gstAmount;
}

// ── Line Item Card ─────────────────────────────────────────────────────────────

class _LineItemCard extends StatefulWidget {
  final int index;
  final _LineData line;
  final VoidCallback onRemove;
  final VoidCallback onChanged;
  final Future<List<Map<String, dynamic>>> Function(String) searchProducts;

  const _LineItemCard({
    super.key,
    required this.index,
    required this.line,
    required this.onRemove,
    required this.onChanged,
    required this.searchProducts,
  });

  @override
  State<_LineItemCard> createState() => _LineItemCardState();
}

class _LineItemCardState extends State<_LineItemCard> {
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _discCtrl;
  late final TextEditingController _gstCtrl;
  late final TextEditingController _hsnCtrl;
  late final TextEditingController _unitCtrl;
  late final TextEditingController _descCtrl;

  @override
  void initState() {
    super.initState();
    final l = widget.line;
    _qtyCtrl = TextEditingController(text: l.quantity.toString());
    _priceCtrl = TextEditingController(text: l.unitPrice.toString());
    _discCtrl = TextEditingController(text: l.discountPercent.toString());
    _gstCtrl = TextEditingController(text: l.gstRate.toString());
    _hsnCtrl = TextEditingController(text: l.hsnSac);
    _unitCtrl = TextEditingController(text: l.unit);
    _descCtrl = TextEditingController(text: l.description);
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    _discCtrl.dispose();
    _gstCtrl.dispose();
    _hsnCtrl.dispose();
    _unitCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _onProductSelected(Map<String, dynamic>? product) {
    if (product == null) return;
    widget.line.productId = product['id'] as int?;
    widget.line.productName = product['name'] as String? ?? '';
    widget.line.unitPrice =
        (product['selling_price'] as num?)?.toDouble() ?? 0.0;
    widget.line.gstRate = (product['gst_rate'] as num?)?.toInt() ?? 0;
    widget.line.hsnSac = product['hsn_sac'] as String? ?? '';
    widget.line.unit = product['unit'] as String? ?? '';
    _priceCtrl.text = widget.line.unitPrice.toString();
    _gstCtrl.text = widget.line.gstRate.toString();
    _hsnCtrl.text = widget.line.hsnSac;
    _unitCtrl.text = widget.line.unit;
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.line;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Line ${widget.index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Remove',
                  onPressed: widget.onRemove,
                ),
              ],
            ),
            SearchableDropdown<Map<String, dynamic>>(
              label: 'Product',
              hint: 'Search product…',
              value: l.productId != null
                  ? {'id': l.productId, 'name': l.productName}
                  : null,
              displayText: (p) => p['name'] as String? ?? '',
              onSearch: widget.searchProducts,
              onSelected: _onProductSelected,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
              onChanged: (v) {
                l.description = v;
                widget.onChanged();
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _qtyCtrl,
                    decoration: const InputDecoration(labelText: 'Qty'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (v) {
                      l.quantity = double.tryParse(v) ?? 1.0;
                      widget.onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _unitCtrl,
                    decoration: const InputDecoration(labelText: 'Unit'),
                    onChanged: (v) {
                      l.unit = v;
                      widget.onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _priceCtrl,
                    decoration: const InputDecoration(labelText: 'Rate'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (v) {
                      l.unitPrice = double.tryParse(v) ?? 0.0;
                      widget.onChanged();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _discCtrl,
                    decoration: const InputDecoration(labelText: 'Disc %'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (v) {
                      l.discountPercent = double.tryParse(v) ?? 0.0;
                      widget.onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _gstCtrl,
                    decoration: const InputDecoration(labelText: 'GST %'),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      l.gstRate = int.tryParse(v) ?? 0;
                      widget.onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _hsnCtrl,
                    decoration: const InputDecoration(labelText: 'HSN/SAC'),
                    onChanged: (v) {
                      l.hsnSac = v;
                      widget.onChanged();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Line Total: ₹${l.lineTotal.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Total Row ─────────────────────────────────────────────────────────────────

class _TotalRow extends StatelessWidget {
  final String label;
  final double value;
  final bool bold;

  const _TotalRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('₹${value.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }
}
