import 'package:dio/dio.dart';
import '../../../core/api_client.dart';

/// Data transfer object for a sales invoice list item.
class SalesInvoiceSummary {
  final int id;
  final String invoiceNumber;
  final String invoiceDate;
  final String? dueDate;
  final int customerId;
  final String customerName;
  final double totalAmount;
  final double balanceAmount;
  final String status;

  const SalesInvoiceSummary({
    required this.id,
    required this.invoiceNumber,
    required this.invoiceDate,
    this.dueDate,
    required this.customerId,
    required this.customerName,
    required this.totalAmount,
    required this.balanceAmount,
    required this.status,
  });

  factory SalesInvoiceSummary.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>?;
    return SalesInvoiceSummary(
      id: json['id'] as int,
      invoiceNumber: json['invoice_number'] as String,
      invoiceDate: json['invoice_date'] as String,
      dueDate: json['due_date'] as String?,
      customerId: json['customer_id'] as int,
      customerName: customer?['name'] as String? ?? '',
      totalAmount: _toDouble(json['total_amount']),
      balanceAmount: _toDouble(json['balance_amount']),
      status: json['status'] as String,
    );
  }

  static double _toDouble(dynamic v) =>
      v == null ? 0.0 : double.tryParse(v.toString()) ?? 0.0;
}

/// Full invoice detail model.
class SalesInvoiceDetail {
  final int id;
  final String invoiceNumber;
  final String invoiceDate;
  final String? dueDate;
  final String supplyType;
  final String invoiceType;
  final String placeOfSupply;
  final String? customerGstin;
  final int customerId;
  final String customerName;
  final double subtotal;
  final double discountAmount;
  final double taxableAmount;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double cessAmount;
  final double roundOff;
  final double totalAmount;
  final double paidAmount;
  final double balanceAmount;
  final String status;
  final String? narration;
  final String? notes;
  final String? internalNotes;
  final String? paymentTerms;
  final String customerBillingAddress;
  final String customerBillingCity;
  final String customerBillingState;
  final String customerBillingPincode;
  final String customerShippingAddress;
  final String customerPhone;
  final List<SalesInvoiceLineDetail> lines;

  const SalesInvoiceDetail({
    required this.id,
    required this.invoiceNumber,
    required this.invoiceDate,
    this.dueDate,
    required this.supplyType,
    required this.invoiceType,
    required this.placeOfSupply,
    this.customerGstin,
    required this.customerId,
    required this.customerName,
    required this.subtotal,
    required this.discountAmount,
    required this.taxableAmount,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.igstAmount,
    required this.cessAmount,
    required this.roundOff,
    required this.totalAmount,
    required this.paidAmount,
    required this.balanceAmount,
    required this.status,
    this.narration,
    this.notes,
    this.internalNotes,
    this.paymentTerms,
    this.customerBillingAddress = '',
    this.customerBillingCity = '',
    this.customerBillingState = '',
    this.customerBillingPincode = '',
    this.customerShippingAddress = '',
    this.customerPhone = '',
    required this.lines,
  });

