import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';

class VendorSummary {
  final int id;
  final String name;
  final String? code;
  final String? gstin;
  final String? gstType;
  final String? phone;
  final String? state;

  const VendorSummary({
    required this.id,
    required this.name,
    this.code,
    this.gstin,
    this.gstType,
    this.phone,
    this.state,
  });

  factory VendorSummary.fromJson(Map<String, dynamic> j) => VendorSummary(
    id: j['id'] as int,
    name: j['name'] as String,
    code: j['code'] as String?,
    gstin: j['gstin'] as String?,
    gstType: j['gst_type'] as String?,
    phone: j['phone'] as String?,
    state: j['state'] as String?,
  );
}

class VendorRepository {
  final ApiClient _client;
  VendorRepository(this._client);

  Future<Map<String, dynamic>> list({
    int page = 1,
    int perPage = 20,
    String? search,
  }) async {
    final res = await _client.dio.get(
      '/api/v1/vendors',
      queryParameters: {
        'page': page,
        'per_page': perPage,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> get(int id) async {
    final res = await _client.dio.get('/api/v1/vendors/$id');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final res = await _client.dio.post('/api/v1/vendors', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> update(int id, Map<String, dynamic> data) async {
    final res = await _client.dio.put('/api/v1/vendors/$id', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<void> delete(int id) async =>
      _client.dio.delete('/api/v1/vendors/$id');
}

final vendorRepositoryProvider = Provider<VendorRepository>(
  (ref) => VendorRepository(ref.watch(apiClientProvider)),
);

class VendorListState {
  final List<VendorSummary> items;
  final int total;
  final int lastPage;
  final int currentPage;
  final bool isLoading;
  final String? error;
  final String searchQuery;

  const VendorListState({
    this.items = const [],
    this.total = 0,
    this.lastPage = 1,
    this.currentPage = 1,
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
  });

  VendorListState copyWith({
    List<VendorSummary>? items,
    int? total,
    int? lastPage,
    int? currentPage,
    bool? isLoading,
    String? error,
    String? searchQuery,
    bool clearError = false,
  }) => VendorListState(
    items: items ?? this.items,
    total: total ?? this.total,
    lastPage: lastPage ?? this.lastPage,
    currentPage: currentPage ?? this.currentPage,
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : error ?? this.error,
    searchQuery: searchQuery ?? this.searchQuery,
  );
}

class VendorListNotifier extends StateNotifier<VendorListState> {
  final VendorRepository _repo;
  VendorListNotifier(this._repo) : super(const VendorListState());

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
      state = state.copyWith(
        isLoading: false,
        items: data
            .map((d) => VendorSummary.fromJson(d as Map<String, dynamic>))
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

  Future<void> delete(int id) async {
    await _repo.delete(id);
    await load(page: state.currentPage);
  }
}

final vendorListProvider =
    StateNotifierProvider<VendorListNotifier, VendorListState>((ref) {
      return VendorListNotifier(ref.watch(vendorRepositoryProvider));
    });
