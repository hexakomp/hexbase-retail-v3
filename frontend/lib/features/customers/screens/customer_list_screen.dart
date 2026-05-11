import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../providers/customer_provider.dart';
import 'customer_form_screen.dart';

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customerListProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerListProvider);
    final notifier = ref.read(customerListProvider.notifier);

    return AppScaffold(
      title: 'Customers',
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CustomerFormScreen()),
          );
          notifier.load();
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search customers…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          notifier.search('');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => notifier.search(v),
            ),
          ),
          if (state.isLoading) const LinearProgressIndicator(),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                state.error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => notifier.load(),
              child: state.items.isEmpty && !state.isLoading
                  ? const Center(child: Text('No customers found'))
                  : ListView.builder(
                      itemCount: state.items.length,
                      itemBuilder: (ctx, i) {
                        final c = state.items[i];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(c.name.substring(0, 1).toUpperCase()),
                          ),
                          title: Text(c.name),
                          subtitle: Text(
                            [c.code, c.gstin, c.phone]
                                .where((s) => s != null && s.isNotEmpty)
                                .join(' · '),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (c.gstType != null)
                                Chip(
                                  label: Text(c.gstType!.toUpperCase()),
                                  padding: EdgeInsets.zero,
                                ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          CustomerFormScreen(customerId: c.id),
                                    ),
                                  );
                                  notifier.load(page: state.currentPage);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
          if (state.lastPage > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: state.currentPage > 1
                      ? () => notifier.load(page: state.currentPage - 1)
                      : null,
                ),
                Text('${state.currentPage} / ${state.lastPage}'),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: state.currentPage < state.lastPage
                      ? () => notifier.load(page: state.currentPage + 1)
                      : null,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
