import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';

class DeliveryChallanSummary {
  final int id;
  final String dcNumber;
  final String dcDate;
  final int customerId;
  final String customerName;
  final double totalAmount;
  final String status;

  const DeliveryChallanSummary({
    required this.id,
    required this.dcNumber,
    required this.dcDate,
    required this.customerId,
    required this.customerName,
    required this.totalAmount,
    required this.status,
  });

  factory DeliveryChallanSummary.fromJson(Map<String, dynamic> j) {
    final customer = (j['customer'] as Map<String, dynamic>?) ?? {};
    return DeliveryChallanSummary(
      id: j['id'] as int,
      dcNumber: j['dc_number'] as String,
      dcDate: j['dc_date'] as String,
      customerId: j['customer_id'] as int,
      customerName: customer['name'] as String? ?? '',
      totalAmount: (j['total_amount'] as num).toDouble(),
      status: j['status'] as String,
    );
  }
}

class DeliveryChallanRepository {
  final ApiClient _client;
  DeliveryChallanRepository(this._client);

  Future<Map<String, dynamic>> list({
    int page = 1,
    String? search,
    String? status,
  }) async {
    final res = await _client.dio.get(
      '/api/v1/delivery-challans',
      queryParameters: {
        'page': page,
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null) 'status': status,
      },
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> get(int id) async {
    final res = await _client.dio.get('/api/v1/delivery-challans/$id');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final res = await _client.dio.post('/api/v1/delivery-challans', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> update(int id, Map<String, dynamic> data) async {
    final res = await _client.dio.put(
      '/api/v1/delivery-challans/$id',
      data: data,
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> dispatch(int id) async {
    final res = await _client.dio.post(
      '/api/v1/delivery-challans/$id/dispatch',
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> cancel(int id) async {
    final res = await _client.dio.post('/api/v1/delivery-challans/$id/cancel');
    return res.data as Map<String, dynamic>;
  }

  String pdfUrl(int id) =>
      '${_client.dio.options.baseUrl}/api/v1/delivery-challans/$id/pdf';
}

class DeliveryChallanListState {
  final List<DeliveryChallanSummary> items;
  final bool isLoading;
  final String? error;

  const DeliveryChallanListState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  DeliveryChallanListState copyWith({
    List<DeliveryChallanSummary>? items,
    bool? isLoading,
    String? error,
  }) {
    return DeliveryChallanListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class DeliveryChallanListNotifier
    extends StateNotifier<DeliveryChallanListState> {
  final DeliveryChallanRepository _repo;

  DeliveryChallanListNotifier(this._repo)
    : super(const DeliveryChallanListState()) {
    load();
  }

  Future<void> load({String? search}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repo.list(search: search);
      final items = (data['data'] as List<dynamic>)
          .map(
            (e) => DeliveryChallanSummary.fromJson(e as Map<String, dynamic>),
          )
          .toList();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => load();
}

final deliveryChallanRepositoryProvider = Provider<DeliveryChallanRepository>((
  ref,
) {
  return DeliveryChallanRepository(ref.read(apiClientProvider));
});

final deliveryChallanListProvider =
    StateNotifierProvider<
      DeliveryChallanListNotifier,
      DeliveryChallanListState
    >((ref) {
      return DeliveryChallanListNotifier(
        ref.read(deliveryChallanRepositoryProvider),
      );
    });
