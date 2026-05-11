import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../providers/debit_note_provider.dart';

class DebitNoteFormScreen extends ConsumerStatefulWidget {
  final int? noteId;
  const DebitNoteFormScreen({super.key, this.noteId});

  @override
  ConsumerState<DebitNoteFormScreen> createState() =>
      _DebitNoteFormScreenState();
}

class _DebitNoteFormScreenState extends ConsumerState<DebitNoteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _noteData;

  final _dateController = TextEditingController();
  final _reasonController = TextEditingController();
  int? _vendorId;
  int? _purchaseInvoiceId;
  String _supplyType = 'intra';
  final List<Map<String, dynamic>> _lines = [];

  bool get _isEdit => widget.noteId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _loadNote();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadNote() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(debitNoteRepositoryProvider);
      final data = await repo.get(widget.noteId!);
      final note = data['data'] as Map<String, dynamic>;
      setState(() {
        _noteData = note;
        _dateController.text = (note['debit_note_date'] as String).substring(
          0,
          10,
        );
        _reasonController.text = note['reason'] as String? ?? '';
        _vendorId = note['vendor_id'] as int;
        _purchaseInvoiceId = note['purchase_invoice_id'] as int?;
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
    if (_vendorId == null) {
      setState(() => _error = 'Please select a vendor.');
      return;
    }
    if (_lines.isEmpty) {
      setState(() => _error = 'Add at least one line item.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(debitNoteRepositoryProvider);
      final payload = {
        'debit_note_date': _dateController.text,
        'vendor_id': _vendorId,
        'purchase_invoice_id': _purchaseInvoiceId,
        'reason': _reasonController.text,
        'supply_type': _supplyType,
        'lines': _lines,
      };
      if (_isEdit) {
        await repo.update(widget.noteId!, payload);
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

  Future<void> _postNote() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(debitNoteRepositoryProvider).post(widget.noteId!);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _cancelNote() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Debit Note'),
        content: const Text('Are you sure you want to cancel this debit note?'),
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
      await ref.read(debitNoteRepositoryProvider).cancel(widget.noteId!);
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
      'discount_pct': 0.0,
    });
  });

  @override
  Widget build(BuildContext context) {
    final isDraft = _noteData == null || _noteData!['status'] == 'draft';
    final status = _noteData?['status'] as String? ?? 'draft';

    return AppScaffold(
      title: _isEdit ? 'Debit Note' : 'New Debit Note',
      actions: _isEdit && isDraft
          ? [
              IconButton(
                icon: const Icon(Icons.check_circle_outline),
                tooltip: 'Post',
                onPressed: _postNote,
              ),
              IconButton(
                icon: const Icon(Icons.cancel_outlined),
                tooltip: 'Cancel',
                onPressed: _cancelNote,
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
                      labelText: 'Debit Note Date *',
                      hintText: 'YYYY-MM-DD',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: !isDraft,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                    onTap: () async {
                      if (!isDraft) return;
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        _dateController.text =
                            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Reason',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: !isDraft,
                    maxLines: 2,
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
                    ],
                    onChanged: isDraft
                        ? (v) => setState(() => _supplyType = v!)
                        : null,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Line Items',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (isDraft)
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
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                if (isDraft)
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
                              readOnly: !isDraft,
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
                                    readOnly: !isDraft,
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
                                    readOnly: !isDraft,
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
                                    readOnly: !isDraft,
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
                  if (isDraft)
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
