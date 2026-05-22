import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../providers/quotation_provider.dart';

class QuotationListScreen extends ConsumerStatefulWidget {
  const QuotationListScreen({super.key});

  @override
  ConsumerState<QuotationListScreen> createState() =>
      _QuotationListScreenState();
}

class _QuotationListScreenState extends ConsumerState<QuotationListScreen> {
  final _searchController = TextEditingController();
  final _statuses = [
    null,
    'draft',
    'sent',
    'accepted',
    'rejected',
    'converted',
  ];
  final _statusLabels = [
    'All',
    'Draft',
    'Sent',
    'Accepted',
    'Rejected',
    'Converted',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(quotationListProvider.notifier).load(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'draft':
        return Colors.grey;
      case 'sent':
        return Colors.blue;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'converted':
        return Colors.purple;
      case 'expired':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quotationListProvider);
    final notifier = ref.read(quotationListProvider.notifier);

    return AppScaffold(
      title: 'Quotations',
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/quotations/new');
          notifier.load();
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search quotations…',
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
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _statuses.length,
              itemBuilder: (ctx, i) {
                final selected = state.statusFilter == _statuses[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(_statusLabels[i]),
                    selected: selected,
                    onSelected: (_) => notifier.setStatusFilter(_statuses[i]),
                  ),
                );
              },
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
                  ? const Center(child: Text('No quotations found'))
                  : ListView.builder(
                      itemCount: state.items.length,
                      itemBuilder: (ctx, i) {
                        final q = state.items[i];
                        final effectiveStatus =
                            q.isExpired && q.status == 'sent'
                            ? 'expired'
                            : q.status;
                        return ListTile(
                          onTap: () async {
                            await context.push('/quotations/${q.id}');
                            notifier.load(page: state.currentPage);
                          },
                          title: Text(q.quotationNo),
                          subtitle: Text(q.customerName ?? 'No customer'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹ ${q.totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Chip(
                                label: Text(
                                  effectiveStatus.toUpperCase(),
                                  style: const TextStyle(fontSize: 10),
                                ),
                                backgroundColor: _statusColor(
                                  effectiveStatus,
                                ).withOpacity(0.15),
                                labelStyle: TextStyle(
                                  color: _statusColor(effectiveStatus),
                                ),
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
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
