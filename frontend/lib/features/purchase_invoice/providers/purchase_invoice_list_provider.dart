import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../purchase_invoice_repository.dart';

// ── Provider wiring ──────────────────────────────────────────────────────────

final purchaseInvoiceRepositoryProvider = Provider<PurchaseInvoiceRepository>((
  ref,
) {
  final client = ref.watch(apiClientProvider);
  return PurchaseInvoiceRepository(client);
});

// ── State ────────────────────────────────────────────────────────────────────

class PurchaseInvoiceListState {
  final List<PurchaseInvoiceSummary> items;
  final int total;
  final int lastPage;
  final int currentPage;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final String? statusFilter;

  const PurchaseInvoiceListState({
    this.items = const [],
    this.total = 0,
    this.lastPage = 1,
    this.currentPage = 1,
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.statusFilter,
  });

  PurchaseInvoiceListState copyWith({
    List<PurchaseInvoiceSummary>? items,
    int? total,
    int? lastPage,
    int? currentPage,
    bool? isLoading,
    String? error,
    String? searchQuery,
    String? statusFilter,
    bool clearError = false,
  }) => PurchaseInvoiceListState(
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

// ── Notifier ──────────────────────────────────────────────────────────────────

class PurchaseInvoiceListNotifier
    extends StateNotifier<PurchaseInvoiceListState> {
  final PurchaseInvoiceRepository _repo;

  PurchaseInvoiceListNotifier(this._repo)
    : super(const PurchaseInvoiceListState()) {
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
    state = state.copyWith(searchQuery: query);
    await load();
  }

  Future<void> filterByStatus(String? status) async {
    state = state.copyWith(statusFilter: status);
    await load();
  }

  Future<void> refresh() => load(page: state.currentPage);
}

// ── Exported provider ─────────────────────────────────────────────────────────

final purchaseInvoiceListProvider =
    StateNotifierProvider<
      PurchaseInvoiceListNotifier,
      PurchaseInvoiceListState
    >((ref) {
      final repo = ref.watch(purchaseInvoiceRepositoryProvider);
      return PurchaseInvoiceListNotifier(repo);
    });
