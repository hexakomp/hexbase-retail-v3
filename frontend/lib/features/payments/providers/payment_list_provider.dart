import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../payment_repository.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return PaymentRepository(client);
});

class PaymentListState {
  final List<PaymentSummary> items;
  final int total;
  final int lastPage;
  final int currentPage;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final String? statusFilter;
  final String? modeFilter;

  const PaymentListState({
    this.items = const [],
    this.total = 0,
    this.lastPage = 1,
    this.currentPage = 1,
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.statusFilter,
    this.modeFilter,
  });

  PaymentListState copyWith({
    List<PaymentSummary>? items,
    int? total,
    int? lastPage,
    int? currentPage,
    bool? isLoading,
    String? error,
    String? searchQuery,
    String? statusFilter,
    String? modeFilter,
    bool clearError = false,
  }) => PaymentListState(
    items: items ?? this.items,
    total: total ?? this.total,
    lastPage: lastPage ?? this.lastPage,
    currentPage: currentPage ?? this.currentPage,
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : (error ?? this.error),
    searchQuery: searchQuery ?? this.searchQuery,
    statusFilter: statusFilter ?? this.statusFilter,
    modeFilter: modeFilter ?? this.modeFilter,
  );
}

class PaymentListNotifier extends StateNotifier<PaymentListState> {
  final PaymentRepository _repo;

  PaymentListNotifier(this._repo) : super(const PaymentListState()) {
    load();
  }

  Future<void> load({int page = 1}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repo.list(
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
        status: state.statusFilter,
        paymentMode: state.modeFilter,
        page: page,
      );
      state = state.copyWith(
        items: result.items,
        total: result.total,
        lastPage: result.lastPage,
        currentPage: page,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> search(String query) async {
    state = state.copyWith(searchQuery: query);
    await load();
  }

  Future<void> filterByStatus(String? status) async {
    state = state.copyWith(statusFilter: status);
    await load();
  }

  Future<void> filterByMode(String? mode) async {
    state = state.copyWith(modeFilter: mode);
    await load();
  }

  Future<void> refresh() => load(page: state.currentPage);
}

final paymentListProvider =
    StateNotifierProvider<PaymentListNotifier, PaymentListState>((ref) {
      final repo = ref.watch(paymentRepositoryProvider);
      return PaymentListNotifier(repo);
    });
