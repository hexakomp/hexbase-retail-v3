import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../providers/product_provider.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(productListProvider.notifier).load(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _stockColor(double? stock) {
    if (stock == null) return Colors.grey;
    if (stock <= 0) return Colors.red;
    if (stock < 10) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productListProvider);
    final notifier = ref.read(productListProvider.notifier);

    return AppScaffold(
      title: 'Products',
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/products/new');
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
                hintText: 'Search products…',
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
                  ? const Center(child: Text('No products found'))
                  : ListView.builder(
                      itemCount: state.items.length,
                      itemBuilder: (ctx, i) {
                        final p = state.items[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _stockColor(p.currentStock),
                            child: Text(
                              p.name.substring(0, 1).toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(p.name),
                          subtitle: Text(
                            [
                              if (p.code != null) p.code!,
                              if (p.hsn != null) 'HSN: ${p.hsn}',
                              'GST: ${p.gstRate}%',
                            ].join(' · '),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (p.currentStock != null)
                                Chip(
                                  label: Text(
                                    '${p.currentStock!.toStringAsFixed(0)} ${p.unit ?? ''}',
                                  ),
                                  backgroundColor: _stockColor(
                                    p.currentStock,
                                  ).withOpacity(0.15),
                                ),
                              PopupMenuButton<String>(
                                onSelected: (action) async {
                                  if (action == 'edit') {
                                    await context.push(
                                      '/products/${p.id}/edit',
                                    );
                                    notifier.load(page: state.currentPage);
                                  } else if (action == 'stock') {
                                    await context.push(
                                      '/products/${p.id}/stock?name=${Uri.encodeComponent(p.name)}',
                                    );
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: ListTile(
                                      leading: Icon(Icons.edit),
                                      title: Text('Edit'),
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'stock',
                                    child: ListTile(
                                      leading: Icon(Icons.inventory_2),
                                      title: Text('Stock Summary'),
                                    ),
                                  ),
                                ],
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
