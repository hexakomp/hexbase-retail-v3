import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';

// ── Repository ───────────────────────────────────────────────────────────────

class FinancialReportRepository {
  final ApiClient _client;
  FinancialReportRepository(this._client);

  Future<Map<String, dynamic>> trialBalance(String asOfDate) async {
    final res = await _client.dio.get(
      '/api/v1/reports/financial/trial-balance',
      queryParameters: {'as_of_date': asOfDate},
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> profitLoss(
    String fromDate,
    String toDate,
  ) async {
    final res = await _client.dio.get(
      '/api/v1/reports/financial/profit-loss',
      queryParameters: {'from_date': fromDate, 'to_date': toDate},
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> balanceSheet(String asOfDate) async {
    final res = await _client.dio.get(
      '/api/v1/reports/financial/balance-sheet',
      queryParameters: {'as_of_date': asOfDate},
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> dayBook(String fromDate, String toDate) async {
    final res = await _client.dio.get(
      '/api/v1/reports/financial/day-book',
      queryParameters: {'from_date': fromDate, 'to_date': toDate},
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> cashBook(String fromDate, String toDate) async {
    final res = await _client.dio.get(
      '/api/v1/reports/financial/cash-book',
      queryParameters: {'from_date': fromDate, 'to_date': toDate},
    );
    return res.data as Map<String, dynamic>;
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────

final financialReportRepositoryProvider = Provider<FinancialReportRepository>((
  ref,
) {
  return FinancialReportRepository(ref.watch(apiClientProvider));
});

// ── State ─────────────────────────────────────────────────────────────────────

class FinancialReportState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? data;

  const FinancialReportState({this.isLoading = false, this.error, this.data});

  FinancialReportState copyWith({
    bool? isLoading,
    String? error,
    Map<String, dynamic>? data,
    bool clearError = false,
  }) => FinancialReportState(
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : error ?? this.error,
    data: data ?? this.data,
  );
}

// ── Notifiers ─────────────────────────────────────────────────────────────────

class TrialBalanceNotifier extends StateNotifier<FinancialReportState> {
  final FinancialReportRepository _repo;
  TrialBalanceNotifier(this._repo) : super(const FinancialReportState());

  Future<void> load(String asOfDate) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _repo.trialBalance(asOfDate);
      state = state.copyWith(
        isLoading: false,
        data: res['data'] as Map<String, dynamic>?,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

class ProfitLossNotifier extends StateNotifier<FinancialReportState> {
  final FinancialReportRepository _repo;
  ProfitLossNotifier(this._repo) : super(const FinancialReportState());

  Future<void> load(String from, String to) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _repo.profitLoss(from, to);
      state = state.copyWith(
        isLoading: false,
        data: res['data'] as Map<String, dynamic>?,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

class BalanceSheetNotifier extends StateNotifier<FinancialReportState> {
  final FinancialReportRepository _repo;
  BalanceSheetNotifier(this._repo) : super(const FinancialReportState());

  Future<void> load(String asOfDate) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _repo.balanceSheet(asOfDate);
      state = state.copyWith(
        isLoading: false,
        data: res['data'] as Map<String, dynamic>?,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

class DayBookNotifier extends StateNotifier<FinancialReportState> {
  final FinancialReportRepository _repo;
  DayBookNotifier(this._repo) : super(const FinancialReportState());

  Future<void> load(String from, String to) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _repo.dayBook(from, to);
      state = state.copyWith(
        isLoading: false,
        data: res['data'] as Map<String, dynamic>?,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

class CashBookNotifier extends StateNotifier<FinancialReportState> {
  final FinancialReportRepository _repo;
  CashBookNotifier(this._repo) : super(const FinancialReportState());

  Future<void> load(String from, String to) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _repo.cashBook(from, to);
      state = state.copyWith(
        isLoading: false,
        data: res['data'] as Map<String, dynamic>?,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final trialBalanceProvider =
    StateNotifierProvider<TrialBalanceNotifier, FinancialReportState>((ref) {
      return TrialBalanceNotifier(ref.watch(financialReportRepositoryProvider));
    });

final profitLossProvider =
    StateNotifierProvider<ProfitLossNotifier, FinancialReportState>((ref) {
      return ProfitLossNotifier(ref.watch(financialReportRepositoryProvider));
    });

final balanceSheetProvider =
    StateNotifierProvider<BalanceSheetNotifier, FinancialReportState>((ref) {
      return BalanceSheetNotifier(ref.watch(financialReportRepositoryProvider));
    });

final dayBookProvider =
    StateNotifierProvider<DayBookNotifier, FinancialReportState>((ref) {
      return DayBookNotifier(ref.watch(financialReportRepositoryProvider));
    });

final cashBookProvider =
    StateNotifierProvider<CashBookNotifier, FinancialReportState>((ref) {
      return CashBookNotifier(ref.watch(financialReportRepositoryProvider));
    });
