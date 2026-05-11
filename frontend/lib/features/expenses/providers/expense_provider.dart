import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';

class ExpenseSummary {
  final int id;
  final String expenseNumber;
  final String expenseDate;
  final String category;
  final String description;
  final double totalAmount;
  final String status;

  const ExpenseSummary({
    required this.id,
    required this.expenseNumber,
    required this.expenseDate,
    required this.category,
    required this.description,
    required this.totalAmount,
    required this.status,
  });

  factory ExpenseSummary.fromJson(Map<String, dynamic> j) {
    return ExpenseSummary(
      id: j['id'] as int,
      expenseNumber: j['expense_number'] as String,
      expenseDate: j['expense_date'] as String,
      category: j['category'] as String,
      description: j['description'] as String,
      totalAmount: (j['total_amount'] as num).toDouble(),
      status: j['status'] as String,
    );
  }
}

class ExpenseRepository {
  final ApiClient _client;
  ExpenseRepository(this._client);

  Future<Map<String, dynamic>> list({
    int page = 1,
    String? search,
    String? status,
  }) async {
    final res = await _client.dio.get(
      '/api/v1/expenses',
      queryParameters: {
        'page': page,
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null) 'status': status,
      },
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> get(int id) async {
    final res = await _client.dio.get('/api/v1/expenses/$id');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final res = await _client.dio.post('/api/v1/expenses', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> post(int id) async {
    final res = await _client.dio.post('/api/v1/expenses/$id/post');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> cancel(int id) async {
    final res = await _client.dio.post('/api/v1/expenses/$id/cancel');
    return res.data as Map<String, dynamic>;
  }
}

class ExpenseListState {
  final List<ExpenseSummary> items;
  final bool isLoading;
  final String? error;

  const ExpenseListState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  ExpenseListState copyWith({
    List<ExpenseSummary>? items,
    bool? isLoading,
    String? error,
  }) {
    return ExpenseListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ExpenseListNotifier extends StateNotifier<ExpenseListState> {
  final ExpenseRepository _repo;

  ExpenseListNotifier(this._repo) : super(const ExpenseListState()) {
    load();
  }

  Future<void> load({String? search}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repo.list(search: search);
      final items = (data['data'] as List<dynamic>)
          .map((e) => ExpenseSummary.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => load();
}

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(ref.read(apiClientProvider));
});

final expenseListProvider =
    StateNotifierProvider<ExpenseListNotifier, ExpenseListState>((ref) {
      return ExpenseListNotifier(ref.read(expenseRepositoryProvider));
    });
