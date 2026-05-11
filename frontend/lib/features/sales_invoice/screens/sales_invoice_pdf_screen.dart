import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/invoice_list_provider.dart';
import '../../../shared/widgets/app_scaffold.dart';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html
    if (dart.library.io) 'package:hexbase_retail/core/stub/html_stub.dart';

/// Downloads the invoice PDF and either:
///  - (web) triggers browser file download
///  - (mobile/desktop) saves to temp dir and opens with native viewer
class SalesInvoicePdfScreen extends ConsumerStatefulWidget {
  final int invoiceId;
  const SalesInvoicePdfScreen({super.key, required this.invoiceId});

  @override
  ConsumerState<SalesInvoicePdfScreen> createState() =>
      _SalesInvoicePdfScreenState();
}

class _SalesInvoicePdfScreenState
    extends ConsumerState<SalesInvoicePdfScreen> {
  bool _loading = true;
  String? _error;
  String? _savedPath;

  @override
  void initState() {
    super.initState();
    _download();
  }

  Future<void> _download() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = ref.read(salesInvoiceRepositoryProvider);
      final bytes = await repo.downloadPdf(widget.invoiceId);
      final filename = 'INV-${widget.invoiceId}.pdf';

      if (kIsWeb) {
        // Trigger browser download via Blob URL
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.document.createElement('a') as html.AnchorElement
          ..href = url
          ..download = filename;
        html.document.body!.append(anchor);
        anchor.click();
        anchor.remove();
        html.Url.revokeObjectUrl(url);

        setState(() {
          _loading = false;
          _savedPath = 'Browser download triggered';
        });
      } else {
        // Save to system temp directory
        final tempDir = Directory.systemTemp;
        final file = File('${tempDir.path}${Platform.pathSeparator}$filename');
        await file.writeAsBytes(bytes);
        setState(() {
          _loading = false;
          _savedPath = file.path;
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Invoice PDF'),
          leading: BackButton(onPressed: () => context.go('/invoices')),
          actions: [
            if (!_loading && _error == null)
              IconButton(
                icon: const Icon(Icons.download),
                tooltip: 'Download again',
                onPressed: _download,
              ),
          ],
        ),
        body: Center(
          child: _loading
              ? _LoadingView()
              : _error != null
                  ? _ErrorView(error: _error!, onRetry: _download)
                  : _SuccessView(
                      path: _savedPath!,
                      isWeb: kIsWeb,
                    ),
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text('Generating PDF…',
            style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 8),
        Text(
          'This may take a few seconds.',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, size: 64, color: Colors.red),
        const SizedBox(height: 16),
        Text('Failed to generate PDF',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SelectableText(error,
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ],
    );
  }
}

class _SuccessView extends StatelessWidget {
  final String path;
  final bool isWeb;
  const _SuccessView({required this.path, required this.isWeb});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
        const SizedBox(height: 16),
        Text(
          isWeb ? 'PDF downloaded to browser' : 'PDF saved successfully',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (!isWeb)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: SelectableText(
              path,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => context.go('/invoices'),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back to Invoices'),
        ),
      ],
    );
  }
}
