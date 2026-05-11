import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';

class QuotationSummary {
  final int id;
  final String quotationNo;
  final String? customerName;
  final String status;
  final double totalAmount;
  final String? validUntil;
  final bool isExpired;

  const QuotationSummary({
    required this.id,
    required this.quotationNo,
    this.customerName,
    required this.status,
    required this.totalAmount,
    this.validUntil,
    this.isExpired = false,
  });

  factory QuotationSummary.fromJson(Map<String, dynamic> j) => QuotationSummary(
    id: j['id'] as int,
    quotationNo: j['quotation_no'] as String? ?? '',
    customerName: (j['customer'] as Map<String, dynamic>?)?['name'] as String?,
    status: j['status'] as String? ?? 'draft',
    totalAmount: (j['total_amount'] as num?)?.toDouble() ?? 0.0,
    validUntil: j['valid_until'] as String?,
    isExpired: j['is_expired'] == true,
  );
}

class QuotationRepository {
  final ApiClient _client;
  QuotationRepository(this._client);

  Future<Map<String, dynamic>> list({
    int page = 1,
    int perPage = 20,
    String? status,
    String? search,
  }) async {
    final res = await _client.dio.get(
      '/api/v1/quotations',
      queryParameters: {
        'page': page,
        'per_page': perPage,
        if (status != null) 'status': status,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> get(int id) async {
    final res = await _client.dio.get('/api/v1/quotations/$id');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final res = await _client.dio.post('/api/v1/quotations', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> update(int id, Map<String, dynamic> data) async {
    final res = await _client.dio.put('/api/v1/quotations/$id', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<void> delete(int id) async =>
      _client.dio.delete('/api/v1/quotations/$id');

  Future<Map<String, dynamic>> post(int id) async {
    final res = await _client.dio.post('/api/v1/quotations/$id/post');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> convert(int id) async {
    final res = await _client.dio.post('/api/v1/quotations/$id/convert');
    return res.data as Map<String, dynamic>;
  }
}

final quotationRepositoryProvider = Provider<QuotationRepository>(
  (ref) => QuotationRepository(ref.watch(apiClientProvider)),
);

// ── List State ────────────────────────────────────────────────────────────────

class QuotationListState {
  final List<QuotationSummary> items;
  final int total;
  final int lastPage;
  final int currentPage;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final String? statusFilter;

  const QuotationListState({
    this.items = const [],
    this.total = 0,
    this.lastPage = 1,
    this.currentPage = 1,
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.statusFilter,
  });

  QuotationListState copyWith({
    List<QuotationSummary>? items,
    int? total,
    int? lastPage,
    int? currentPage,
    bool? isLoading,
    String? error,
    String? searchQuery,
    String? statusFilter,
    bool clearError = false,
    bool clearStatusFilter = false,
  }) => QuotationListState(
    items: items ?? this.items,
    total: total ?? this.total,
    lastPage: lastPage ?? this.lastPage,
    currentPage: currentPage ?? this.currentPage,
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : error ?? this.error,
    searchQuery: searchQuery ?? this.searchQuery,
    statusFilter: clearStatusFilter ? null : statusFilter ?? this.statusFilter,
  );
}

class QuotationListNotifier extends StateNotifier<QuotationListState> {
  final QuotationRepository _repo;
  QuotationListNotifier(this._repo) : super(const QuotationListState());

  Future<void> load({int page = 1, String? status, String? search}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _repo.list(
        page: page,
        status: status ?? state.statusFilter,
        search:
            search ?? (state.searchQuery.isEmpty ? null : state.searchQuery),
      );
      final data = res['data'] as List<dynamic>;
      final meta = res['meta'] as Map<String, dynamic>;
      state = state.copyWith(
        isLoading: false,
        items: data
            .map((d) => QuotationSummary.fromJson(d as Map<String, dynamic>))
            .toList(),
        total: meta['total'] as int? ?? 0,
        lastPage: meta['last_page'] as int? ?? 1,
        currentPage: meta['current_page'] as int? ?? page,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> search(String query) async {
    state = state.copyWith(searchQuery: query);
    await load(page: 1);
  }

  Future<void> setStatusFilter(String? status) async {
    state = status == null
        ? state.copyWith(clearStatusFilter: true)
        : state.copyWith(statusFilter: status);
    await load(page: 1);
  }
}

final quotationListProvider =
    StateNotifierProvider<QuotationListNotifier, QuotationListState>((ref) {
      return QuotationListNotifier(ref.watch(quotationRepositoryProvider));
    });
