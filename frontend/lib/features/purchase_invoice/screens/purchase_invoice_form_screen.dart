import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/purchase_invoice_list_provider.dart';
import '../../../shared/widgets/app_scaffold.dart';

/// Line item state used on the form.
class _LineItem {
  int? productId;
  String description;
  String hsnSac;
  double quantity;
  String unit;
  double rate;
  double discountPercent;
  double gstRate;
  double cessRate;
  bool itcEligible;

  _LineItem({
    this.productId,
    this.description = '',
    this.hsnSac = '',
    this.quantity = 1,
    this.unit = 'PCS',
    this.rate = 0,
    this.discountPercent = 0,
    this.gstRate = 18,
    this.cessRate = 0,
    this.itcEligible = true,
  });

  double get taxable => quantity * rate * (1 - discountPercent / 100);
  double get gstAmount => taxable * gstRate / 100;
  double get lineTotal => taxable + gstAmount;

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'description': description,
    'hsn_sac': hsnSac,
    'quantity': quantity,
    'unit': unit,
    'rate': rate,
    'discount_percent': discountPercent,
    'gst_rate': gstRate,
    'cess_rate': cessRate,
    'itc_eligible': itcEligible,
  };
}

class PurchaseInvoiceFormScreen extends ConsumerStatefulWidget {
  final int? invoiceId;

  const PurchaseInvoiceFormScreen({super.key, this.invoiceId});

  @override
  ConsumerState<PurchaseInvoiceFormScreen> createState() =>
      _PurchaseInvoiceFormScreenState();
}