  factory SalesInvoiceDetail.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>?;
    final linesJson = (json['lines'] as List<dynamic>?) ?? [];
    return SalesInvoiceDetail(
      id: json['id'] as int,
      invoiceNumber: json['invoice_number'] as String,
      invoiceDate: json['invoice_date'] as String,
      dueDate: json['due_date'] as String?,
      supplyType: json['supply_type'] as String? ?? 'intra',
      invoiceType: json['invoice_type'] as String? ?? 'b2b',
      placeOfSupply: json['place_of_supply'] as String? ?? '',
      customerGstin: json['customer_gstin'] as String?,
      customerId: json['customer_id'] as int,
      customerName: customer?['name'] as String? ?? '',
      subtotal: _d(json['subtotal']),
      discountAmount: _d(json['discount_amount']),
      taxableAmount: _d(json['taxable_amount']),
      cgstAmount: _d(json['cgst_amount']),
      sgstAmount: _d(json['sgst_amount']),
      igstAmount: _d(json['igst_amount']),
      cessAmount: _d(json['cess_amount']),
      roundOff: _d(json['round_off']),
      totalAmount: _d(json['total_amount']),
      paidAmount: _d(json['paid_amount']),
      balanceAmount: _d(json['balance_amount']),
      status: json['status'] as String,
      narration: json['narration'] as String?,
      notes: json['notes'] as String?,
      internalNotes: json['internal_notes'] as String?,
      paymentTerms: json['payment_terms'] as String?,
      customerBillingAddress:
          json['customer_billing_address'] as String? ??
          customer?['billing_address'] as String? ??
          '',
      customerBillingCity: customer?['billing_city'] as String? ?? '',
      customerBillingState: customer?['billing_state'] as String? ?? '',
      customerBillingPincode:
          json['customer_pincode'] as String? ??
          customer?['billing_pincode'] as String? ??
          '',
      customerShippingAddress: customer?['shipping_address'] as String? ?? '',
      customerPhone:
          json['customer_phone'] as String? ??
          customer?['phone'] as String? ??
          '',
      lines: linesJson
          .map(
            (l) => SalesInvoiceLineDetail.fromJson(l as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  static double _d(dynamic v) =>
      v == null ? 0.0 : double.tryParse(v.toString()) ?? 0.0;
}

class SalesInvoiceLineDetail {
  final int id;
  final int productId;
  final String? productName;
  final String? description;
  final String? hsnSac;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double discountPct;
  final double taxableAmount;
  final double gstRate;
  final double cgstRate;
  final double cgstAmount;
  final double sgstRate;
  final double sgstAmount;
  final double igstRate;
  final double igstAmount;
  final double lineTotal;

  const SalesInvoiceLineDetail({
    required this.id,
    required this.productId,
    this.productName,
    this.description,
    this.hsnSac,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.discountPct,
    required this.taxableAmount,
    required this.gstRate,
    required this.cgstRate,
    required this.cgstAmount,
    required this.sgstRate,
    required this.sgstAmount,
    required this.igstRate,
    required this.igstAmount,
    required this.lineTotal,
  });

  factory SalesInvoiceLineDetail.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    return SalesInvoiceLineDetail(
      id: json['id'] as int,
      productId: json['product_id'] as int,
      productName: product?['name'] as String?,
      description: json['description'] as String?,
      hsnSac: json['hsn_sac'] as String?,
      quantity: _d(json['quantity']),
      unit: json['unit'] as String? ?? 'PCS',
      unitPrice: _d(json['unit_price']),
      discountPct: _d(json['discount_pct']),
      taxableAmount: _d(json['taxable_amount']),
      gstRate: _d(json['gst_rate']),
      cgstRate: _d(json['cgst_rate']),
      cgstAmount: _d(json['cgst_amount']),
      sgstRate: _d(json['sgst_rate']),
      sgstAmount: _d(json['sgst_amount']),
      igstRate: _d(json['igst_rate']),
      igstAmount: _d(json['igst_amount']),
      lineTotal: _d(json['line_total']),
    );
  }

  static double _d(dynamic v) =>
      v == null ? 0.0 : double.tryParse(v.toString()) ?? 0.0;
}

/// Repository: wraps all Dio calls for the sales-invoice module.
class SalesInvoiceRepository {
  final ApiClient _client;

  SalesInvoiceRepository(this._client);

  Future<({List<SalesInvoiceSummary> items, int total, int lastPage})> list({
    String? search,
    String? status,
    int? customerId,
    String? fromDate,
    String? toDate,
    int page = 1,
  }) async {
    final response = await _client.dio.get(
      '/api/v1/invoices',
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null) 'status': status,
        if (customerId != null) 'customer_id': customerId,
        if (fromDate != null) 'from_date': fromDate,
        if (toDate != null) 'to_date': toDate,
        'page': page,
      },
    );

    final data = response.data as Map<String, dynamic>;
    final meta = data['meta'] as Map<String, dynamic>;
    final items = (data['data'] as List<dynamic>)
        .map((j) => SalesInvoiceSummary.fromJson(j as Map<String, dynamic>))
        .toList();

    return (
      items: items,
      total: meta['total'] as int,
      lastPage: meta['last_page'] as int,
    );
  }

  Future<SalesInvoiceDetail> show(int id) async {
    final response = await _client.dio.get('/api/v1/invoices/$id');
    return SalesInvoiceDetail.fromJson(
      (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>,
    );
  }

  Future<SalesInvoiceDetail> store(Map<String, dynamic> payload) async {
    final response = await _client.dio.post('/api/v1/invoices', data: payload);
    return SalesInvoiceDetail.fromJson(
      (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>,
    );
  }

  Future<SalesInvoiceDetail> update(
    int id,
    Map<String, dynamic> payload,
  ) async {
    payload['_method'] = 'PUT';
    final response = await _client.dio.post(
      '/api/v1/invoices/$id',
      data: payload,
    );
    return SalesInvoiceDetail.fromJson(
      (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>,
    );
  }

  Future<Map<String, dynamic>> calculate(Map<String, dynamic> payload) async {
    final response = await _client.dio.post(
      '/api/v1/invoices/calculate',
      data: payload,
    );
    return (response.data as Map<String, dynamic>)['data']
        as Map<String, dynamic>;
  }

  Future<SalesInvoiceDetail> post(int id) async {
    final response = await _client.dio.post('/api/v1/invoices/$id/post');
    return SalesInvoiceDetail.fromJson(
      (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>,
    );
  }

  Future<SalesInvoiceDetail> cancel(int id, String reason) async {
    final response = await _client.dio.post(
      '/api/v1/invoices/$id/cancel',
      data: {'reason': reason},
    );
    return SalesInvoiceDetail.fromJson(
      (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>,
    );
  }

  /// Returns PDF bytes.
  Future<List<int>> downloadPdf(int id) async {
    final response = await _client.dio.get<List<int>>(
      '/api/v1/invoices/$id/pdf',
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data ?? [];
  }
}
