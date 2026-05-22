import '../../../core/api_client.dart';

/// Summary DTO for purchase invoice list.
class PurchaseInvoiceSummary {
  final int id;
  final String invoiceNumber;
  final String? vendorInvoiceNumber;
  final String invoiceDate;
  final int vendorId;
  final String vendorName;
  final double totalAmount;
  final double balanceAmount;
  final String status;

  const PurchaseInvoiceSummary({
    required this.id,
    required this.invoiceNumber,
    this.vendorInvoiceNumber,
    required this.invoiceDate,
    required this.vendorId,
    required this.vendorName,
    required this.totalAmount,
    required this.balanceAmount,
    required this.status,
  });

  factory PurchaseInvoiceSummary.fromJson(Map<String, dynamic> json) {
    final vendor = json['vendor'] as Map<String, dynamic>?;
    return PurchaseInvoiceSummary(
      id: json['id'] as int,
      invoiceNumber: json['invoice_number'] as String,
      vendorInvoiceNumber: json['vendor_invoice_number'] as String?,
      invoiceDate: json['invoice_date'] as String,
      vendorId: json['vendor_id'] as int,
      vendorName: vendor?['name'] as String? ?? '',
      totalAmount: _toDouble(json['total_amount']),
      balanceAmount: _toDouble(json['balance_amount']),
      status: json['status'] as String,
    );
  }

  static double _toDouble(dynamic v) =>
      v == null ? 0.0 : double.tryParse(v.toString()) ?? 0.0;
}

class PurchaseInvoiceListResult {
  final List<PurchaseInvoiceSummary> items;
  final int total;
  final int lastPage;

  const PurchaseInvoiceListResult({
    required this.items,
    required this.total,
    required this.lastPage,
  });
}

/// Repository for purchase invoice API calls.
class PurchaseInvoiceRepository {
  final ApiClient _client;

  const PurchaseInvoiceRepository(this._client);

  Future<PurchaseInvoiceListResult> list({
    String? search,
    int? vendorId,
    String? status,
    String? fromDate,
    String? toDate,
    int page = 1,
  }) async {
    final params = <String, dynamic>{'page': page};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (vendorId != null) params['vendor_id'] = vendorId;
    if (status != null) params['status'] = status;
    if (fromDate != null) params['from_date'] = fromDate;
    if (toDate != null) params['to_date'] = toDate;

    final response = await _client.dio.get(
      '/purchase-invoices',
      queryParameters: params,
    );
    final data = response.data as Map<String, dynamic>;
    final meta = data['meta'] as Map<String, dynamic>;
    final items = (data['data'] as List)
        .map((e) => PurchaseInvoiceSummary.fromJson(e as Map<String, dynamic>))
        .toList();

    return PurchaseInvoiceListResult(
      items: items,
      total: meta['total'] as int,
      lastPage: meta['last_page'] as int,
    );
  }

  Future<Map<String, dynamic>> show(int id) async {
    final response = await _client.dio.get('/api/v1/purchase-invoices/$id');
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> store(Map<String, dynamic> payload) async {
    final response = await _client.dio.post(
      '/purchase-invoices',
      data: payload,
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> update(
    int id,
    Map<String, dynamic> payload,
  ) async {
    payload['_method'] = 'PUT';
    final response = await _client.dio.post(
      '/api/v1/purchase-invoices/$id',
      data: payload,
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<void> postInvoice(int id) async {
    await _client.dio.post('/api/v1/purchase-invoices/$id/post');
  }

  Future<void> cancel(int id, {String? reason}) async {
    await _client.dio.post(
      '/purchase-invoices/$id/cancel',
      data: {'reason': reason ?? ''},
    );
  }
}