class _PurchaseInvoiceFormScreenState
    extends ConsumerState<PurchaseInvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  // Header fields
  int? _vendorId;
  String _vendorName = '';
  final _vendorInvNumCtrl = TextEditingController();
  DateTime? _vendorInvoiceDate;
  DateTime _entryDate = DateTime.now();
  bool _reverseCharge = false;
  final _narrationCtrl = TextEditingController();

  // Line items
  final List<_LineItem> _lines = [_LineItem()];

  @override
  void initState() {
    super.initState();
    if (widget.invoiceId != null) _loadExisting();
  }

  @override
  void dispose() {
    _vendorInvNumCtrl.dispose();
    _narrationCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(purchaseInvoiceRepositoryProvider);
      final data = await repo.show(widget.invoiceId!);
      final linesList = (data['lines'] as List? ?? []);
      final vendor = data['vendor'] as Map<String, dynamic>?;

      setState(() {
        _vendorId = data['vendor_id'] as int?;
        _vendorName = vendor?['name'] as String? ?? '';
        _vendorInvNumCtrl.text = data['vendor_invoice_number'] as String? ?? '';
        final vid = data['vendor_invoice_date'] as String?;
        _vendorInvoiceDate = vid != null ? DateTime.tryParse(vid) : null;
        final ed = data['entry_date'] as String?;
        _entryDate = ed != null
            ? DateTime.tryParse(ed) ?? DateTime.now()
            : DateTime.now();
        _reverseCharge = data['reverse_charge'] as bool? ?? false;
        _narrationCtrl.text = data['narration'] as String? ?? '';
        _lines
          ..clear()
          ..addAll(
            linesList.map((l) {
              final lm = l as Map<String, dynamic>;
              return _LineItem(
                productId: lm['product_id'] as int?,
                description: lm['description'] as String? ?? '',
                hsnSac: lm['hsn_sac'] as String? ?? '',
                quantity: _toDouble(lm['quantity']),
                unit: lm['unit'] as String? ?? 'PCS',
                rate: _toDouble(lm['unit_price'] ?? lm['rate']),
                discountPercent: _toDouble(
                  lm['discount_pct'] ?? lm['discount_percent'],
                ),
                gstRate: _toDouble(lm['gst_rate']),
                cessRate: _toDouble(lm['cess_rate']),
                itcEligible: lm['itc_eligible'] as bool? ?? true,
              );
            }),
          );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  static double _toDouble(dynamic v) =>
      v == null ? 0.0 : double.tryParse(v.toString()) ?? 0.0;

  double get _subtotal => _lines.fold(0, (s, l) => s + l.taxable);
  double get _totalTax => _lines.fold(0, (s, l) => s + l.gstAmount);
  double get _grandTotal => _subtotal + _totalTax;

  Future<void> _save({String status = 'draft'}) async {
    if (!_formKey.currentState!.validate()) return;
    if (_vendorId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a vendor.')));
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });

    final payload = {
      'entry_date': _entryDate.toIso8601String().split('T').first,
      'vendor_id': _vendorId,
      'vendor_invoice_number': _vendorInvNumCtrl.text.trim().isEmpty
          ? null
          : _vendorInvNumCtrl.text.trim(),
      'vendor_invoice_date': _vendorInvoiceDate
          ?.toIso8601String()
          .split('T')
          .first,
      'reverse_charge': _reverseCharge,
      'narration': _narrationCtrl.text.trim().isEmpty
          ? null
          : _narrationCtrl.text.trim(),
      'status': status,
      'lines': _lines.map((l) => l.toJson()).toList(),
    };

    try {
      final repo = ref.read(purchaseInvoiceRepositoryProvider);
      if (widget.invoiceId != null) {
        await repo.update(widget.invoiceId!, payload);
      } else {
        await repo.store(payload);
      }
      ref.read(purchaseInvoiceListProvider.notifier).refresh();
      if (mounted) context.go('/purchase-invoices');
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.invoiceId != null;

    if (_isLoading) {
      return const AppScaffold(
        child: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return AppScaffold(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isEdit ? 'Edit Purchase Invoice' : 'New Purchase Invoice',
          ),
          actions: [
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else ...[
              TextButton(
                onPressed: () => _save(status: 'draft'),
                child: const Text('Save Draft'),
              ),
              FilledButton(
                onPressed: () => _save(status: 'posted'),
                child: const Text('Post'),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_error != null)
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                _buildHeaderSection(context),
                const SizedBox(height: 24),
                _buildLinesSection(context),
                const SizedBox(height: 16),
                _buildTaxSummary(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invoice Details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            // Vendor selector (simplified — would use SearchableDropdown in full impl)
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Vendor *',
                border: OutlineInputBorder(),
              ),
              initialValue: _vendorName,
              readOnly: true,
              onTap: () async {
                // Placeholder: In production, open vendor search bottom sheet
                // and set _vendorId, _vendorName
              },
              validator: (v) =>
                  _vendorId == null ? 'Please select a vendor' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Entry Date *',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                    initialValue:
                        '${_entryDate.year}-${_entryDate.month.toString().padLeft(2, '0')}-${_entryDate.day.toString().padLeft(2, '0')}',
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _entryDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => _entryDate = picked);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _vendorInvNumCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Vendor Invoice No.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Reverse Charge (RCM)'),
              value: _reverseCharge,
              onChanged: (v) => setState(() => _reverseCharge = v),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _narrationCtrl,
              decoration: const InputDecoration(
                labelText: 'Narration',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Line Items', style: Theme.of(context).textTheme.titleMedium),
            TextButton.icon(
              onPressed: () => setState(() => _lines.add(_LineItem())),
              icon: const Icon(Icons.add),
              label: const Text('Add Line'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._lines.asMap().entries.map(
          (e) => _buildLineCard(context, e.key, e.value),
        ),
      ],
    );
  }

  Widget _buildLineCard(BuildContext context, int idx, _LineItem line) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Line ${idx + 1}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (_lines.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => setState(() => _lines.removeAt(idx)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: line.description,
                    onChanged: (v) => line.description = v,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'HSN/SAC *',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: line.hsnSac,
                    onChanged: (v) => setState(() => line.hsnSac = v),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Qty *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    initialValue: line.quantity.toString(),
                    onChanged: (v) =>
                        setState(() => line.quantity = double.tryParse(v) ?? 1),
                    validator: (v) {
                      final d = double.tryParse(v ?? '');
                      return d == null || d <= 0 ? 'Must be > 0' : null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Rate *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    initialValue: line.rate.toString(),
                    onChanged: (v) =>
                        setState(() => line.rate = double.tryParse(v) ?? 0),
                    validator: (v) {
                      final d = double.tryParse(v ?? '');
                      return d == null || d < 0 ? 'Must be >= 0' : null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Disc %',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    initialValue: line.discountPercent.toString(),
                    onChanged: (v) => setState(
                      () => line.discountPercent = double.tryParse(v) ?? 0,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'GST %',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    initialValue: line.gstRate.toString(),
                    onChanged: (v) =>
                        setState(() => line.gstRate = double.tryParse(v) ?? 0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: line.itcEligible,
                      onChanged: (v) =>
                          setState(() => line.itcEligible = v ?? true),
                    ),
                    const Text('ITC Eligible'),
                  ],
                ),
                Text(
                  'Line Total: ₹${line.lineTotal.toStringAsFixed(2)}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaxSummary(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _SummaryRow('Subtotal (Taxable)', _subtotal),
            _SummaryRow('Total Tax', _totalTax),
            const Divider(),
            _SummaryRow('Grand Total', _grandTotal, bold: true),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool bold;

  const _SummaryRow(this.label, this.amount, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)
        : Theme.of(context).textTheme.bodyMedium;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('₹${amount.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }
}
