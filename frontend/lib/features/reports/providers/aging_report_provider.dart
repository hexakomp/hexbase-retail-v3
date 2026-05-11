import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';

class AgingBucket {
  final String entityId;
  final String entityName;
  final double current;
  final double days3160;
  final double days6190;
  final double over90;
  final double total;

  const AgingBucket({
    required this.entityId,
    required this.entityName,
    required this.current,
    required this.days3160,
    required this.days6190,
    required this.over90,
    required this.total,
  });

  factory AgingBucket.fromReceivablesJson(Map<String, dynamic> j) =>
      AgingBucket(
        entityId: j['customer_id']?.toString() ?? '',
        entityName: j['customer_name'] ?? '',
        current: (j['current'] ?? 0).toDouble(),
        days3160: (j['days_31_60'] ?? 0).toDouble(),
        days6190: (j['days_61_90'] ?? 0).toDouble(),
        over90: (j['over_90'] ?? 0).toDouble(),
        total: (j['total'] ?? 0).toDouble(),
      );

  factory AgingBucket.fromPayablesJson(Map<String, dynamic> j) => AgingBucket(
    entityId: j['vendor_id']?.toString() ?? '',
    entityName: j['vendor_name'] ?? '',
    current: (j['current'] ?? 0).toDouble(),
    days3160: (j['days_31_60'] ?? 0).toDouble(),
    days6190: (j['days_61_90'] ?? 0).toDouble(),
    over90: (j['over_90'] ?? 0).toDouble(),
    total: (j['total'] ?? 0).toDouble(),
  );
}

class AgingReportRepository {
  final ApiClient _client;
  AgingReportRepository(this._client);

  Future<List<AgingBucket>> receivables(String asOfDate) async {
    final res = await _client.dio.get(
      '/api/v1/reports/financial/receivables-ageing',
      queryParameters: {'as_of_date': asOfDate},
    );
    return (res.data['data'] as List)
        .map((j) => AgingBucket.fromReceivablesJson(j))
        .toList();
  }

  Future<List<AgingBucket>> payables(String asOfDate) async {
    final res = await _client.dio.get(
      '/api/v1/reports/financial/payables-ageing',
      queryParameters: {'as_of_date': asOfDate},
    );
    return (res.data['data'] as List)
        .map((j) => AgingBucket.fromPayablesJson(j))
        .toList();
  }
}

// ── State ─────────────────────────────────────────────────────────────────────

class AgingReportState {
  final bool isLoading;
  final String? error;
  final List<AgingBucket> items;

  const AgingReportState({
    this.isLoading = false,
    this.error,
    this.items = const [],
  });

  AgingReportState copyWith({
    bool? isLoading,
    String? error,
    List<AgingBucket>? items,
    bool clearError = false,
  }) => AgingReportState(
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : error ?? this.error,
    items: items ?? this.items,
  );
}

// ── Notifiers ─────────────────────────────────────────────────────────────────

class AgingReportNotifier extends StateNotifier<AgingReportState> {
  final Future<List<AgingBucket>> Function(String) _fetcher;
  AgingReportNotifier(this._fetcher) : super(const AgingReportState());

  Future<void> load(String date) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await _fetcher(date);
      state = state.copyWith(isLoading: false, items: items);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

// ── Providers ────────────────────────────────────────────────────────────────

final agingReportRepositoryProvider = Provider(
  (ref) => AgingReportRepository(ref.watch(apiClientProvider)),
);

final receivablesAgingProvider =
    StateNotifierProvider.autoDispose<AgingReportNotifier, AgingReportState>((
      ref,
    ) {
      final repo = ref.watch(agingReportRepositoryProvider);
      return AgingReportNotifier(repo.receivables);
    });

final payablesAgingProvider =
    StateNotifierProvider.autoDispose<AgingReportNotifier, AgingReportState>((
      ref,
    ) {
      final repo = ref.watch(agingReportRepositoryProvider);
      return AgingReportNotifier(repo.payables);
    });
