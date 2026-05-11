import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../providers/pdf_template_provider.dart';

class PdfTemplatesScreen extends ConsumerWidget {
  const PdfTemplatesScreen({super.key});

  static const _docTypes = [
    'sales_invoice',
    'credit_note',
    'debit_note',
    'purchase_order',
    'delivery_challan',
    'quotation',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(pdfTemplatesProvider);

    return AppScaffold(
      title: 'PDF Templates',
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(context, ref, null),
        child: const Icon(Icons.add),
      ),
      body: templatesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (templates) => RefreshIndicator(
          onRefresh: () => ref.refresh(pdfTemplatesProvider.future),
          child: templates.isEmpty
              ? const Center(child: Text('No PDF templates found.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: templates.length,
                  itemBuilder: (ctx, i) {
                    final t = templates[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: t.isDefault
                              ? Colors.green.shade100
                              : Colors.grey.shade200,
                          child: Icon(
                            Icons.description,
                            color: t.isDefault ? Colors.green : Colors.grey,
                          ),
                        ),
                        title: Text(t.name),
                        subtitle: Text(
                          '${t.documentType.replaceAll('_', ' ')}${t.isDefault ? '  •  DEFAULT' : ''}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!t.isDefault)
                              IconButton(
                                icon: const Icon(Icons.star_border),
                                tooltip: 'Set as default',
                                onPressed: () async {
                                  await ref
                                      .read(pdfTemplateRepositoryProvider)
                                      .setDefault(t.id);
                                  ref.invalidate(pdfTemplatesProvider);
                                },
                              ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _openEditor(context, ref, t),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Delete Template'),
                                    content: Text('Delete "${t.name}"?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (ok == true) {
                                  await ref
                                      .read(pdfTemplateRepositoryProvider)
                                      .delete(t.id);
                                  ref.invalidate(pdfTemplatesProvider);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  void _openEditor(BuildContext context, WidgetRef ref, PdfTemplate? template) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProviderScope(
          parent: ProviderScope.containerOf(context),
          child: _TemplateEditorScreen(template: template, ref: ref),
        ),
      ),
    );
  }
}

class _TemplateEditorScreen extends StatefulWidget {
  final PdfTemplate? template;
  final WidgetRef ref;
  const _TemplateEditorScreen({this.template, required this.ref});

  @override
  State<_TemplateEditorScreen> createState() => _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends State<_TemplateEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.template?.name ?? '');
  late final _html = TextEditingController(
    text: widget.template?.templateHtml ?? _defaultHtml,
  );
  late String _docType = widget.template?.documentType ?? 'sales_invoice';
  bool _saving = false;

  static const _defaultHtml = '''<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><style>
  body { font-family: sans-serif; font-size: 12px; margin: 20px; }
  h1 { color: #1565C0; }
  table { width: 100%; border-collapse: collapse; }
  th, td { border: 1px solid #ccc; padding: 6px 8px; }
  th { background: #E3F2FD; }
</style></head>
<body>
  <h1>{{ \$company_name }}</h1>
  <p>Document Type: {{ \$document_type }}</p>
  <!-- Add your custom layout here -->
</body>
</html>''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template == null ? 'New Template' : 'Edit Template'),
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(
                        labelText: 'Template Name',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _docType,
                      decoration: const InputDecoration(
                        labelText: 'Document Type',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: PdfTemplatesScreen._docTypes
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(t.replaceAll('_', ' ')),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _docType = v!),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'HTML Template',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: TextFormField(
                  controller: _html,
                  maxLines: null,
                  expands: true,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(8),
                  ),
                  validator: (v) => v!.isEmpty ? 'HTML required' : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final repo = widget.ref.read(pdfTemplateRepositoryProvider);
    try {
      final data = {
        'name': _name.text,
        'document_type': _docType,
        'template_html': _html.text,
      };
      if (widget.template == null) {
        await repo.create(data);
      } else {
        await repo.update(widget.template!.id, data);
      }
      widget.ref.invalidate(pdfTemplatesProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    setState(() => _saving = false);
  }

  @override
  void dispose() {
    _name.dispose();
    _html.dispose();
    super.dispose();
  }
}
