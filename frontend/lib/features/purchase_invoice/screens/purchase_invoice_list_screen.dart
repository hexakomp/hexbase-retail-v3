import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../purchase_invoice_repository.dart';
import '../providers/purchase_invoice_list_provider.dart';
import '../../../shared/widgets/app_scaffold.dart';

class PurchaseInvoiceListScreen extends ConsumerWidget {
  const PurchaseInvoiceListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(purchaseInvoiceListProvider);
    final notifier = ref.read(purchaseInvoiceListProvider.notifier);

    return AppScaffold(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Purchase Invoices'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: () => notifier.refresh(),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.go('/purchase-invoices/new'),
          icon: const Icon(Icons.add),
          label: const Text('New Purchase Invoice'),
        ),
        body: Column(
          children: [
            _SearchAndFilter(notifier: notifier, state: state),
            if (state.error != null)
              MaterialBanner(
                content: Text(state.error!),
                actions: [
                  TextButton(
                    onPressed: () => notifier.refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.items.isEmpty
                  ? _EmptyState(
                      onNew: () => context.go('/purchase-invoices/new'),
                    )
                  : _InvoiceList(items: state.items, notifier: notifier),
            ),
            if (!state.isLoading && state.lastPage > 1)
              _Pagination(state: state, notifier: notifier),
          ],
        ),
      ),
    );
  }
}

// ── Search & Filter bar ────────────────────────────────────────────────────

class _SearchAndFilter extends StatefulWidget {
  final PurchaseInvoiceListNotifier notifier;
  final PurchaseInvoiceListState state;

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
    (label: 'Partial', value: 'partially_paid'),
    (label: 'Paid', value: 'paid'),
    (label: 'Cancelled', value: 'cancelled'),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search by invoice number or vendor…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        widget.notifier.search('');
                      },
                    )
                  : null,
              border: const OutlineInputBorder(),
            ),
            onChanged: (q) {
              setState(() {});
              widget.notifier.search(q);
            },
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statuses.map((s) {
                final selected = widget.state.statusFilter == s.value;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(s.label),
                    selected: selected,
                    onSelected: (_) => widget.notifier.filterByStatus(s.value),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Invoice List ────────────────────────────────────────────────────────────

class _InvoiceList extends StatelessWidget {
  final List<PurchaseInvoiceSummary> items;
  final PurchaseInvoiceListNotifier notifier;

  const _InvoiceList({required this.items, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (ctx, i) => _InvoiceTile(invoice: items[i]),
      ),
    );
  }
}

class _InvoiceTile extends StatelessWidget {
  final PurchaseInvoiceSummary invoice;

  const _InvoiceTile({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      title: Row(
        children: [
          Text(
            invoice.invoiceNumber,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          _StatusChip(invoice.status),
        ],
      ),
      subtitle: Text(
        '${invoice.vendorName}  ·  ${invoice.invoiceDate}'
        '${invoice.vendorInvoiceNumber != null ? '  ·  ${invoice.vendorInvoiceNumber}' : ''}',
        style: theme.textTheme.bodySmall,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '₹${invoice.totalAmount.toStringAsFixed(2)}',
            style: theme.textTheme.titleSmall,
          ),
          if (invoice.balanceAmount > 0)
            Text(
              'Due: ₹${invoice.balanceAmount.toStringAsFixed(2)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
        ],
      ),
      onTap: () => context.go('/purchase-invoices/${invoice.id}'),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'draft' => Colors.grey,
      'confirmed' => Colors.blue,
      'partially_paid' => Colors.orange,
      'paid' => Colors.green,
      'cancelled' => Colors.red,
      _ => Colors.grey,
    };
    return Chip(
      label: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 10, color: color.shade700),
      ),
      backgroundColor: color.shade50,
      side: BorderSide(color: color.shade200),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
    );
  }
}

// ── Empty state ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onNew;
  const _EmptyState({required this.onNew});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No purchase invoices found',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onNew,
            icon: const Icon(Icons.add),
            label: const Text('New Purchase Invoice'),
          ),
        ],
      ),
    );
  }
}

// ── Pagination ──────────────────────────────────────────────────────────────

class _Pagination extends StatelessWidget {
  final PurchaseInvoiceListState state;
  final PurchaseInvoiceListNotifier notifier;

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
