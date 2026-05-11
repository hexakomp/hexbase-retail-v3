import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/receipt_list_provider.dart';
import '../../../shared/widgets/app_scaffold.dart';

/// Allocation row: maps a sales invoice to an amount the user allocates.
class _AllocRow {
  final int salesInvoiceId;
  final String invoiceNumber;
  final double outstanding;
  double allocated;

  _AllocRow({
    required this.salesInvoiceId,
    required this.invoiceNumber,
    required this.outstanding,
    this.allocated = 0,
  });

  Map<String, dynamic> toJson() => {
    'sales_invoice_id': salesInvoiceId,
    'allocated_amount': allocated,
  };
}

class ReceiptFormScreen extends ConsumerStatefulWidget {
  final int? receiptId;

  const ReceiptFormScreen({super.key, this.receiptId});

  @override
  ConsumerState<ReceiptFormScreen> createState() => _ReceiptFormScreenState();
}

class _ReceiptFormScreenState extends ConsumerState<ReceiptFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  int? _customerId;
  String _customerName = '';
  DateTime _receiptDate = DateTime.now();
  String _paymentMode = 'cash';
  int? _bankAccountId;
  final _referenceNumCtrl = TextEditingController();
  final _amountCtrl = TextEditingController(text: '0');
  final _narrationCtrl = TextEditingController();

  final List<_AllocRow> _allocations = [];

  static const _paymentModes = [
    'cash',
    'bank_transfer',
    'cheque',
    'upi',
    'card',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.receiptId != null) _loadExisting();
  }

  @override
  void dispose() {
    _referenceNumCtrl.dispose();
    _amountCtrl.dispose();
    _narrationCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(receiptRepositoryProvider);
      final data = await repo.show(widget.receiptId!);
      final customer = data['customer'] as Map<String, dynamic>?;
      final allocList = (data['allocations'] as List? ?? []);

      setState(() {
        _customerId = data['customer_id'] as int?;
        _customerName = customer?['name'] as String? ?? '';
        final rd = data['receipt_date'] as String?;
        _receiptDate = rd != null
            ? DateTime.tryParse(rd) ?? DateTime.now()
            : DateTime.now();
        _paymentMode = data['payment_mode'] as String? ?? 'cash';
        _bankAccountId = data['bank_account_id'] as int?;
        _referenceNumCtrl.text = data['reference_number'] as String? ?? '';
        _amountCtrl.text = (data['amount'] ?? 0).toString();
        _narrationCtrl.text = data['narration'] as String? ?? '';
        _allocations.clear();
        _allocations.addAll(
          allocList.map((a) {
            final am = a as Map<String, dynamic>;
            final inv = am['sales_invoice'] as Map<String, dynamic>? ?? {};
            return _AllocRow(
              salesInvoiceId: am['sales_invoice_id'] as int,
              invoiceNumber: inv['invoice_number'] as String? ?? '',
              outstanding: _toDouble(inv['balance_amount']),
              allocated: _toDouble(am['allocated_amount']),
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

  double get _totalAllocated =>
      _allocations.fold(0.0, (s, a) => s + a.allocated);
  double get _receiptAmount => double.tryParse(_amountCtrl.text) ?? 0.0;
  double get _advanceAmount =>
      (_receiptAmount - _totalAllocated).clamp(0.0, double.infinity);

  Future<void> _save({String status = 'draft'}) async {
    if (!_formKey.currentState!.validate()) return;
    if (_customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer.')),
      );
      return;
    }
    if (_totalAllocated > _receiptAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Allocated amount exceeds receipt amount.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final payload = {
      'receipt_date': _receiptDate.toIso8601String().split('T').first,
      'customer_id': _customerId,
      'payment_mode': _paymentMode,
      'bank_account_id': _bankAccountId,
      'reference_number': _referenceNumCtrl.text.trim().isEmpty
          ? null
          : _referenceNumCtrl.text.trim(),
      'amount': _receiptAmount,
      'narration': _narrationCtrl.text.trim().isEmpty
          ? null
          : _narrationCtrl.text.trim(),
      'status': status,
      'allocations': _allocations
          .where((a) => a.allocated > 0)
          .map((a) => a.toJson())
          .toList(),
    };

    try {
      final repo = ref.read(receiptRepositoryProvider);
      if (widget.receiptId != null) {
        await repo.update(widget.receiptId!, payload);
      } else {
        await repo.store(payload);
      }
      ref.read(receiptListProvider.notifier).refresh();
      if (mounted) context.go('/receipts');
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.receiptId != null;

    if (_isLoading) {
      return const AppScaffold(
        child: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return AppScaffold(
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEdit ? 'Edit Receipt' : 'New Receipt'),
          actions: _isSaving
              ? [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ]
              : [
                  TextButton(
                    onPressed: () => _save(status: 'draft'),
                    child: const Text('Save Draft'),
                  ),
                  FilledButton(
                    onPressed: () => _save(status: 'confirmed'),
                    child: const Text('Confirm'),
                  ),
                  const SizedBox(width: 8),
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
                _buildAllocationSection(context),
                const SizedBox(height: 16),
                _buildFooter(context),
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
              'Receipt Details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Customer *',
                border: OutlineInputBorder(),
              ),
              initialValue: _customerName,
              readOnly: true,
              onTap: () {
                // Placeholder: open customer search bottom sheet
              },
              validator: (v) =>
                  _customerId == null ? 'Please select a customer' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Receipt Date *',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                    initialValue:
                        '${_receiptDate.year}-${_receiptDate.month.toString().padLeft(2, '0')}-${_receiptDate.day.toString().padLeft(2, '0')}',
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _receiptDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _receiptDate = picked);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Payment Mode',
                      border: OutlineInputBorder(),
                    ),
                    value: _paymentMode,
                    items: _paymentModes
                        .map(
                          (m) => DropdownMenuItem(
                            value: m,
                            child: Text(m.replaceAll('_', ' ').toUpperCase()),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _paymentMode = v ?? 'cash'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _amountCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Amount *',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      final d = double.tryParse(v ?? '');
                      return d == null || d <= 0 ? 'Enter valid amount' : null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _referenceNumCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Reference No. (UTR/Cheque)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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

  Widget _buildAllocationSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Invoice Allocations',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Text(
              '(optional)',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        if (_allocations.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No invoices allocated.',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          ..._allocations.asMap().entries.map(
            (e) => _buildAllocRow(context, e.key, e.value),
          ),
      ],
    );
  }

  Widget _buildAllocRow(BuildContext context, int idx, _AllocRow row) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(row.invoiceNumber),
        subtitle: Text('Outstanding: ₹${row.outstanding.toStringAsFixed(2)}'),
        trailing: SizedBox(
          width: 130,
          child: TextFormField(
            initialValue: row.allocated.toStringAsFixed(2),
            decoration: const InputDecoration(
              labelText: 'Allocate',
              prefixText: '₹ ',
            ),
            keyboardType: TextInputType.number,
            onChanged: (v) {
              setState(() {
                row.allocated = double.tryParse(v) ?? 0;
              });
            },
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
          onPressed: () => setState(() => _allocations.removeAt(idx)),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _FooterRow('Receipt Amount', _receiptAmount),
            _FooterRow('Total Allocated', _totalAllocated),
            const Divider(),
            _FooterRow('Advance (Unapplied)', _advanceAmount, bold: true),
          ],
        ),
      ),
    );
  }
}

class _FooterRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool bold;

  const _FooterRow(this.label, this.amount, {this.bold = false});

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
