import '../../../core/api_client.dart';

class PaymentSummary {
  final int id;
  final String paymentNumber;
  final String paymentDate;
  final int vendorId;
  final String vendorName;
  final String paymentMode;
  final double amount;
  final double tdsAmount;
  final String status;

  const PaymentSummary({
    required this.id,
    required this.paymentNumber,
    required this.paymentDate,
    required this.vendorId,
    required this.vendorName,
    required this.paymentMode,
    required this.amount,
    required this.tdsAmount,
    required this.status,
  });

  factory PaymentSummary.fromJson(Map<String, dynamic> json) {
    final vendor = json['vendor'] as Map<String, dynamic>?;
    return PaymentSummary(
      id: json['id'] as int,
      paymentNumber: json['payment_number'] as String,
      paymentDate: json['payment_date'] as String,
      vendorId: json['vendor_id'] as int,
      vendorName: vendor?['name'] as String? ?? '',
      paymentMode: json['payment_mode'] as String? ?? 'bank_transfer',
      amount: _toDouble(json['amount']),
      tdsAmount: _toDouble(json['tds_amount']),
      status: json['status'] as String,
    );
  }

  static double _toDouble(dynamic v) =>
      v == null ? 0.0 : double.tryParse(v.toString()) ?? 0.0;
}

class PaymentListResult {
  final List<PaymentSummary> items;
  final int total;
  final int lastPage;

  const PaymentListResult({
    required this.items,
    required this.total,
    required this.lastPage,
  });
}

class PaymentRepository {
  final ApiClient _client;

  const PaymentRepository(this._client);

  Future<PaymentListResult> list({
    String? search,
    int? vendorId,
    String? status,
    String? paymentMode,
    String? fromDate,
    String? toDate,
    int page = 1,
  }) async {
    final params = <String, dynamic>{'page': page};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (vendorId != null) params['vendor_id'] = vendorId;
    if (status != null) params['status'] = status;
    if (paymentMode != null) params['payment_mode'] = paymentMode;
    if (fromDate != null) params['from_date'] = fromDate;
    if (toDate != null) params['to_date'] = toDate;

    final response = await _client.dio.get(
      '/api/v1/payments',
      queryParameters: params,
    );
    final data = response.data as Map<String, dynamic>;
    final meta = data['meta'] as Map<String, dynamic>;
    final items = (data['data'] as List)
        .map((e) => PaymentSummary.fromJson(e as Map<String, dynamic>))
        .toList();

    return PaymentListResult(
      items: items,
      total: _toInt(meta['total']),
      lastPage: _toInt(meta['last_page']),
    );
  }

  static int _toInt(dynamic v) =>
      v == null ? 0 : int.tryParse(v.toString()) ?? 0;

  Future<Map<String, dynamic>> show(int id) async {
    final response = await _client.dio.get('/api/v1/payments/$id');
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> store(Map<String, dynamic> payload) async {
    final response = await _client.dio.post('/api/v1/payments', data: payload);
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> update(
    int id,
    Map<String, dynamic> payload,
  ) async {
    payload['_method'] = 'PUT';
    final response = await _client.dio.post(
      '/api/v1/payments/$id',
      data: payload,
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<void> postPayment(int id) async {
    await _client.dio.post('/api/v1/payments/$id/post');
  }

  Future<void> cancel(int id, {String? reason}) async {
    await _client.dio.post(
      '/api/v1/payments/$id/cancel',
      data: {'reason': reason ?? ''},
    );
  }
}
