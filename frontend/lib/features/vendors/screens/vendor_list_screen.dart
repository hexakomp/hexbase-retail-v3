import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../providers/vendor_provider.dart';
import 'vendor_form_screen.dart';

class VendorListScreen extends ConsumerStatefulWidget {
  const VendorListScreen({super.key});

  @override
  ConsumerState<VendorListScreen> createState() => _VendorListScreenState();
}

class _VendorListScreenState extends ConsumerState<VendorListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(vendorListProvider.notifier).load(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vendorListProvider);
    final notifier = ref.read(vendorListProvider.notifier);

    return AppScaffold(
      title: 'Vendors',
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const VendorFormScreen()),
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
                hintText: 'Search vendors…',
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
                  ? const Center(child: Text('No vendors found'))
                  : ListView.builder(
                      itemCount: state.items.length,
                      itemBuilder: (ctx, i) {
                        final v = state.items[i];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(v.name.substring(0, 1).toUpperCase()),
                          ),
                          title: Text(v.name),
                          subtitle: Text(
                            [v.code, v.gstin, v.phone]
                                .where((s) => s != null && s.isNotEmpty)
                                .join(' · '),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      VendorFormScreen(vendorId: v.id),
                                ),
                              );
                              notifier.load(page: state.currentPage);
                            },
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
