import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../sales_invoice_repository.dart';

// ── Provider wiring ──────────────────────────────────────────────────────────

final salesInvoiceRepositoryProvider = Provider<SalesInvoiceRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return SalesInvoiceRepository(client);
});

// ── Invoice List State ────────────────────────────────────────────────────────

class InvoiceListState {
  final List<SalesInvoiceSummary> items;
  final int total;
  final int lastPage;
  final int currentPage;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final String? statusFilter;

  const InvoiceListState({
    this.items = const [],
    this.total = 0,
    this.lastPage = 1,
    this.currentPage = 1,
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.statusFilter,
  });

  InvoiceListState copyWith({
    List<SalesInvoiceSummary>? items,
    int? total,
    int? lastPage,
    int? currentPage,
    bool? isLoading,
    String? error,
    String? searchQuery,
    String? statusFilter,
    bool clearError = false,
  }) => InvoiceListState(
    items: items ?? this.items,
    total: total ?? this.total,
    lastPage: lastPage ?? this.lastPage,
    currentPage: currentPage ?? this.currentPage,
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : (error ?? this.error),
    searchQuery: searchQuery ?? this.searchQuery,
    statusFilter: statusFilter ?? this.statusFilter,
  );
}

// ── InvoiceListNotifier ──────────────────────────────────────────────────────

class InvoiceListNotifier extends StateNotifier<InvoiceListState> {
  final SalesInvoiceRepository _repo;

  InvoiceListNotifier(this._repo) : super(const InvoiceListState()) {
    load();
  }

  Future<void> load({int page = 1}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repo.list(
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
        status: state.statusFilter,
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
    state = state.copyWith(searchQuery: query, currentPage: 1);
    await load();
  }

  Future<void> filterByStatus(String? status) async {
    state = state.copyWith(statusFilter: status, currentPage: 1);
    await load();
  }

  Future<void> refresh() => load(page: state.currentPage);

  Future<void> nextPage() async {
    if (state.currentPage < state.lastPage) {
      await load(page: state.currentPage + 1);
    }
  }

  Future<void> prevPage() async {
    if (state.currentPage > 1) {
      await load(page: state.currentPage - 1);
    }
  }

  Future<bool> postInvoice(int id) async {
    try {
      await _repo.post(id);
      await refresh();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> cancelInvoice(int id, String reason) async {
    try {
      await _repo.cancel(id, reason);
      await refresh();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final invoiceListProvider =
    StateNotifierProvider<InvoiceListNotifier, InvoiceListState>((ref) {
      final repo = ref.watch(salesInvoiceRepositoryProvider);
      return InvoiceListNotifier(repo);
    });
