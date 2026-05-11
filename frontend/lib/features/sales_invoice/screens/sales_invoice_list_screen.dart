import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hexbase_retail/features/sales_invoice/sales_invoice_repository.dart';
import '../providers/invoice_list_provider.dart';
import '../../../shared/widgets/app_scaffold.dart';

class SalesInvoiceListScreen extends ConsumerWidget {
  const SalesInvoiceListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(invoiceListProvider);
    final notifier = ref.read(invoiceListProvider.notifier);

    return AppScaffold(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sales Invoices'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: () => notifier.refresh(),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.go('/invoices/new'),
          icon: const Icon(Icons.add),
          label: const Text('New Invoice'),
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
                  ? _EmptyState(onNew: () => context.go('/invoices/new'))
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

class _SearchAndFilter extends StatefulWidget {
  final InvoiceListNotifier notifier;
  final InvoiceListState state;
  const _SearchAndFilter({required this.notifier, required this.state});

  @override
  State<_SearchAndFilter> createState() => _SearchAndFilterState();
}

class _SearchAndFilterState extends State<_SearchAndFilter> {
  final _searchCtrl = TextEditingController();

  static const _statuses = [
    (label: 'All', value: null),
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
              hintText: 'Search by invoice number or customer…',
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
              isDense: true,
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
                  padding: const EdgeInsets.only(right: 6),
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

class _InvoiceList extends StatelessWidget {
  final List<SalesInvoiceSummary> items;
  final InvoiceListNotifier notifier;
  const _InvoiceList({required this.items, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final inv = items[i];
        return _InvoiceListTile(inv: inv, notifier: notifier);
      },
    );
  }
}

class _InvoiceListTile extends StatelessWidget {
  final SalesInvoiceSummary inv;
  final InvoiceListNotifier notifier;
  const _InvoiceListTile({required this.inv, required this.notifier});

  Color _statusColor(String status) => switch (status) {
    'draft' => Colors.grey,
    'confirmed' => Colors.blue,
    'partially_paid' => Colors.orange,
    'paid' => Colors.green,
    'cancelled' => Colors.red,
    _ => Colors.grey,
  };

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => context.go('/invoices/${inv.id}'),
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      title: Row(
        children: [
          Text(
            inv.invoiceNumber,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          Chip(
            label: Text(
              inv.status.toUpperCase(),
              style: const TextStyle(fontSize: 10, color: Colors.white),
            ),
            backgroundColor: _statusColor(inv.status),
            padding: EdgeInsets.zero,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
      subtitle: Text(
        '${inv.customerName}  ·  ${inv.invoiceDate}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '₹ ${inv.totalAmount.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          if (inv.balanceAmount > 0)
            Text(
              'Due: ₹ ${inv.balanceAmount.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 11, color: Colors.red.shade700),
            ),
        ],
      ),
      leading: _ActionMenu(inv: inv, notifier: notifier),
    );
  }
}

class _ActionMenu extends StatelessWidget {
  final SalesInvoiceSummary inv;
  final InvoiceListNotifier notifier;
  const _ActionMenu({required this.inv, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (action) async {
        switch (action) {
          case 'edit':
            context.go('/invoices/${inv.id}/edit');
          case 'post':
            await notifier.postInvoice(inv.id);
          case 'cancel':
            final reason = await _showCancelDialog(context);
            if (reason != null) {
              await notifier.cancelInvoice(inv.id, reason);
            }
          case 'pdf':
            context.go('/invoices/${inv.id}/pdf');
        }
      },
      itemBuilder: (ctx) => [
        if (inv.status == 'draft') ...[
          const PopupMenuItem(value: 'edit', child: Text('Edit')),
          const PopupMenuItem(value: 'post', child: Text('Post')),
        ],
        if (inv.status != 'cancelled')
          const PopupMenuItem(value: 'cancel', child: Text('Cancel')),
        const PopupMenuItem(value: 'pdf', child: Text('Download PDF')),
      ],
    );
  }

  Future<String?> _showCancelDialog(BuildContext context) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Invoice'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Reason (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}

class _Pagination extends StatelessWidget {
  final InvoiceListState state;
  final InvoiceListNotifier notifier;
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
            onPressed: state.currentPage > 1 ? () => notifier.prevPage() : null,
          ),
          Text('Page ${state.currentPage} of ${state.lastPage}'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: state.currentPage < state.lastPage
                ? () => notifier.nextPage()
                : null,
          ),
        ],
      ),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No invoices found'),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onNew,
            icon: const Icon(Icons.add),
            label: const Text('Create Invoice'),
          ),
        ],
      ),
    );
  }
}
