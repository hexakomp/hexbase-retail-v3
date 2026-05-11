import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../providers/vendor_provider.dart';

class VendorFormScreen extends ConsumerStatefulWidget {
  final int? vendorId;
  const VendorFormScreen({super.key, this.vendorId});

  @override
  ConsumerState<VendorFormScreen> createState() => _VendorFormScreenState();
}

class _VendorFormScreenState extends ConsumerState<VendorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _saving = false;
  String? _error;

  final _name = TextEditingController();
  final _code = TextEditingController();
  final _gstin = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _pincode = TextEditingController();
  final _tdsRate = TextEditingController();
  String _gstType = 'regular';
  bool _tdsApplicable = false;

  bool get _isEdit => widget.vendorId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _loadVendor();
  }

  Future<void> _loadVendor() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(vendorRepositoryProvider);
      final res = await repo.get(widget.vendorId!);
      final d = res['data'] as Map<String, dynamic>;
      _name.text = d['name'] ?? '';
      _code.text = d['code'] ?? '';
      _gstin.text = d['gstin'] ?? '';
      _phone.text = d['phone'] ?? '';
      _email.text = d['email'] ?? '';
      _address.text = d['address'] ?? '';
      _city.text = d['city'] ?? '';
      _state.text = d['state'] ?? '';
      _pincode.text = d['pincode'] ?? '';
      _tdsRate.text = d['tds_rate']?.toString() ?? '';
      setState(() {
        _gstType = d['gst_type'] ?? 'regular';
        _tdsApplicable =
            d['tds_applicable'] == true || d['tds_applicable'] == 1;
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
      final repo = ref.read(vendorRepositoryProvider);
      final data = {
        'name': _name.text.trim(),
        'code': _code.text.trim(),
        'gstin': _gstin.text.trim(),
        'gst_type': _gstType,
        'phone': _phone.text.trim(),
        'email': _email.text.trim(),
        'address': _address.text.trim(),
        'city': _city.text.trim(),
        'state': _state.text.trim(),
        'pincode': _pincode.text.trim(),
        'tds_applicable': _tdsApplicable,
        if (_tdsRate.text.isNotEmpty)
          'tds_rate': double.tryParse(_tdsRate.text),
      };

      if (_isEdit)
        await repo.update(widget.vendorId!, data);
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
      _gstin,
      _phone,
      _email,
      _address,
      _city,
      _state,
      _pincode,
      _tdsRate,
    ])
      c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: _isEdit ? 'Edit Vendor' : 'New Vendor',
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
                      labelText: 'Vendor Name *',
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _code,
                    decoration: const InputDecoration(labelText: 'Vendor Code'),
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
                    'Address',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _address,
                    decoration: const InputDecoration(
                      labelText: 'Street Address',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _city,
                          decoration: const InputDecoration(labelText: 'City'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _state,
                          decoration: const InputDecoration(labelText: 'State'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _pincode,
                          decoration: const InputDecoration(
                            labelText: 'Pincode',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'TDS Settings',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SwitchListTile(
                    title: const Text('TDS Applicable'),
                    value: _tdsApplicable,
                    onChanged: (v) => setState(() => _tdsApplicable = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (_tdsApplicable) ...[
                    TextFormField(
                      controller: _tdsRate,
                      decoration: const InputDecoration(
                        labelText: 'TDS Rate (%)',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isEdit ? 'Update Vendor' : 'Create Vendor'),
                  ),
                ],
              ),
            ),
    );
  }
}
