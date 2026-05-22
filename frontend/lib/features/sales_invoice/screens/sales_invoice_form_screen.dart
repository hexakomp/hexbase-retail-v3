import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/invoice_form_provider.dart';
import '../providers/invoice_list_provider.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/searchable_dropdown.dart';
import '../../../core/api_client.dart';

/// Sales Invoice form — create / edit.
class SalesInvoiceFormScreen extends ConsumerStatefulWidget {
  final int? invoiceId;

  const SalesInvoiceFormScreen({super.key, this.invoiceId});

  @override
  ConsumerState<SalesInvoiceFormScreen> createState() =>
      _SalesInvoiceFormScreenState();
}

class _SalesInvoiceFormScreenState
    extends ConsumerState<SalesInvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateCtrl = TextEditingController();
  final _dueDateCtrl = TextEditingController();
  final _narrationCtrl = TextEditingController();
  final _internalNotesCtrl = TextEditingController();
  final _billingAddressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _gstinCtrl = TextEditingController();
  final _invoiceNumCtrl = TextEditingController();
  final _posCtrl = TextEditingController();
  final _termsCtrl = TextEditingController();

  bool _showShipping = false;

  bool _initialised = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifier = ref.read(invoiceFormProvider.notifier);
      if (widget.invoiceId != null) {
        await notifier.loadForEdit(widget.invoiceId!);
        final s = ref.read(invoiceFormProvider);
        _invoiceNumCtrl.text = s.invoiceNumber;
        _dateCtrl.text = s.invoiceDate;
        _dueDateCtrl.text = s.dueDate ?? '';
        _narrationCtrl.text = s.narration;
        _internalNotesCtrl.text = s.internalNotes;
        _billingAddressCtrl.text = s.billingAddress;
        _phoneCtrl.text = s.customerPhone;
        _pincodeCtrl.text = s.billingPincode;
        _gstinCtrl.text = s.customerGstin;
        _posCtrl.text = s.placeOfSupply;
        _termsCtrl.text = s.paymentTerms ?? '';
        if (s.shippingAddress.isNotEmpty) {
          setState(() => _showShipping = true);
        }
      } else {
        await notifier.reset();
        final today = DateTime.now();
        final formatted =
            '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        _dateCtrl.text = formatted;
        notifier.setInvoiceDate(formatted);
      }
      setState(() => _initialised = true);
    });
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _dueDateCtrl.dispose();
    _narrationCtrl.dispose();
    _internalNotesCtrl.dispose();
    _billingAddressCtrl.dispose();
    _phoneCtrl.dispose();
    _pincodeCtrl.dispose();
    _gstinCtrl.dispose();
    _invoiceNumCtrl.dispose();
    _posCtrl.dispose();
    _termsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(
    TextEditingController ctrl,
    void Function(String) onPicked,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(ctrl.text) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      final formatted =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      ctrl.text = formatted;
      onPicked(formatted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(invoiceFormProvider);
    final notifier = ref.read(invoiceFormProvider.notifier);

    // Watch for save success → navigate away
    ref.listen<InvoiceFormState>(invoiceFormProvider, (prev, next) {
      if (!prev!.saved && next.saved && next.editingId != null) {
        ref.read(invoiceListProvider.notifier).refresh();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invoice saved')));
        context.go('/invoices/${next.editingId}');
      }
    });

    return AppScaffold(
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(state.isEditing ? 'Edit Invoice' : 'New Invoice'),
              if (state.isEditing && state.invoiceNumber.isNotEmpty)
                Text(
                  state.invoiceNumber,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                ),
            ],
          ),
          actions: [
            if (state.isCalculating)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            TextButton.icon(
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save Draft'),
              onPressed: state.isSaving
                  ? null
                  : () => _save(notifier, post: false),
            ),
            const SizedBox(width: 4),
            FilledButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Save & Post'),
              onPressed: state.isSaving
                  ? null
                  : () => _save(notifier, post: true),
            ),
            const SizedBox(width: 12),
          ],
        ),
        body: !_initialised
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (state.error != null)
                      MaterialBanner(
                        content: Text(state.error!),
                        backgroundColor: Colors.red.shade50,
                        actions: [
                          TextButton(
                            onPressed: () =>
                                ref.read(invoiceFormProvider.notifier).reset(),
                            child: const Text('Dismiss'),
                          ),
                        ],
                      ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left Column: Customer & Address
                                Expanded(
                                  flex: 3,
                                  child: FocusTraversalGroup(
                                    child: _CustomerSection(
                                      state: state,
                                      notifier: notifier,
                                      showShipping: _showShipping,
                                      billingAddressCtrl: _billingAddressCtrl,
                                      phoneCtrl: _phoneCtrl,
                                      pincodeCtrl: _pincodeCtrl,
                                      gstinCtrl: _gstinCtrl,
                                      posCtrl: _posCtrl,
                                      onToggleShipping: () => setState(
                                        () => _showShipping = !_showShipping,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Right Column: Invoice Details
                                Expanded(
                                  flex: 2,
                                  child: FocusTraversalGroup(
                                    child: _InvoiceSection(
                                      state: state,
                                      notifier: notifier,
                                      invoiceNumCtrl: _invoiceNumCtrl,
                                      dateCtrl: _dateCtrl,
                                      dueDateCtrl: _dueDateCtrl,
                                      posCtrl: _posCtrl,
                                      termsCtrl: _termsCtrl,
                                      pickDate: _pickDate,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: FocusTraversalGroup(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        TextFormField(
                                          controller: _narrationCtrl,
                                          maxLines: 3,
                                          decoration: const InputDecoration(
                                            labelText: 'Narration / Reference',
                                            hintText:
                                                'Enter any notes or reference numbers here...',
                                            alignLabelWithHint: true,
                                          ),
                                          onChanged: notifier.setNarration,
                                        ),
                                        const SizedBox(height: 16),
                                        TextFormField(
                                          controller: _internalNotesCtrl,
                                          maxLines: 3,
                                          decoration: const InputDecoration(
                                            labelText: 'Internal Notes',
                                            hintText:
                                                'Notes for internal purpose (not printed on invoice)',
                                            alignLabelWithHint: true,
                                          ),
                                          onChanged: notifier.setInternalNotes,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 24),
                                FocusTraversalGroup(
                                  child: _TaxSummaryFooter(
                                    state: state,
                                    notifier: notifier,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            FocusTraversalGroup(
                              child: _LineItemsSection(
                                state: state,
                                notifier: notifier,
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _save(InvoiceFormNotifier notifier, {required bool post}) async {
    if (!_formKey.currentState!.validate()) return;
    if (post) {
      await notifier.saveAndPost();
    } else {
      await notifier.saveDraft();
    }
  }
}

class _CustomerSection extends ConsumerWidget {
  final InvoiceFormState state;
  final InvoiceFormNotifier notifier;
  final bool showShipping;
  final VoidCallback onToggleShipping;
  final TextEditingController billingAddressCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController pincodeCtrl;
  final TextEditingController gstinCtrl;
  final TextEditingController posCtrl;

  const _CustomerSection({
    required this.state,
    required this.notifier,
    required this.showShipping,
    required this.onToggleShipping,
    required this.billingAddressCtrl,
    required this.phoneCtrl,
    required this.pincodeCtrl,
    required this.gstinCtrl,
    required this.posCtrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.read(apiClientProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Customer Information',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                OutlinedButton.icon(
                  icon: Icon(
                    showShipping
                        ? Icons.location_off_outlined
                        : Icons.local_shipping_outlined,
                    size: 16,
                  ),
                  label: Text(
                    showShipping ? 'Hide Shipping' : 'Shipping Address',
                    style: const TextStyle(fontSize: 13),
                  ),
                  onPressed: onToggleShipping,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SearchableDropdown<Map<String, dynamic>>(
              label: 'Customer *',
              hint: 'Search customer…',
              value: state.customerId == null
                  ? null
                  : {'id': state.customerId, 'name': state.customerName},
              displayText: (c) => c['name'] as String,
              onSearch: (q) async {
                final resp = await client.dio.get(
                  '/api/v1/customers',
                  queryParameters: {'search': q, 'per_page': 20},
                );
                return (resp.data['data'] as List<dynamic>)
                    .cast<Map<String, dynamic>>();
              },
              onSelected: (c) {
                if (c != null) {
                  billingAddressCtrl.text =
                      c['billing_address'] as String? ?? '';
                  phoneCtrl.text = c['phone'] as String? ?? '';
                  pincodeCtrl.text = c['billing_pincode'] as String? ?? '';
                  gstinCtrl.text = c['gstin'] as String? ?? '';

                  // Derive place of supply from GSTIN: first 2 digits = state code
                  final gstin = gstinCtrl.text;
                  final placeOfSupply = gstin.length >= 2
                      ? gstin.substring(0, 2)
                      : '';
                  if (placeOfSupply.isNotEmpty) {
                    posCtrl.text = placeOfSupply;
                  }

                  notifier.setCustomer(
                    c['id'] as int,
                    c['name'] as String,
                    billingAddress: billingAddressCtrl.text,
                    billingCity: c['billing_city'] as String? ?? '',
                    billingState: c['billing_state'] as String? ?? '',
                    billingPincode: pincodeCtrl.text,
                    shippingAddress: c['shipping_address'] as String? ?? '',
                    customerGstin: gstinCtrl.text,
                    customerPhone: phoneCtrl.text,
                    placeOfSupply: placeOfSupply,
                  );
                }
              },
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: billingAddressCtrl,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Billing Address',
                          alignLabelWithHint: true,
                        ),
                        onChanged: notifier.setBillingAddress,
                      ),
                      if (showShipping) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          initialValue: state.shippingAddress,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Shipping Address',
                            alignLabelWithHint: true,
                          ),
                          onChanged: notifier.updateShippingAddress,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: gstinCtrl,
                        decoration: const InputDecoration(labelText: 'GSTIN'),
                        onChanged: notifier.setCustomerGstin,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: phoneCtrl,
                        decoration: const InputDecoration(labelText: 'Phone'),
                        onChanged: notifier.setCustomerPhone,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: pincodeCtrl,
                        decoration: const InputDecoration(labelText: 'Pincode'),
                        onChanged: notifier.setBillingPincode,
                      ),
                    ],
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

// ── Invoice Section ──────────────────────────────────────────────────────────

class _InvoiceSection extends StatelessWidget {
  final InvoiceFormState state;
  final InvoiceFormNotifier notifier;
  final TextEditingController invoiceNumCtrl;
  final TextEditingController dateCtrl;
  final TextEditingController dueDateCtrl;
  final TextEditingController posCtrl;
  final TextEditingController termsCtrl;
  final Function(TextEditingController, void Function(String)) pickDate;

  const _InvoiceSection({
    required this.state,
    required this.notifier,
    required this.invoiceNumCtrl,
    required this.dateCtrl,
    required this.dueDateCtrl,
    required this.posCtrl,
    required this.termsCtrl,
    required this.pickDate,
  });

  @override
  Widget build(BuildContext context) {
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
            TextFormField(
              controller: invoiceNumCtrl,
              decoration: const InputDecoration(
                labelText: 'Invoice Number',
                hintText: 'Leave empty to auto-generate',
              ),
              onChanged: notifier.setInvoiceNumber,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: dateCtrl,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Invoice Date *',
                      suffixIcon: Icon(Icons.calendar_today, size: 18),
                    ),
                    onTap: () => pickDate(dateCtrl, notifier.setInvoiceDate),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: dueDateCtrl,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Due Date',
                      suffixIcon: Icon(Icons.calendar_today, size: 18),
                    ),
                    onTap: () => pickDate(dueDateCtrl, notifier.setDueDate),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: state.invoiceType,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Invoice Type *',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'b2b', child: Text('B2B')),
                      DropdownMenuItem(value: 'b2c', child: Text('B2C')),
                      DropdownMenuItem(value: 'export', child: Text('Export')),
                    ],
                    onChanged: (v) => notifier.setInvoiceType(v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: posCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Place of Supply *',
                      hintText: 'State Code',
                      counterText: '',
                    ),
                    maxLength: 2,
                    keyboardType: TextInputType.number,
                    onChanged: notifier.setPlaceOfSupply,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: termsCtrl,
              decoration: const InputDecoration(
                labelText: 'Payment Terms',
                hintText: 'e.g. Net 30',
              ),
              onChanged: notifier.setPaymentTerms,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Line Items Section ────────────────────────────────────────────────────────

class _LineItemsSection extends ConsumerWidget {
  final InvoiceFormState state;
  final InvoiceFormNotifier notifier;
  const _LineItemsSection({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supplyType = _supplyType(state);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Line Items',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: notifier.addLine,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Row'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _LineHeader(supplyType: supplyType),
            const Divider(height: 1),
            ...state.lines.asMap().entries.map(
              (e) => _LineRow(
                index: e.key,
                line: e.value,
                supplyType: supplyType,
                notifier: notifier,
                ref: ref,
              ),
            ),
            if (state.lines.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('No lines yet. Click "Add Row".')),
              ),
          ],
        ),
      ),
    );
  }

  String _supplyType(InvoiceFormState s) {
    if (s.invoiceType == 'export') return 'export';

    if (s.customerGstin.trim().isEmpty) {
      return 'intra';
    }

    final compState = s.companyGstin.length >= 2
        ? s.companyGstin.substring(0, 2)
        : '';
    final custState = s.placeOfSupply.length >= 2
        ? s.placeOfSupply.substring(0, 2)
        : (s.customerGstin.length >= 2 ? s.customerGstin.substring(0, 2) : '');

    if (compState.isNotEmpty &&
        custState.isNotEmpty &&
        compState != custState) {
      return 'inter';
    }
    return 'intra';
  }
}

class _LineHeader extends StatelessWidget {
  final String supplyType;
  const _LineHeader({required this.supplyType});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          _hdr('#', flex: 1),
          _hdr('Product', flex: 3),
          _hdr('HSN/SAC', flex: 2),
          _hdr('Qty', flex: 1),
          _hdr('Unit', flex: 1),
          _hdr('Rate', flex: 2),
          _hdr('Disc%', flex: 1),
          _hdr('GST%', flex: 1),
          if (supplyType == 'intra') ...[
            _hdr('CGST%', flex: 1),
            _hdr('SGST%', flex: 1),
            _hdr('CGST', flex: 2),
            _hdr('SGST', flex: 2),
          ] else
            _hdr('IGST', flex: 2),
          _hdr('Total', flex: 2),
          const SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _hdr(String label, {required int flex}) => Expanded(
    flex: flex,
    child: Text(
      label,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
      overflow: TextOverflow.ellipsis,
    ),
  );
}

class _LineRow extends StatelessWidget {
  final int index;
  final InvoiceLineForm line;
  final String supplyType;
  final InvoiceFormNotifier notifier;
  final WidgetRef ref;

  const _LineRow({
    required this.index,
    required this.line,
    required this.supplyType,
    required this.notifier,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final client = ref.read(apiClientProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // S.No
          Expanded(
            flex: 1,
            child: Text(
              '${index + 1}',
              style: const TextStyle(fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
          // Product search
          Expanded(
            flex: 3,
            child: SearchableDropdown<Map<String, dynamic>>(
              label: '',
              hint: 'Product…',
              value: line.productId == null
                  ? null
                  : {'id': line.productId, 'name': line.productName},
              displayText: (p) => p['name'] as String,
              onSearch: (q) async {
                final resp = await client.dio.get(
                  '/api/v1/products',
                  queryParameters: {'search': q, 'per_page': 20},
                );
                return (resp.data['data'] as List<dynamic>)
                    .cast<Map<String, dynamic>>();
              },
              onSelected: (p) {
                if (p != null) {
                  notifier.updateLine(
                    index,
                    line.copyWith(
                      productId: p['id'] as int,
                      productName: p['name'] as String,
                      hsnSac: p['hsn_sac'] as String? ?? '',
                      unitPrice: _d(p['sale_price']),
                      gstRate: _d(p['gst_rate']),
                      cessRate: _d(p['cess_rate']),
                      unit: p['unit'] as String? ?? '',
                    ),
                  );
                }
              },
            ),
          ),
          const SizedBox(width: 4),
          // HSN
          Expanded(
            flex: 2,
            child: _SmallField(
              key: ValueKey('hsn-$index-${line.productId}'),
              initialValue: line.hsnSac,
              hint: 'HSN/SAC',
              onChanged: (v) =>
                  notifier.updateLine(index, line.copyWith(hsnSac: v)),
            ),
          ),
          // Qty
          Expanded(
            flex: 1,
            child: _SmallField(
              key: ValueKey('qty-$index-${line.productId}'),
              initialValue: line.quantity == 0 ? '' : line.quantity.toString(),
              hint: 'Qty',
              numeric: true,
              onChanged: (v) => notifier.updateLine(
                index,
                line.copyWith(quantity: double.tryParse(v) ?? 0),
              ),
            ),
          ),
          // Unit
          Expanded(
            flex: 1,
            child: _SmallField(
              key: ValueKey('unit-$index-${line.productId}'),
              initialValue: line.unit,
              hint: 'Unit',
              onChanged: (v) =>
                  notifier.updateLine(index, line.copyWith(unit: v)),
            ),
          ),
          // Rate
          Expanded(
            flex: 2,
            child: _SmallField(
              key: ValueKey('rate-$index-${line.productId}'),
              initialValue: line.unitPrice == 0
                  ? ''
                  : line.unitPrice.toString(),
              hint: 'Rate',
              numeric: true,
              onChanged: (v) => notifier.updateLine(
                index,
                line.copyWith(unitPrice: double.tryParse(v) ?? 0),
              ),
            ),
          ),
          // Disc%
          Expanded(
            flex: 1,
            child: _SmallField(
              key: ValueKey('disc-$index-${line.productId}'),
              initialValue: line.discountPct == 0
                  ? ''
                  : line.discountPct.toString(),
              hint: '0',
              numeric: true,
              onChanged: (v) => notifier.updateLine(
                index,
                line.copyWith(discountPct: double.tryParse(v) ?? 0),
              ),
            ),
          ),
          // GST%
          Expanded(
            flex: 1,
            child: _SmallField(
              key: ValueKey('gst-$index-${line.productId}'),
              initialValue: line.gstRate.toString(),
              hint: 'GST%',
              numeric: true,
              onChanged: (v) => notifier.updateLine(
                index,
                line.copyWith(gstRate: double.tryParse(v) ?? 0),
              ),
            ),
          ),
          // Tax amounts
          if (supplyType == 'intra') ...[
            Expanded(
              flex: 1,
              child: _ReadOnlyAmountCell(
                line.gstRate / 2,
                suffix: '%',
                fontSize: 12,
              ),
            ),
            Expanded(
              flex: 1,
              child: _ReadOnlyAmountCell(
                line.gstRate / 2,
                suffix: '%',
                fontSize: 12,
              ),
            ),
            Expanded(flex: 2, child: _ReadOnlyAmountCell(line.cgstAmount)),
            Expanded(flex: 2, child: _ReadOnlyAmountCell(line.sgstAmount)),
          ] else
            Expanded(flex: 2, child: _ReadOnlyAmountCell(line.igstAmount)),
          // Line total
          Expanded(
            flex: 2,
            child: Text(
              '₹ ${line.lineTotal.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
          // Delete
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            color: Colors.red,
            onPressed: () => notifier.removeLine(index),
          ),
        ],
      ),
    );
  }

  static double _d(dynamic v) =>
      v == null ? 0.0 : double.tryParse(v.toString()) ?? 0.0;
}

class _SmallField extends StatelessWidget {
  final String? initialValue;
  final String hint;
  final bool numeric;
  final ValueChanged<String> onChanged;

  const _SmallField({
    super.key,
    this.initialValue,
    required this.hint,
    this.numeric = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: key,
      initialValue: initialValue,
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        border: const OutlineInputBorder(),
      ),
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      inputFormatters: numeric
          ? [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))]
          : null,
      style: const TextStyle(fontSize: 13),
      onChanged: onChanged,
    );
  }
}

class _ReadOnlyAmountCell extends StatelessWidget {
  final double amount;
  final String suffix;
  final double fontSize;
  const _ReadOnlyAmountCell(
    this.amount, {
    this.suffix = '',
    this.fontSize = 13,
  });

  @override
  Widget build(BuildContext context) {
    final display = amount > 0
        ? '${amount.toStringAsFixed(suffix.isEmpty ? 2 : 1)}$suffix'
        : '—';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        display,
        textAlign: TextAlign.right,
        style: TextStyle(
          fontSize: fontSize,
          color: amount > 0 ? Colors.black87 : Colors.grey,
        ),
      ),
    );
  }
}

// ── Tax Summary Footer ───────────────────────────────────────────────────────

class _TaxSummaryFooter extends StatefulWidget {
  final InvoiceFormState state;
  final InvoiceFormNotifier notifier;
  const _TaxSummaryFooter({required this.state, required this.notifier});

  @override
  State<_TaxSummaryFooter> createState() => _TaxSummaryFooterState();
}

class _TaxSummaryFooterState extends State<_TaxSummaryFooter> {
  late final TextEditingController _roundOffCtrl;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _roundOffCtrl = TextEditingController(
      text: widget.state.roundOff.toStringAsFixed(2),
    );
  }

  @override
  void didUpdateWidget(_TaxSummaryFooter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing && widget.state.roundOff != oldWidget.state.roundOff) {
      _roundOffCtrl.text = widget.state.roundOff.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _roundOffCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final s = widget.state;
    return Card(
      color: colorScheme.surfaceVariant.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: 320,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Invoice Summary',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _readonlyRow(context, 'Base Total', s.subtotal),
              const SizedBox(height: 8),
              _readonlyRow(context, 'Total CGST', s.cgstAmount),
              const SizedBox(height: 8),
              _readonlyRow(context, 'Total SGST', s.sgstAmount),
              const SizedBox(height: 8),
              _readonlyRow(context, 'Total IGST', s.igstAmount),
              const SizedBox(height: 8),
              // Editable Round Off
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Round Off',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black.withOpacity(0.7),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _roundOffCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^-?\d*\.?\d*'),
                        ),
                      ],
                      decoration: const InputDecoration(
                        isDense: true,
                        prefixText: '₹ ',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                      ),
                      style: const TextStyle(fontSize: 13),
                      onTap: () => setState(() => _editing = true),
                      onChanged: (v) {
                        final val = double.tryParse(v) ?? 0.0;
                        widget.notifier.setRoundOff(val);
                      },
                      onEditingComplete: () {
                        setState(() => _editing = false);
                        FocusScope.of(context).unfocus();
                      },
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '₹ ${s.totalAmount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _readonlyRow(BuildContext context, String label, double amount) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.black.withOpacity(0.7),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '₹ ${amount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }
}
