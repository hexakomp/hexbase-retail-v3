import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../providers/admin_provider.dart';

class BankAccountsScreen extends ConsumerWidget {
  const BankAccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(bankAccountsProvider);

    return AppScaffold(
      title: 'Bank Accounts',
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, ref, null),
        child: const Icon(Icons.add),
      ),
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (accounts) => RefreshIndicator(
          onRefresh: () => ref.refresh(bankAccountsProvider.future),
          child: accounts.isEmpty
              ? const Center(child: Text('No bank accounts found.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: accounts.length,
                  itemBuilder: (ctx, i) {
                    final acc = accounts[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: acc.isActive
                              ? Colors.green.shade100
                              : Colors.grey.shade200,
                          child: Icon(
                            Icons.account_balance,
                            color: acc.isActive ? Colors.green : Colors.grey,
                          ),
                        ),
                        title: Text(acc.name),
                        subtitle: Text(
                          '${acc.bankName} • ${acc.accountNumber}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: acc.isActive,
                              onChanged: (_) async {
                                await ref
                                    .read(bankAccountRepositoryProvider)
                                    .toggleActive(acc.id);
                                ref.invalidate(bankAccountsProvider);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _showForm(context, ref, acc),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  void _showForm(BuildContext context, WidgetRef ref, BankAccount? account) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _BankAccountForm(account: account, ref: ref),
    );
  }
}

class _BankAccountForm extends StatefulWidget {
  final BankAccount? account;
  final WidgetRef ref;
  const _BankAccountForm({this.account, required this.ref});

  @override
  State<_BankAccountForm> createState() => _BankAccountFormState();
}

class _BankAccountFormState extends State<_BankAccountForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.account?.name ?? '');
  late final _bankName = TextEditingController(
    text: widget.account?.bankName ?? '',
  );
  late final _accountNumber = TextEditingController(
    text: widget.account?.accountNumber ?? '',
  );
  late final _ifsc = TextEditingController(text: widget.account?.ifsc ?? '');
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.account == null ? 'Add Bank Account' : 'Edit Bank Account',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Account Label',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _bankName,
              decoration: const InputDecoration(
                labelText: 'Bank Name',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _accountNumber,
              decoration: const InputDecoration(
                labelText: 'Account Number',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _ifsc,
              decoration: const InputDecoration(
                labelText: 'IFSC Code',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
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
                    : Text(widget.account == null ? 'Add' : 'Update'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final repo = widget.ref.read(bankAccountRepositoryProvider);
    try {
      final data = {
        'name': _name.text,
        'bank_name': _bankName.text,
        'account_number': _accountNumber.text,
        'ifsc': _ifsc.text,
      };
      if (widget.account == null) {
        await repo.create(data);
      } else {
        await repo.update(widget.account!.id, data);
      }
      widget.ref.invalidate(bankAccountsProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    setState(() => _saving = false);
  }

  @override
  void dispose() {
    _name.dispose();
    _bankName.dispose();
    _accountNumber.dispose();
    _ifsc.dispose();
    super.dispose();
  }
}
