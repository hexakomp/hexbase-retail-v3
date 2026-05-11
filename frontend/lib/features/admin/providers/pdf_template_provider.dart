import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';

class PdfTemplate {
  final int id;
  final String name;
  final String documentType;
  final String templateHtml;
  final bool isDefault;

  const PdfTemplate({
    required this.id,
    required this.name,
    required this.documentType,
    required this.templateHtml,
    required this.isDefault,
  });

  factory PdfTemplate.fromJson(Map<String, dynamic> j) => PdfTemplate(
    id: j['id'],
    name: j['name'] ?? '',
    documentType: j['document_type'] ?? '',
    templateHtml: j['template_html'] ?? '',
    isDefault: j['is_default'] == true,
  );
}

class PdfTemplateRepository {
  final ApiClient _client;
  PdfTemplateRepository(this._client);

  Future<List<PdfTemplate>> list({String? documentType}) async {
    final res = await _client.dio.get(
      '/admin/pdf-templates',
      queryParameters: {
        if (documentType != null) 'document_type': documentType,
      },
    );
    return (res.data['data'] as List)
        .map((j) => PdfTemplate.fromJson(j))
        .toList();
  }

  Future<PdfTemplate> create(Map<String, dynamic> data) async {
    final res = await _client.dio.post('/api/v1/admin/pdf-templates', data: data);
    return PdfTemplate.fromJson(res.data['data']);
  }

  Future<PdfTemplate> update(int id, Map<String, dynamic> data) async {
    final res = await _client.dio.put('/api/v1/admin/pdf-templates/$id', data: data);
    return PdfTemplate.fromJson(res.data['data']);
  }

  Future<void> delete(int id) async =>
      await _client.dio.delete('/api/v1/admin/pdf-templates/$id');

  Future<void> setDefault(int id) async =>
      await _client.dio.patch('/admin/pdf-templates/$id/set-default');
}

final pdfTemplateRepositoryProvider = Provider(
  (ref) => PdfTemplateRepository(ref.read(apiClientProvider)),
);

final pdfTemplatesProvider = FutureProvider.autoDispose<List<PdfTemplate>>(
  (ref) => ref.read(pdfTemplateRepositoryProvider).list(),
);
