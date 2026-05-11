import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../providers/delivery_challan_provider.dart';

class DeliveryChallanFormScreen extends ConsumerStatefulWidget {
  final int? challanId;
  const DeliveryChallanFormScreen({super.key, this.challanId});

  @override
  ConsumerState<DeliveryChallanFormScreen> createState() =>
      _DeliveryChallanFormScreenState();
}

class _DeliveryChallanFormScreenState
    extends ConsumerState<DeliveryChallanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _challanData;

  final _dateController = TextEditingController();
  final _vehicleController = TextEditingController();
  final _transporterController = TextEditingController();
  final _destinationController = TextEditingController();
  final _notesController = TextEditingController();
  final List<Map<String, dynamic>> _lines = [];

  bool get _isEdit => widget.challanId != null;
  bool get _isDraft =>
      _challanData == null || _challanData!['status'] == 'draft';

  @override
  void initState() {
    super.initState();
    if (_isEdit) _loadChallan();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _vehicleController.dispose();
    _transporterController.dispose();
    _destinationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadChallan() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(deliveryChallanRepositoryProvider);
      final data = await repo.get(widget.challanId!);
      final dc = data['data'] as Map<String, dynamic>;
      setState(() {
        _challanData = dc;
        _dateController.text = (dc['dc_date'] as String).substring(0, 10);
        _vehicleController.text = dc['vehicle_number'] as String? ?? '';
        _transporterController.text = dc['transporter_name'] as String? ?? '';
        _destinationController.text = dc['destination'] as String? ?? '';
        _notesController.text = dc['notes'] as String? ?? '';
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
      final repo = ref.read(deliveryChallanRepositoryProvider);
      final payload = {
        'dc_date': _dateController.text,
        'vehicle_number': _vehicleController.text,
        'transporter_name': _transporterController.text,
        'destination': _destinationController.text,
        'notes': _notesController.text,
        'lines': _lines,
      };
      if (_isEdit) {
        await repo.update(widget.challanId!, payload);
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

  Future<void> _dispatch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(deliveryChallanRepositoryProvider)
          .dispatch(widget.challanId!);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _cancelChallan() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Challan'),
        content: const Text(
          'Are you sure you want to cancel this delivery challan?',
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
      await ref
          .read(deliveryChallanRepositoryProvider)
          .cancel(widget.challanId!);
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
    });
  });

  @override
  Widget build(BuildContext context) {
    final status = _challanData?['status'] as String? ?? 'draft';

    return AppScaffold(
      title: _isEdit ? 'Delivery Challan' : 'New Delivery Challan',
      actions: _isEdit && _isDraft
          ? [
              IconButton(
                icon: const Icon(Icons.local_shipping),
                tooltip: 'Dispatch',
                onPressed: _dispatch,
              ),
              IconButton(
                icon: const Icon(Icons.cancel_outlined),
                tooltip: 'Cancel',
                onPressed: _cancelChallan,
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
                      labelText: 'DC Date *',
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
                    controller: _vehicleController,
                    decoration: const InputDecoration(
                      labelText: 'Vehicle Number',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: !_isDraft,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _transporterController,
                    decoration: const InputDecoration(
                      labelText: 'Transporter',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: !_isDraft,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _destinationController,
                    decoration: const InputDecoration(
                      labelText: 'Destination',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: !_isDraft,
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
