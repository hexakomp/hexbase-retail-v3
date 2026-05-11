import '../../../core/api_client.dart';

class ReceiptSummary {
  final int id;
  final String receiptNumber;
  final String receiptDate;
  final int customerId;
  final String customerName;
  final String paymentMode;
  final double amount;
  final String status;

  const ReceiptSummary({
    required this.id,
    required this.receiptNumber,
    required this.receiptDate,
    required this.customerId,
    required this.customerName,
    required this.paymentMode,
    required this.amount,
    required this.status,
  });

  factory ReceiptSummary.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>?;
    return ReceiptSummary(
      id: json['id'] as int,
      receiptNumber: json['receipt_number'] as String,
      receiptDate: json['receipt_date'] as String,
      customerId: json['customer_id'] as int,
      customerName: customer?['name'] as String? ?? '',
      paymentMode: json['payment_mode'] as String? ?? 'cash',
      amount: _toDouble(json['amount']),
      status: json['status'] as String,
    );
  }

  static double _toDouble(dynamic v) =>
      v == null ? 0.0 : double.tryParse(v.toString()) ?? 0.0;
}

class ReceiptListResult {
  final List<ReceiptSummary> items;
  final int total;
  final int lastPage;

  const ReceiptListResult({
    required this.items,
    required this.total,
    required this.lastPage,
  });
}

class ReceiptRepository {
  final ApiClient _client;

  const ReceiptRepository(this._client);

  Future<ReceiptListResult> list({
    String? search,
    int? customerId,
    String? status,
    String? paymentMode,
    String? fromDate,
    String? toDate,
    int page = 1,
  }) async {
    final params = <String, dynamic>{'page': page};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (customerId != null) params['customer_id'] = customerId;
    if (status != null) params['status'] = status;
    if (paymentMode != null) params['payment_mode'] = paymentMode;
    if (fromDate != null) params['from_date'] = fromDate;
    if (toDate != null) params['to_date'] = toDate;

    final response = await _client.dio.get(
      '/api/v1/receipts',
      queryParameters: params,
    );
    final data = response.data as Map<String, dynamic>;
    final meta = data['meta'] as Map<String, dynamic>;
    final items = (data['data'] as List)
        .map((e) => ReceiptSummary.fromJson(e as Map<String, dynamic>))
        .toList();

    return ReceiptListResult(
      items: items,
      total: _toInt(meta['total']),
      lastPage: _toInt(meta['last_page']),
    );
  }

  static int _toInt(dynamic v) =>
      v == null ? 0 : int.tryParse(v.toString()) ?? 0;

  Future<Map<String, dynamic>> show(int id) async {
    final response = await _client.dio.get('/api/v1/receipts/$id');
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> store(Map<String, dynamic> payload) async {
    final response = await _client.dio.post('/api/v1/receipts', data: payload);
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> update(
    int id,
    Map<String, dynamic> payload,
  ) async {
    final response = await _client.dio.put(
      '/api/v1/receipts/$id',
      data: payload,
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<void> postReceipt(int id) async {
    await _client.dio.post('/api/v1/receipts/$id/post');
  }

  Future<void> cancel(int id, {String? reason}) async {
    await _client.dio.post(
      '/api/v1/receipts/$id/cancel',
      data: {'reason': reason ?? ''},
    );
  }
}
