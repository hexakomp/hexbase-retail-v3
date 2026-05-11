import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../providers/product_provider.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  final int? productId;
  const ProductFormScreen({super.key, this.productId});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _saving = false;
  String? _error;

  final _name = TextEditingController();
  final _code = TextEditingController();
  final _hsnSac = TextEditingController();
  final _unit = TextEditingController();
  final _purchasePrice = TextEditingController();
  final _sellingPrice = TextEditingController();
  final _reorderLevel = TextEditingController();
  final _description = TextEditingController();
  int _gstRate = 0;
  String _productType = 'goods';

  bool get _isEdit => widget.productId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _loadProduct();
  }

  Future<void> _loadProduct() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(productRepositoryProvider);
      final res = await repo.get(widget.productId!);
      final d = res['data'] as Map<String, dynamic>;
      _name.text = d['name'] ?? '';
      _code.text = d['code'] ?? '';
      _hsnSac.text = d['hsn_sac'] ?? '';
      _unit.text = d['unit'] ?? '';
      _purchasePrice.text = d['purchase_price']?.toString() ?? '';
      _sellingPrice.text = d['selling_price']?.toString() ?? '';
      _reorderLevel.text = d['reorder_level']?.toString() ?? '';
      _description.text = d['description'] ?? '';
      setState(() {
        _gstRate = (d['gst_rate'] as num?)?.toInt() ?? 0;
        _productType = d['product_type'] ?? 'goods';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(productRepositoryProvider);
      final data = {
        'name': _name.text.trim(),
        'code': _code.text.trim(),
        'hsn_sac': _hsnSac.text.trim(),
        'unit': _unit.text.trim(),
        'product_type': _productType,
        'gst_rate': _gstRate,
        'description': _description.text.trim(),
        if (_purchasePrice.text.isNotEmpty)
          'purchase_price': double.tryParse(_purchasePrice.text),
        if (_sellingPrice.text.isNotEmpty)
          'selling_price': double.tryParse(_sellingPrice.text),
        if (_reorderLevel.text.isNotEmpty)
          'reorder_level': double.tryParse(_reorderLevel.text),
      };

      if (_isEdit)
        await repo.update(widget.productId!, data);
      else
        await repo.create(data);

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
    for (final c in [
      _name,
      _code,
      _hsnSac,
      _unit,
      _purchasePrice,
      _sellingPrice,
      _reorderLevel,
      _description,
    ])
      c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: _isEdit ? 'Edit Product' : 'New Product',
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
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'Product Name *',
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _code,
                          decoration: const InputDecoration(
                            labelText: 'Product Code',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _unit,
                          decoration: const InputDecoration(
                            labelText: 'Unit (e.g. Pcs, Kg)',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _productType,
                    decoration: const InputDecoration(
                      labelText: 'Product Type',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'goods', child: Text('Goods')),
                      DropdownMenuItem(
                        value: 'service',
                        child: Text('Service'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _productType = v!),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _hsnSac,
                          decoration: const InputDecoration(
                            labelText: 'HSN / SAC Code',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _gstRate,
                          decoration: const InputDecoration(
                            labelText: 'GST Rate (%)',
                          ),
                          items: [0, 5, 12, 18, 28]
                              .map(
                                (r) => DropdownMenuItem(
                                  value: r,
                                  child: Text('$r%'),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _gstRate = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _purchasePrice,
                          decoration: const InputDecoration(
                            labelText: 'Purchase Price (₹)',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _sellingPrice,
                          decoration: const InputDecoration(
                            labelText: 'Selling Price (₹)',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _reorderLevel,
                    decoration: const InputDecoration(
                      labelText: 'Reorder Level',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _description,
                    decoration: const InputDecoration(labelText: 'Description'),
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
                        : Text(_isEdit ? 'Update Product' : 'Create Product'),
                  ),
                ],
              ),
            ),
    );
  }
}
