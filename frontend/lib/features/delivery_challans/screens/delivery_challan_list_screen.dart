import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../providers/delivery_challan_provider.dart';

class DeliveryChallanListScreen extends ConsumerStatefulWidget {
  const DeliveryChallanListScreen({super.key});

  @override
  ConsumerState<DeliveryChallanListScreen> createState() =>
      _DeliveryChallanListScreenState();
}

class _DeliveryChallanListScreenState
    extends ConsumerState<DeliveryChallanListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'dispatched':
        return Colors.green;
      case 'draft':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(deliveryChallanListProvider);
    final notifier = ref.read(deliveryChallanListProvider.notifier);

    return AppScaffold(
      title: 'Delivery Challans',
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/delivery-challans/new');
          notifier.refresh();
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
                hintText: 'Search challans…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          notifier.load();
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (v) => notifier.load(search: v),
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
              onRefresh: notifier.refresh,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                itemCount: state.items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final dc = state.items[index];
                  return ListTile(
                    title: Text(
                      dc.dcNumber,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(dc.customerName),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹ ${dc.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor(dc.status).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            dc.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              color: _statusColor(dc.status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    onTap: () async {
                      await context.push('/delivery-challans/${dc.id}/edit');
                      notifier.refresh();
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
