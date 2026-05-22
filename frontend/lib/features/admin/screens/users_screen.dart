import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../providers/admin_provider.dart';

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider);

    return AppScaffold(
      title: 'Users',
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, ref, null),
        child: const Icon(Icons.person_add),
      ),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (users) => RefreshIndicator(
          onRefresh: () => ref.refresh(adminUsersProvider.future),
          child: users.isEmpty
              ? const Center(child: Text('No users found.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: users.length,
                  itemBuilder: (ctx, i) {
                    final u = users[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: u.isActive
                              ? Colors.blue.shade100
                              : Colors.grey.shade200,
                          child: Text(
                            u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                            style: TextStyle(
                              color: u.isActive
                                  ? Colors.blue.shade800
                                  : Colors.grey,
                            ),
                          ),
                        ),
                        title: Text(u.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(u.email),
                            if (u.roles.isNotEmpty)
                              Wrap(
                                spacing: 4,
                                children: u.roles
                                    .map(
                                      (r) => Chip(
                                        label: Text(
                                          r,
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                        padding: EdgeInsets.zero,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    )
                                    .toList(),
                              ),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (v == 'edit') {
                              _showForm(context, ref, u);
                            } else if (v == 'deactivate') {
                              await ref
                                  .read(adminUsersRepositoryProvider)
                                  .deactivate(u.id);
                              ref.invalidate(adminUsersProvider);
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            if (u.isActive)
                              const PopupMenuItem(
                                value: 'deactivate',
                                child: Text('Deactivate'),
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

  void _showForm(BuildContext context, WidgetRef ref, AdminUser? user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _UserForm(user: user, ref: ref),
    );
  }
}

class _UserForm extends StatefulWidget {
  final AdminUser? user;
  final WidgetRef ref;
  const _UserForm({this.user, required this.ref});

  @override
  State<_UserForm> createState() => _UserFormState();
}

class _UserFormState extends State<_UserForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.user?.name ?? '');
  late final _email = TextEditingController(text: widget.user?.email ?? '');
  final _password = TextEditingController();
  String _role = 'staff';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final allowedRoles = [
      'super-admin',
      'admin',
      'accountant',
      'staff',
      'viewer',
    ];
    if (widget.user != null && widget.user!.roles.isNotEmpty) {
      final userRole = widget.user!.roles.first;
      if (allowedRoles.contains(userRole)) {
        _role = userRole;
      } else {
        _role = 'staff';
      }
    }
  }

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
              widget.user == null ? 'Add User' : 'Edit User',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            if (widget.user == null) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _password,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (v) => v!.length < 8 ? 'Min 8 characters' : null,
              ),
            ],
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _role,
              decoration: const InputDecoration(
                labelText: 'Role',
                border: OutlineInputBorder(),
              ),
              items: [
                'super-admin',
                'admin',
                'accountant',
                'staff',
                'viewer',
              ].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (v) => setState(() => _role = v!),
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
                    : Text(widget.user == null ? 'Add User' : 'Update'),
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
    final repo = widget.ref.read(adminUsersRepositoryProvider);
    try {
      if (widget.user == null) {
        await repo.create({
          'name': _name.text,
          'email': _email.text,
          'password': _password.text,
          'password_confirmation': _password.text,
          'role': _role,
        });
      } else {
        await repo.update(widget.user!.id, {
          'name': _name.text,
          'email': _email.text,
          'role': _role,
        });
      }
      widget.ref.invalidate(adminUsersProvider);
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
    _email.dispose();
    _password.dispose();
    super.dispose();
  }
}
