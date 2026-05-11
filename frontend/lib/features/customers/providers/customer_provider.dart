import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class CustomerSummary {
  final int id;
  final String name;
  final String? code;
  final String? gstin;
  final String? gstType;
  final String? phone;
  final String? billingState;

  const CustomerSummary({
    required this.id,
    required this.name,
    this.code,
    this.gstin,
    this.gstType,
    this.phone,
    this.billingState,
  });

  factory CustomerSummary.fromJson(Map<String, dynamic> j) => CustomerSummary(
    id: j['id'] as int,
    name: j['name'] as String,
    code: j['code'] as String?,
    gstin: j['gstin'] as String?,
    gstType: j['gst_type'] as String?,
    phone: j['phone'] as String?,
    billingState: j['billing_state'] as String?,
  );
}

// ── Repository ───────────────────────────────────────────────────────────────

class CustomerRepository {
  final ApiClient _client;
  CustomerRepository(this._client);

  Future<Map<String, dynamic>> list({
    int page = 1,
    int perPage = 20,
    String? search,
  }) async {
    final res = await _client.dio.get(
      '/api/v1/customers',
      queryParameters: {
        'page': page,
        'per_page': perPage,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> get(int id) async {
    final res = await _client.dio.get('/api/v1/customers/$id');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final res = await _client.dio.post('/api/v1/customers', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> update(int id, Map<String, dynamic> data) async {
    final res = await _client.dio.put('/api/v1/customers/$id', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<void> delete(int id) async {
    await _client.dio.delete('/api/v1/customers/$id');
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository(ref.watch(apiClientProvider));
});

// ── List State ────────────────────────────────────────────────────────────────

class CustomerListState {
  final List<CustomerSummary> items;
  final int total;
  final int lastPage;
  final int currentPage;
  final bool isLoading;
  final String? error;
  final String searchQuery;

  const CustomerListState({
    this.items = const [],
    this.total = 0,
    this.lastPage = 1,
    this.currentPage = 1,
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
  });

  CustomerListState copyWith({
    List<CustomerSummary>? items,
    int? total,
    int? lastPage,
    int? currentPage,
    bool? isLoading,
    String? error,
    String? searchQuery,
    bool clearError = false,
  }) => CustomerListState(
    items: items ?? this.items,
    total: total ?? this.total,
    lastPage: lastPage ?? this.lastPage,
    currentPage: currentPage ?? this.currentPage,
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : error ?? this.error,
    searchQuery: searchQuery ?? this.searchQuery,
  );
}

class CustomerListNotifier extends StateNotifier<CustomerListState> {
  final CustomerRepository _repo;
  CustomerListNotifier(this._repo) : super(const CustomerListState());

  Future<void> load({int page = 1, String? search}) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      searchQuery: search ?? state.searchQuery,
    );
    try {
      final res = await _repo.list(
        page: page,
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
      );
      final data = res['data'] as List<dynamic>;
      final meta = res['meta'] as Map<String, dynamic>;
      final items = data
          .map((d) => CustomerSummary.fromJson(d as Map<String, dynamic>))
          .toList();
      state = state.copyWith(
        isLoading: false,
        items: items,
        total: meta['total'] as int? ?? items.length,
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

  Future<void> delete(int id) async {
    await _repo.delete(id);
    await load(page: state.currentPage);
  }
}

final customerListProvider =
    StateNotifierProvider<CustomerListNotifier, CustomerListState>((ref) {
      return CustomerListNotifier(ref.watch(customerRepositoryProvider));
    });
