import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../payment_repository.dart';
import '../providers/payment_list_provider.dart';
import '../../../shared/widgets/app_scaffold.dart';

class PaymentListScreen extends ConsumerWidget {
  const PaymentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(paymentListProvider);
    final notifier = ref.read(paymentListProvider.notifier);

    return AppScaffold(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Vendor Payments'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: notifier.refresh,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.go('/payments/new'),
          icon: const Icon(Icons.add),
          label: const Text('New Payment'),
        ),
        body: Column(
          children: [
            _SearchAndFilter(notifier: notifier, state: state),
            if (state.error != null)
              MaterialBanner(
                content: Text(state.error!),
                actions: [
                  TextButton(
                    onPressed: notifier.refresh,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.items.isEmpty
                  ? _EmptyState(onNew: () => context.go('/payments/new'))
                  : _PaymentList(items: state.items, notifier: notifier),
            ),
            if (!state.isLoading && state.lastPage > 1)
              _Pagination(state: state, notifier: notifier),
          ],
        ),
      ),
    );
  }
}

class _SearchAndFilter extends StatefulWidget {
  final PaymentListNotifier notifier;
  final PaymentListState state;

  const _SearchAndFilter({required this.notifier, required this.state});

  @override
  State<_SearchAndFilter> createState() => _SearchAndFilterState();
}

class _SearchAndFilterState extends State<_SearchAndFilter> {
  final _searchCtrl = TextEditingController();

  static const _statuses = [
    (label: 'All', value: null as String?),
    (label: 'Draft', value: 'draft'),
    (label: 'Confirmed', value: 'confirmed'),
    (label: 'Cancelled', value: 'cancelled'),
  ];

  static const _modes = [
    (label: 'All Modes', value: null as String?),
    (label: 'Cash', value: 'cash'),
    (label: 'Bank Transfer', value: 'bank_transfer'),
    (label: 'UPI', value: 'upi'),
    (label: 'Cheque', value: 'cheque'),
    (label: 'Card', value: 'card'),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search by payment number or vendor…',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        widget.notifier.search('');
                      },
                    )
                  : null,
            ),
            onChanged: (q) {
              setState(() {});
              widget.notifier.search(q);
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _statuses.map((s) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(s.label),
                          selected: widget.state.statusFilter == s.value,
                          onSelected: (_) =>
                              widget.notifier.filterByStatus(s.value),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              DropdownButton<String?>(
                value: widget.state.modeFilter,
                hint: const Text('Mode'),
                onChanged: widget.notifier.filterByMode,
                items: _modes
                    .map(
                      (m) => DropdownMenuItem(
                        value: m.value,
                        child: Text(m.label),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentList extends StatelessWidget {
  final List<PaymentSummary> items;
  final PaymentListNotifier notifier;

  const _PaymentList({required this.items, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (ctx, i) => _PaymentTile(payment: items[i]),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final PaymentSummary payment;
  const _PaymentTile({required this.payment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modeColor = payment.paymentMode == 'cash'
        ? Colors.green
        : Colors.orange;

    return ListTile(
      title: Row(
        children: [
          Text(
            payment.paymentNumber,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Chip(
            label: Text(
              payment.status.toUpperCase(),
              style: const TextStyle(fontSize: 10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
      subtitle: Text('${payment.vendorName}  ·  ${payment.paymentDate}'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '₹${payment.amount.toStringAsFixed(2)}',
            style: theme.textTheme.titleSmall,
          ),
          if (payment.tdsAmount > 0)
            Text(
              'TDS ₹${payment.tdsAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          Chip(
            label: Text(
              payment.paymentMode.toUpperCase(),
              style: TextStyle(fontSize: 10, color: modeColor),
            ),
            backgroundColor: modeColor.withOpacity(0.08),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
      onTap: () => context.go('/payments/${payment.id}'),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onNew;
  const _EmptyState({required this.onNew});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.payment_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No payments found', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onNew,
            icon: const Icon(Icons.add),
            label: const Text('New Payment'),
          ),
        ],
      ),
    );
  }
}

class _Pagination extends StatelessWidget {
  final PaymentListState state;
  final PaymentListNotifier notifier;

  const _Pagination({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: state.currentPage > 1
                ? () => notifier.load(page: state.currentPage - 1)
                : null,
          ),
          Text('Page ${state.currentPage} of ${state.lastPage}'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: state.currentPage < state.lastPage
                ? () => notifier.load(page: state.currentPage + 1)
                : null,
          ),
        ],
      ),
    );
  }
}
