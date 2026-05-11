import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/product_provider.dart';

class StockAdjustmentDialog extends ConsumerStatefulWidget {
  final int productId;
  final String productName;
  const StockAdjustmentDialog({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  ConsumerState<StockAdjustmentDialog> createState() =>
      _StockAdjustmentDialogState();
}

class _StockAdjustmentDialogState extends ConsumerState<StockAdjustmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _qty = TextEditingController();
  final _cost = TextEditingController();
  final _narration = TextEditingController();
  bool _saving = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repo = ref.read(productRepositoryProvider);
      await repo.stockAdjustment(widget.productId, {
        'adjusted_qty': double.parse(_qty.text),
        if (_cost.text.isNotEmpty) 'adjusted_cost': double.tryParse(_cost.text),
        'narration': _narration.text.trim(),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _qty.dispose();
    _cost.dispose();
    _narration.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Adjust Stock: ${widget.productName}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            TextFormField(
              controller: _qty,
              decoration: const InputDecoration(
                labelText: 'Adjusted Quantity *',
                helperText: 'Use negative to reduce stock',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                signed: true,
                decimal: true,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (double.tryParse(v) == null) return 'Enter a valid number';
                if (double.parse(v) == 0) return 'Cannot be zero';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cost,
              decoration: const InputDecoration(
                labelText: 'Unit Cost (₹, optional)',
                helperText: 'Leave blank to use current WAC',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _narration,
              decoration: const InputDecoration(
                labelText: 'Narration / Reason *',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Adjust'),
        ),
      ],
    );
  }
}
