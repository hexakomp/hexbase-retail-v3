import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../providers/admin_provider.dart';

class CompanySettingsScreen extends ConsumerStatefulWidget {
  const CompanySettingsScreen({super.key});

  @override
  ConsumerState<CompanySettingsScreen> createState() =>
      _CompanySettingsScreenState();
}

class _CompanySettingsScreenState extends ConsumerState<CompanySettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = true;
  bool _saving = false;

  final _name = TextEditingController();
  final _gstin = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _pincode = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _website = TextEditingController();
  final _pan = TextEditingController();
  final _cin = TextEditingController();
  final _bankName = TextEditingController();
  final _bankAccount = TextEditingController();
  final _bankIfsc = TextEditingController();
  final _bankBranch = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final repo = ref.read(companySettingsRepositoryProvider);
      final data = await repo.get();
      _name.text = data['name'] ?? '';
      _gstin.text = data['gstin'] ?? '';
      _address.text = data['address'] ?? '';
      _city.text = data['city'] ?? '';
      _state.text = data['state'] ?? '';
      _pincode.text = data['pincode'] ?? '';
      _phone.text = data['phone'] ?? '';
      _email.text = data['email'] ?? '';
      _website.text = data['website'] ?? '';
      _pan.text = data['pan'] ?? '';
      _cin.text = data['cin'] ?? '';
      _bankName.text = data['bank_name'] ?? '';
      _bankAccount.text = data['bank_account_no'] ?? '';
      _bankIfsc.text = data['bank_ifsc'] ?? '';
      _bankBranch.text = data['bank_branch'] ?? '';
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(companySettingsRepositoryProvider).update({
        'name': _name.text,
        'gstin': _gstin.text,
        'address': _address.text,
        'city': _city.text,
        'state': _state.text,
        'pincode': _pincode.text,
        'phone': _phone.text,
        'email': _email.text,
        'website': _website.text,
        'pan': _pan.text,
        'cin': _cin.text,
        'bank_name': _bankName.text,
        'bank_account_no': _bankAccount.text,
        'bank_ifsc': _bankIfsc.text,
        'bank_branch': _bankBranch.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Settings saved.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    setState(() => _saving = false);
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    bool required = false,
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: required ? (v) => v!.isEmpty ? 'Required' : null : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Company Settings',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Basic Info',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _field('Company Name', _name, required: true),
                    _field('GSTIN', _gstin, required: true),
                    _field('PAN', _pan),
                    _field('CIN', _cin),
                    const SizedBox(height: 8),
                    Text(
                      'Address',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _field('Address', _address),
                    _field('City', _city),
                    _field('State', _state),
                    _field('Pincode', _pincode),
                    const SizedBox(height: 8),
                    Text(
                      'Contact',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _field('Phone', _phone, keyboard: TextInputType.phone),
                    _field(
                      'Email',
                      _email,
                      keyboard: TextInputType.emailAddress,
                    ),
                    _field('Website', _website, keyboard: TextInputType.url),
                    const SizedBox(height: 8),
                    Text(
                      'Bank Details',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _field('Bank Name', _bankName),
                    _field('Account Number', _bankAccount),
                    _field('IFSC Code', _bankIfsc),
                    _field('Branch', _bankBranch),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Save Settings'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _gstin,
      _address,
      _city,
      _state,
      _pincode,
      _phone,
      _email,
      _website,
      _pan,
      _cin,
      _bankName,
      _bankAccount,
      _bankIfsc,
      _bankBranch,
    ]) {
      c.dispose();
    }
    super.dispose();
  }
}
