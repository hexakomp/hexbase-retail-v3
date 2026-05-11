import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../providers/quotation_provider.dart';

class QuotationDetailScreen extends ConsumerStatefulWidget {
  final int quotationId;
  const QuotationDetailScreen({super.key, required this.quotationId});

  @override
  ConsumerState<QuotationDetailScreen> createState() =>
      _QuotationDetailScreenState();
}

class _QuotationDetailScreenState extends ConsumerState<QuotationDetailScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  bool _actionLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(quotationRepositoryProvider);
      final res = await repo.get(widget.quotationId);
      setState(() {
        _data = res['data'] as Map<String, dynamic>;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  String get _status => _data?['status'] as String? ?? '';
  bool get _isExpired => _data?['is_expired'] == true;

  String get _effectiveStatus {
    if (_isExpired && _status == 'sent') return 'expired';
    return _status;
  }

  Color _statusColor(String s) {
    switch (s) {
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

  Future<void> _send() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send Quotation'),
        content: const Text('Mark this quotation as Sent?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _actionLoading = true);
    try {
      final repo = ref.read(quotationRepositoryProvider);
      await repo.post(widget.quotationId);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _convert() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Convert to Invoice'),
        content: const Text(
          'This will create a Sales Invoice from this quotation. Proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Convert'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _actionLoading = true);
    try {
      final repo = ref.read(quotationRepositoryProvider);
      final res = await repo.convert(widget.quotationId);
      await _load();
      if (mounted) {
        final invoice = res['data'] as Map<String, dynamic>?;
        final invoiceNo = invoice?['invoice_no'] ?? 'New invoice created';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Converted! Invoice: $invoiceNo'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Quotation'),
        content: const Text(
          'This action cannot be undone. Delete this quotation?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final repo = ref.read(quotationRepositoryProvider);
      await repo.delete(widget.quotationId);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;

    return AppScaffold(
      title: d == null
          ? 'Quotation Detail'
          : (d['quotation_no'] as String? ?? 'Quotation'),
      actions: [
        if (d != null && _status == 'draft')
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      QuotationFormScreen(quotationId: widget.quotationId),
                ),
              );
              if (result == true) _load();
            },
          ),
        if (d != null && _status == 'draft')
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
            onPressed: _delete,
          ),
      ],
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                    TextButton(onPressed: _load, child: const Text('Retry')),
                  ],
                ),
              )
            : _buildBody(d!),
      ),
    );
  }

  Widget _buildBody(Map<String, dynamic> d) {
    final customer = d['customer'] as Map<String, dynamic>?;
    final lines = d['lines'] as List<dynamic>? ?? [];
    final convertedInvoice = d['converted_invoice'] as Map<String, dynamic>?;
    final status = _effectiveStatus;

    double taxableAmount = 0;
    double totalGst = 0;
    for (final l in lines) {
      final line = l as Map<String, dynamic>;
      final qty = (line['quantity'] as num?)?.toDouble() ?? 0;
      final price = (line['unit_price'] as num?)?.toDouble() ?? 0;
      final disc = (line['discount_percent'] as num?)?.toDouble() ?? 0;
      final gstRate = (line['gst_rate'] as num?)?.toInt() ?? 0;
      final base = qty * price * (1 - disc / 100);
      taxableAmount += base;
      totalGst += base * gstRate / 100;
    }
    final grandTotal = taxableAmount + totalGst;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Expired banner
        if (_isExpired && _status != 'converted')
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              border: Border.all(color: Colors.orange),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'This quotation has expired',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

        // Header card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        d['quotation_no'] as String? ?? '—',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Chip(
                      label: Text(
                        status.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: _statusColor(status),
                    ),
                  ],
                ),
                const Divider(),
                _infoRow('Customer', customer?['name'] as String? ?? '—'),
                if (customer?['gstin'] != null)
                  _infoRow('GSTIN', customer!['gstin'] as String),
                _infoRow('Date', d['quotation_date'] as String? ?? '—'),
                _infoRow('Valid Until', d['valid_until'] as String? ?? '—'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Line items
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Line Items',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const Divider(height: 1),
              for (final l in lines) _buildLineItem(l as Map<String, dynamic>),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Tax summary
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _summaryRow(
                  'Taxable Amount',
                  '₹ ${taxableAmount.toStringAsFixed(2)}',
                ),
                _summaryRow('Total GST', '₹ ${totalGst.toStringAsFixed(2)}'),
                const Divider(),
                _summaryRow(
                  'Grand Total',
                  '₹ ${grandTotal.toStringAsFixed(2)}',
                  bold: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Notes / Terms
        if ((d['notes'] as String? ?? '').isNotEmpty) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Notes', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(d['notes'] as String),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        if ((d['terms_conditions'] as String? ?? '').isNotEmpty) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Terms & Conditions',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(d['terms_conditions'] as String),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Converted invoice info
        if (_status == 'converted' && convertedInvoice != null) ...[
          Card(
            color: Colors.purple.shade50,
            child: ListTile(
              leading: const Icon(Icons.receipt_long, color: Colors.purple),
              title: const Text('Converted to Invoice'),
              subtitle: Text(convertedInvoice['invoice_no'] as String? ?? ''),
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Action buttons
        if (_actionLoading)
          const Center(child: CircularProgressIndicator())
        else ...[
          if (_status == 'draft')
            FilledButton.icon(
              icon: const Icon(Icons.send),
              label: const Text('Send Quotation'),
              onPressed: _send,
            ),
          if (_status == 'sent' || _status == 'accepted')
            FilledButton.icon(
              icon: const Icon(Icons.receipt_long),
              label: const Text('Convert to Invoice'),
              onPressed: _convert,
            ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildLineItem(Map<String, dynamic> line) {
    final product = line['product'] as Map<String, dynamic>?;
    final name =
        product?['name'] as String? ?? line['description'] as String? ?? '—';
    final qty = (line['quantity'] as num?)?.toDouble() ?? 0;
    final price = (line['unit_price'] as num?)?.toDouble() ?? 0;
    final disc = (line['discount_percent'] as num?)?.toDouble() ?? 0;
    final gstRate = (line['gst_rate'] as num?)?.toInt() ?? 0;
    final base = qty * price * (1 - disc / 100);
    final total = base * (1 + gstRate / 100);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                if ((line['description'] as String? ?? '').isNotEmpty &&
                    product != null)
                  Text(
                    line['description'] as String,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                Text(
                  '$qty × ₹${price.toStringAsFixed(2)}  GST: $gstRate%${disc > 0 ? '  Disc: $disc%' : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            '₹ ${total.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null,
          ),
          Text(
            value,
            style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null,
          ),
        ],
      ),
    );
  }
}
