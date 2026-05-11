import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../providers/customer_provider.dart';

class CustomerFormScreen extends ConsumerStatefulWidget {
  final int? customerId;
  const CustomerFormScreen({super.key, this.customerId});

  @override
  ConsumerState<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends ConsumerState<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _saving = false;
  String? _error;

  final _name = TextEditingController();
  final _code = TextEditingController();
  final _gstin = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _billingAddress = TextEditingController();
  final _billingCity = TextEditingController();
  final _billingState = TextEditingController();
  final _billingPincode = TextEditingController();
  final _creditLimit = TextEditingController();
  String _gstType = 'regular';

  bool get _isEdit => widget.customerId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _loadCustomer();
  }

  Future<void> _loadCustomer() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(customerRepositoryProvider);
      final res = await repo.get(widget.customerId!);
      final d = res['data'] as Map<String, dynamic>;
      _name.text = d['name'] ?? '';
      _code.text = d['code'] ?? '';
      _gstin.text = d['gstin'] ?? '';
      _phone.text = d['phone'] ?? '';
      _email.text = d['email'] ?? '';
      _billingAddress.text = d['billing_address'] ?? '';
      _billingCity.text = d['billing_city'] ?? '';
      _billingState.text = d['billing_state'] ?? '';
      _billingPincode.text = d['billing_pincode'] ?? '';
      _creditLimit.text = d['credit_limit']?.toString() ?? '';
      setState(() {
        _gstType = d['gst_type'] ?? 'regular';
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
      final repo = ref.read(customerRepositoryProvider);
      final data = {
        'name': _name.text.trim(),
        'code': _code.text.trim(),
        'gstin': _gstin.text.trim(),
        'gst_type': _gstType,
        'phone': _phone.text.trim(),
        'email': _email.text.trim(),
        'billing_address': _billingAddress.text.trim(),
        'billing_city': _billingCity.text.trim(),
        'billing_state': _billingState.text.trim(),
        'billing_pincode': _billingPincode.text.trim(),
        if (_creditLimit.text.isNotEmpty)
          'credit_limit': double.tryParse(_creditLimit.text),
      };

      if (_isEdit) {
        await repo.update(widget.customerId!, data);
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
    for (final c in [
      _name,
      _code,
      _gstin,
      _phone,
      _email,
      _billingAddress,
      _billingCity,
      _billingState,
      _billingPincode,
      _creditLimit,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: _isEdit ? 'Edit Customer' : 'New Customer',
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
                      labelText: 'Customer Name *',
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _code,
                    decoration: const InputDecoration(
                      labelText: 'Customer Code',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _gstType,
                    decoration: const InputDecoration(labelText: 'GST Type'),
                    items: const [
                      DropdownMenuItem(
                        value: 'regular',
                        child: Text('Regular'),
                      ),
                      DropdownMenuItem(
                        value: 'composition',
                        child: Text('Composition'),
                      ),
                      DropdownMenuItem(
                        value: 'unregistered',
                        child: Text('Unregistered'),
                      ),
                      DropdownMenuItem(
                        value: 'consumer',
                        child: Text('Consumer'),
                      ),
                      DropdownMenuItem(
                        value: 'overseas',
                        child: Text('Overseas'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _gstType = v!),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _gstin,
                    decoration: const InputDecoration(labelText: 'GSTIN'),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phone,
                    decoration: const InputDecoration(labelText: 'Phone'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _email,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Billing Address',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _billingAddress,
                    decoration: const InputDecoration(labelText: 'Address'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _billingCity,
                          decoration: const InputDecoration(labelText: 'City'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _billingState,
                          decoration: const InputDecoration(labelText: 'State'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _billingPincode,
                          decoration: const InputDecoration(
                            labelText: 'Pincode',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _creditLimit,
                    decoration: const InputDecoration(
                      labelText: 'Credit Limit (₹)',
                    ),
                    keyboardType: TextInputType.number,
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
                        : Text(_isEdit ? 'Update Customer' : 'Create Customer'),
                  ),
                ],
              ),
            ),
    );
  }
}
