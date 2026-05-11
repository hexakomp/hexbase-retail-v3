import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/invoice_form_provider.dart';
import '../providers/invoice_list_provider.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/searchable_dropdown.dart';
//import '../../../shared/widgets/data_grid.dart';
import '../../../core/api_client.dart';

/// Sales Invoice form — create / edit.
/// Supports keyboard-first data entry with tab-navigation across line items.
class SalesInvoiceFormScreen extends ConsumerStatefulWidget {
  final int? invoiceId; // null = new invoice

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

  bool _initialised = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifier = ref.read(invoiceFormProvider.notifier);
      if (widget.invoiceId != null) {
        await notifier.loadForEdit(widget.invoiceId!);
        final s = ref.read(invoiceFormProvider);
        _dateCtrl.text = s.invoiceDate;
        _dueDateCtrl.text = s.dueDate ?? '';
        _narrationCtrl.text = s.narration;
      } else {
        notifier.reset();
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
          title: Text(state.isEditing ? 'Edit Invoice' : 'New Invoice'),
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
                            _HeaderSection(
                              state: state,
                              notifier: notifier,
                              dateCtrl: _dateCtrl,
                              dueDateCtrl: _dueDateCtrl,
                              narrationCtrl: _narrationCtrl,
                              pickDate: _pickDate,
                            ),
                            const SizedBox(height: 16),
                            _LineItemsSection(state: state, notifier: notifier),
                            const SizedBox(height: 16),
                            _TaxSummaryFooter(state: state),
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

// ── Header Section ──────────────────────────────────────────────────────────

class _HeaderSection extends ConsumerWidget {
  final InvoiceFormState state;
  final InvoiceFormNotifier notifier;
  final TextEditingController dateCtrl;
  final TextEditingController dueDateCtrl;
  final TextEditingController narrationCtrl;
  final Future<void> Function(TextEditingController, void Function(String))
  pickDate;

  const _HeaderSection({
    required this.state,
    required this.notifier,
    required this.dateCtrl,
    required this.dueDateCtrl,
    required this.narrationCtrl,
    required this.pickDate,
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
            Text(
              'Invoice Details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer search
                Expanded(
                  flex: 3,
                  child: SearchableDropdown<Map<String, dynamic>>(
                    label: 'Customer',
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
                      final items = (resp.data['data'] as List<dynamic>);
                      return items.cast<Map<String, dynamic>>();
                    },
                    onSelected: (c) {
                      if (c != null) {
                        notifier.setCustomer(
                          c['id'] as int,
                          c['name'] as String,
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Invoice date
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: dateCtrl,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Invoice Date *',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today, size: 18),
                    ),
                    onTap: () => pickDate(dateCtrl, notifier.setInvoiceDate),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                // Due date
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: dueDateCtrl,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Due Date',
                      border: OutlineInputBorder(),
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
                // Invoice type
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: state.invoiceType,
                    decoration: const InputDecoration(
                      labelText: 'Invoice Type *',
                      border: OutlineInputBorder(),
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
                // Place of supply
                Expanded(
                  child: TextFormField(
                    initialValue: state.placeOfSupply,
                    decoration: const InputDecoration(
                      labelText: 'Place of Supply (State Code) *',
                      border: OutlineInputBorder(),
                      hintText: 'e.g. 27',
                    ),
                    maxLength: 2,
                    keyboardType: TextInputType.number,
                    onChanged: notifier.setPlaceOfSupply,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                // Payment terms
                Expanded(
                  child: TextFormField(
                    initialValue: state.paymentTerms,
                    decoration: const InputDecoration(
                      labelText: 'Payment Terms',
                      border: OutlineInputBorder(),
                      hintText: 'e.g. Net 30',
                    ),
                    onChanged: notifier.setPaymentTerms,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: narrationCtrl,
              decoration: const InputDecoration(
                labelText: 'Narration / Reference',
                border: OutlineInputBorder(),
              ),
              onChanged: notifier.setNarration,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Line Items Section ───────────────────────────────────────────────────────

class _LineItemsSection extends ConsumerWidget {
  final InvoiceFormState state;
  final InvoiceFormNotifier notifier;
  const _LineItemsSection({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  label: const Text('Add Line'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Column headers
            _LineHeader(supplyType: _supplyType(state)),
            const Divider(height: 1),
            // Lines
            ...state.lines.asMap().entries.map(
              (e) => _LineRow(
                index: e.key,
                line: e.value,
                supplyType: _supplyType(state),
                notifier: notifier,
                ref: ref,
              ),
            ),
            if (state.lines.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('No lines yet. Click "Add Line".')),
              ),
          ],
        ),
      ),
    );
  }

  String _supplyType(InvoiceFormState s) {
    if (s.invoiceType == 'export') return 'export';
    return 'intra'; // simplified — actual type derived by service
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
          _hdr('Product', flex: 3),
          _hdr('HSN/SAC', flex: 2),
          _hdr('Qty', flex: 1),
          _hdr('Rate', flex: 2),
          _hdr('Disc%', flex: 1),
          _hdr('GST%', flex: 1),
          if (supplyType == 'intra') ...[
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
                      unitPrice: _d(p['selling_price']),
                      gstRate: _d(p['gst_rate']),
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
              initialValue: line.quantity == 0 ? '' : line.quantity.toString(),
              hint: 'Qty',
              numeric: true,
              onChanged: (v) => notifier.updateLine(
                index,
                line.copyWith(quantity: double.tryParse(v) ?? 0),
              ),
            ),
          ),
          // Rate
          Expanded(
            flex: 2,
            child: _SmallField(
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
              initialValue: line.gstRate.toString(),
              hint: 'GST%',
              numeric: true,
              onChanged: (v) => notifier.updateLine(
                index,
                line.copyWith(gstRate: double.tryParse(v) ?? 0),
              ),
            ),
          ),
          // CGST / IGST (read-only computed)
          if (supplyType == 'intra') ...[
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
    this.initialValue,
    required this.hint,
    this.numeric = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
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
  const _ReadOnlyAmountCell(this.amount);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        amount > 0 ? amount.toStringAsFixed(2) : '—',
        textAlign: TextAlign.right,
        style: TextStyle(
          fontSize: 13,
          color: amount > 0 ? Colors.black87 : Colors.grey,
        ),
      ),
    );
  }
}

// ── Tax Summary Footer ───────────────────────────────────────────────────────

class _TaxSummaryFooter extends StatelessWidget {
  final InvoiceFormState state;
  const _TaxSummaryFooter({required this.state});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerRight,
      child: Card(
        color: colorScheme.surfaceVariant,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: 320,
            child: Column(
              children: [
                _row('Subtotal', state.subtotal),
                if (state.discountAmount > 0)
                  _row('Discount', -state.discountAmount),
                _row('Taxable Amount', state.taxableAmount),
                if (state.cgstAmount > 0) _row('CGST', state.cgstAmount),
                if (state.sgstAmount > 0) _row('SGST', state.sgstAmount),
                if (state.igstAmount > 0) _row('IGST', state.igstAmount),
                if (state.cessAmount > 0) _row('Cess', state.cessAmount),
                if (state.roundOff != 0) _row('Round Off', state.roundOff),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Grand Total',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '₹ ${state.totalAmount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, double amount) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13)),
        Text(
          '₹ ${amount.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 13),
        ),
      ],
    ),
  );
}
