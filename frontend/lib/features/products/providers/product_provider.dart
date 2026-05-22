import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';

class ProductSummary {
  final int id;
  final String name;
  final String? description;
  final String? code;
  final String? sku;
  final String? hsn;
  final String? type;
  final String? unit;
  final double? salePrice;
  final double? purchasePrice;
  final double? mrp;
  final double? currentStock;
  final int gstRate;
  final int cessRate;
  final bool trackInventory;
  final double? openingStock;
  final bool isActive;

  const ProductSummary({
    required this.id,
    required this.name,
    this.description,
    this.code,
    this.sku,
    this.hsn,
    this.type,
    this.unit,
    this.salePrice,
    this.purchasePrice,
    this.mrp,
    this.currentStock,
    this.gstRate = 0,
    this.cessRate = 0,
    this.trackInventory = true,
    this.openingStock,
    this.isActive = true,
  });

  factory ProductSummary.fromJson(Map<String, dynamic> j) => ProductSummary(
    id: j['id'] as int,
    name: j['name'] as String,
    description: j['description'] as String?,
    code: j['code'] as String?,
    sku: j['sku'] as String?,
    hsn: j['hsn_sac'] as String?,
    type: j['type'] as String?,
    unit: j['unit'] as String?,
    salePrice: j['sale_price'] != null
        ? double.tryParse(j['sale_price'].toString())
        : null,
    purchasePrice: j['purchase_price'] != null
        ? double.tryParse(j['purchase_price'].toString())
        : null,
    mrp: j['mrp'] != null ? double.tryParse(j['mrp'].toString()) : null,
    currentStock: j['current_stock'] != null
        ? double.tryParse(j['current_stock'].toString())
        : null,
    gstRate: int.tryParse(j['gst_rate']?.toString() ?? '') ?? 0,
    cessRate: int.tryParse(j['cess_rate']?.toString() ?? '') ?? 0,
    trackInventory:
        j['track_inventory'] == true ||
        j['track_inventory'] == 1 ||
        j['track_inventory'] == '1',
    openingStock: j['opening_stock'] != null
        ? double.tryParse(j['opening_stock'].toString())
        : null,
    isActive:
        j['is_active'] == true || j['is_active'] == 1 || j['is_active'] == '1',
  );
}

class ProductRepository {
  final ApiClient _client;
  ProductRepository(this._client);

  Future<Map<String, dynamic>> list({
    int page = 1,
    int perPage = 20,
    String? search,
  }) async {
    final res = await _client.dio.get(
      '/api/v1/products',
      queryParameters: {
        'page': page,
        'per_page': perPage,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> get(int id) async {
    final res = await _client.dio.get('/api/v1/products/$id');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final res = await _client.dio.post('/api/v1/products', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> update(int id, Map<String, dynamic> data) async {
    final res = await _client.dio.put('/api/v1/products/$id', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> stockSummary(int id) async {
    final res = await _client.dio.get('/api/v1/products/$id/stock-summary');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> movements(int id, {int page = 1}) async {
    final res = await _client.dio.get(
      '/api/v1/products/$id/movements',
      queryParameters: {'page': page},
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> stockAdjustment(
    int id,
    Map<String, dynamic> data,
  ) async {
    final res = await _client.dio.post(
      '/api/v1/products/$id/stock-adjustment',
      data: data,
    );
    return res.data as Map<String, dynamic>;
  }
}

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => ProductRepository(ref.watch(apiClientProvider)),
);

// ── List State ────────────────────────────────────────────────────────────────

class ProductListState {
  final List<ProductSummary> items;
  final int total;
  final int lastPage;
  final int currentPage;
  final bool isLoading;
  final String? error;
  final String searchQuery;

  const ProductListState({
    this.items = const [],
    this.total = 0,
    this.lastPage = 1,
    this.currentPage = 1,
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
  });

  ProductListState copyWith({
    List<ProductSummary>? items,
    int? total,
    int? lastPage,
    int? currentPage,
    bool? isLoading,
    String? error,
    String? searchQuery,
    bool clearError = false,
  }) => ProductListState(
    items: items ?? this.items,
    total: total ?? this.total,
    lastPage: lastPage ?? this.lastPage,
    currentPage: currentPage ?? this.currentPage,
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : error ?? this.error,
    searchQuery: searchQuery ?? this.searchQuery,
  );
}

class ProductListNotifier extends StateNotifier<ProductListState> {
  final ProductRepository _repo;
  ProductListNotifier(this._repo) : super(const ProductListState());

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
            .map((d) => ProductSummary.fromJson(d as Map<String, dynamic>))
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
}

final productListProvider =
    StateNotifierProvider<ProductListNotifier, ProductListState>((ref) {
      return ProductListNotifier(ref.watch(productRepositoryProvider));
    });
