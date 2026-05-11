import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../providers/expense_provider.dart';

class ExpenseFormScreen extends ConsumerStatefulWidget {
  final int? expenseId;
  const ExpenseFormScreen({super.key, this.expenseId});

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _expenseData;

  final _dateController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  final _gstAmountController = TextEditingController();
  final _referenceController = TextEditingController();
  String _paymentMode = 'bank';
  bool _isBillable = false;

  bool get _isEdit => widget.expenseId != null;
  bool get _isDraft =>
      _expenseData == null || _expenseData!['status'] == 'draft';

  @override
  void initState() {
    super.initState();
    if (_isEdit) _loadExpense();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _categoryController.dispose();
    _descController.dispose();
    _amountController.dispose();
    _gstAmountController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _loadExpense() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(expenseRepositoryProvider);
      final data = await repo.get(widget.expenseId!);
      final exp = data['data'] as Map<String, dynamic>;
      setState(() {
        _expenseData = exp;
        _dateController.text = (exp['expense_date'] as String).substring(0, 10);
        _categoryController.text = exp['category'] as String? ?? '';
        _descController.text = exp['description'] as String? ?? '';
        _amountController.text = exp['amount'].toString();
        _gstAmountController.text = exp['gst_amount'].toString();
        _referenceController.text = exp['reference'] as String? ?? '';
        _paymentMode = exp['payment_mode'] as String? ?? 'bank';
        _isBillable = exp['is_billable'] as bool? ?? false;
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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(expenseRepositoryProvider);
      final amount = double.tryParse(_amountController.text) ?? 0;
      final gst = double.tryParse(_gstAmountController.text) ?? 0;
      final payload = {
        'expense_date': _dateController.text,
        'category': _categoryController.text,
        'description': _descController.text,
        'amount': amount,
        'gst_amount': gst,
        'payment_mode': _paymentMode,
        'is_billable': _isBillable,
        if (_referenceController.text.isNotEmpty)
          'reference': _referenceController.text,
      };
      await repo.create(payload);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _postExpense() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(expenseRepositoryProvider).post(widget.expenseId!);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _cancelExpense() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Expense'),
        content: const Text('Are you sure you want to cancel this expense?'),
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
      await ref.read(expenseRepositoryProvider).cancel(widget.expenseId!);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _expenseData?['status'] as String? ?? 'draft';

    return AppScaffold(
      title: _isEdit ? 'Expense' : 'New Expense',
      actions: _isEdit && _isDraft
          ? [
              IconButton(
                icon: const Icon(Icons.check_circle_outline),
                tooltip: 'Post',
                onPressed: _postExpense,
              ),
              IconButton(
                icon: const Icon(Icons.cancel_outlined),
                tooltip: 'Cancel',
                onPressed: _cancelExpense,
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
                        color: Colors.green.shade50,
                        border: Border.all(color: Colors.green),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Status: ${status.toUpperCase()}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  TextFormField(
                    controller: _dateController,
                    decoration: const InputDecoration(
                      labelText: 'Expense Date *',
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
                    controller: _categoryController,
                    decoration: const InputDecoration(
                      labelText: 'Category *',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: !_isDraft,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descController,
                    decoration: const InputDecoration(
                      labelText: 'Description *',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: !_isDraft,
                    maxLines: 2,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _amountController,
                          decoration: const InputDecoration(
                            labelText: 'Amount *',
                            border: OutlineInputBorder(),
                            prefixText: '₹ ',
                          ),
                          readOnly: !_isDraft,
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _gstAmountController,
                          decoration: const InputDecoration(
                            labelText: 'GST Amount',
                            border: OutlineInputBorder(),
                            prefixText: '₹ ',
                          ),
                          readOnly: !_isDraft,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _paymentMode,
                    decoration: const InputDecoration(
                      labelText: 'Payment Mode',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('Cash')),
                      DropdownMenuItem(
                        value: 'bank',
                        child: Text('Bank Transfer'),
                      ),
                      DropdownMenuItem(value: 'upi', child: Text('UPI')),
                      DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
                    ],
                    onChanged: _isDraft
                        ? (v) => setState(() => _paymentMode = v!)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _referenceController,
                    decoration: const InputDecoration(
                      labelText: 'Reference / Bill No.',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: !_isDraft,
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Billable to Customer'),
                    value: _isBillable,
                    onChanged: _isDraft
                        ? (v) => setState(() => _isBillable = v)
                        : null,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 24),
                  if (!_isEdit)
                    ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Draft'),
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
