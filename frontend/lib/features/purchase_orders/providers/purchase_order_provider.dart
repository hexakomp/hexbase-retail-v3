import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';

class PurchaseOrderSummary {
  final int id;
  final String poNumber;
  final String poDate;
  final int vendorId;
  final String vendorName;
  final double totalAmount;
  final String status;

  const PurchaseOrderSummary({
    required this.id,
    required this.poNumber,
    required this.poDate,
    required this.vendorId,
    required this.vendorName,
    required this.totalAmount,
    required this.status,
  });

  factory PurchaseOrderSummary.fromJson(Map<String, dynamic> j) {
    final vendor = (j['vendor'] as Map<String, dynamic>?) ?? {};
    return PurchaseOrderSummary(
      id: j['id'] as int,
      poNumber: j['po_number'] as String,
      poDate: j['po_date'] as String,
      vendorId: j['vendor_id'] as int,
      vendorName: vendor['name'] as String? ?? '',
      totalAmount: (j['total_amount'] as num).toDouble(),
      status: j['status'] as String,
    );
  }
}

class PurchaseOrderRepository {
  final ApiClient _client;
  PurchaseOrderRepository(this._client);

  Future<Map<String, dynamic>> list({
    int page = 1,
    String? search,
    String? status,
  }) async {
    final res = await _client.dio.get(
      '/api/v1/purchase-orders',
      queryParameters: {
        'page': page,
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null) 'status': status,
      },
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> get(int id) async {
    final res = await _client.dio.get('/api/v1/purchase-orders/$id');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final res = await _client.dio.post('/api/v1/purchase-orders', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> update(int id, Map<String, dynamic> data) async {
    final res = await _client.dio.put(
      '/api/v1/purchase-orders/$id',
      data: data,
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> cancel(int id) async {
    final res = await _client.dio.post('/api/v1/purchase-orders/$id/cancel');
    return res.data as Map<String, dynamic>;
  }

  String pdfUrl(int id) =>
      '${_client.dio.options.baseUrl}/api/v1/purchase-orders/$id/pdf';
}

class PurchaseOrderListState {
  final List<PurchaseOrderSummary> items;
  final bool isLoading;
  final String? error;

  const PurchaseOrderListState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  PurchaseOrderListState copyWith({
    List<PurchaseOrderSummary>? items,
    bool? isLoading,
    String? error,
  }) {
    return PurchaseOrderListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class PurchaseOrderListNotifier extends StateNotifier<PurchaseOrderListState> {
  final PurchaseOrderRepository _repo;

  PurchaseOrderListNotifier(this._repo)
    : super(const PurchaseOrderListState()) {
    load();
  }

  Future<void> load({String? search}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repo.list(search: search);
      final items = (data['data'] as List<dynamic>)
          .map((e) => PurchaseOrderSummary.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => load();
}

final purchaseOrderRepositoryProvider = Provider<PurchaseOrderRepository>((
  ref,
) {
  return PurchaseOrderRepository(ref.read(apiClientProvider));
});

final purchaseOrderListProvider =
    StateNotifierProvider<PurchaseOrderListNotifier, PurchaseOrderListState>((
      ref,
    ) {
      return PurchaseOrderListNotifier(
        ref.read(purchaseOrderRepositoryProvider),
      );
    });
