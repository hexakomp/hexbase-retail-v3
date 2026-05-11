import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../providers/admin_provider.dart';

class NumberingSequencesScreen extends ConsumerWidget {
  const NumberingSequencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seqAsync = ref.watch(numberingSequencesProvider);

    return AppScaffold(
      title: 'Numbering Sequences',
      body: seqAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (sequences) => RefreshIndicator(
          onRefresh: () => ref.refresh(numberingSequencesProvider.future),
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: sequences.length,
            itemBuilder: (ctx, i) {
              final seq = sequences[i];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text(seq.type.replaceAll('_', ' ').toUpperCase()),
                  subtitle: Text(
                    'Prefix: ${seq.prefix}  •  Next: ${seq.nextNumber}  •  Padding: ${seq.padding}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _showEditDialog(context, ref, seq),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    NumberingSequence seq,
  ) {
    final prefix = TextEditingController(text: seq.prefix);
    final next = TextEditingController(text: seq.nextNumber.toString());
    final padding = TextEditingController(text: seq.padding.toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Edit ${seq.type.replaceAll('_', ' ')}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: prefix,
              decoration: const InputDecoration(
                labelText: 'Prefix',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: next,
              decoration: const InputDecoration(
                labelText: 'Next Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: padding,
              decoration: const InputDecoration(
                labelText: 'Padding',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await ref
                  .read(numberingSequenceRepositoryProvider)
                  .update(seq.id, {
                    'prefix': prefix.text,
                    'next_number': int.tryParse(next.text) ?? seq.nextNumber,
                    'padding': int.tryParse(padding.text) ?? seq.padding,
                  });
              ref.invalidate(numberingSequencesProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
