import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';

// ── Repository ───────────────────────────────────────────────────────────────

class GstReportRepository {
  final ApiClient _client;
  GstReportRepository(this._client);

  Future<Map<String, dynamic>> gstr1({
    required String fromDate,
    required String toDate,
    String section = 'b2b',
  }) async {
    final res = await _client.dio.get(
      '/api/v1/reports/gst/gstr1',
      queryParameters: {
        'from_date': fromDate,
        'to_date': toDate,
        'section': section,
      },
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> gstr3bSupport({
    required String fromDate,
    required String toDate,
  }) async {
    final res = await _client.dio.get(
      '/api/v1/reports/gst/gstr3b-support',
      queryParameters: {'from_date': fromDate, 'to_date': toDate},
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> itcRegister({
    required String fromDate,
    required String toDate,
    int? vendorId,
  }) async {
    final res = await _client.dio.get(
      '/api/v1/reports/gst/itc-register',
      queryParameters: {
        'from_date': fromDate,
        'to_date': toDate,
        if (vendorId != null) 'vendor_id': vendorId,
      },
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> salesTaxRegister({
    required String fromDate,
    required String toDate,
  }) async {
    final res = await _client.dio.get(
      '/api/v1/reports/gst/sales-tax-register',
      queryParameters: {'from_date': fromDate, 'to_date': toDate},
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> purchaseTaxRegister({
    required String fromDate,
    required String toDate,
  }) async {
    final res = await _client.dio.get(
      '/api/v1/reports/gst/purchase-tax-register',
      queryParameters: {'from_date': fromDate, 'to_date': toDate},
    );
    return res.data as Map<String, dynamic>;
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────

final gstReportRepositoryProvider = Provider<GstReportRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return GstReportRepository(client);
});

// ── State ─────────────────────────────────────────────────────────────────────

class GstReportState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? data;
  final String fromDate;
  final String toDate;
  final String section; // for GSTR-1 multi-section

  const GstReportState({
    this.isLoading = false,
    this.error,
    this.data,
    this.fromDate = '',
    this.toDate = '',
    this.section = 'b2b',
  });

  GstReportState copyWith({
    bool? isLoading,
    String? error,
    Map<String, dynamic>? data,
    String? fromDate,
    String? toDate,
    String? section,
    bool clearError = false,
  }) => GstReportState(
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : error ?? this.error,
    data: data ?? this.data,
    fromDate: fromDate ?? this.fromDate,
    toDate: toDate ?? this.toDate,
    section: section ?? this.section,
  );
}

// ── Notifiers ─────────────────────────────────────────────────────────────────

class Gstr1Notifier extends StateNotifier<GstReportState> {
  final GstReportRepository _repo;
  Gstr1Notifier(this._repo) : super(const GstReportState());

  Future<void> load({
    required String fromDate,
    required String toDate,
    String section = 'b2b',
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      fromDate: fromDate,
      toDate: toDate,
      section: section,
    );
    try {
      final res = await _repo.gstr1(
        fromDate: fromDate,
        toDate: toDate,
        section: section,
      );
      state = state.copyWith(
        isLoading: false,
        data: res['data'] as Map<String, dynamic>?,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

class Gstr3bNotifier extends StateNotifier<GstReportState> {
  final GstReportRepository _repo;
  Gstr3bNotifier(this._repo) : super(const GstReportState());

  Future<void> load({required String fromDate, required String toDate}) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      fromDate: fromDate,
      toDate: toDate,
    );
    try {
      final res = await _repo.gstr3bSupport(fromDate: fromDate, toDate: toDate);
      state = state.copyWith(
        isLoading: false,
        data: res['data'] as Map<String, dynamic>?,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

class ItcRegisterNotifier extends StateNotifier<GstReportState> {
  final GstReportRepository _repo;
  ItcRegisterNotifier(this._repo) : super(const GstReportState());

  Future<void> load({required String fromDate, required String toDate}) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      fromDate: fromDate,
      toDate: toDate,
    );
    try {
      final res = await _repo.itcRegister(fromDate: fromDate, toDate: toDate);
      state = state.copyWith(
        isLoading: false,
        data: res['data'] as Map<String, dynamic>?,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

class TaxRegisterNotifier extends StateNotifier<GstReportState> {
  final GstReportRepository _repo;
  final bool isSales;
  TaxRegisterNotifier(this._repo, {this.isSales = true})
    : super(const GstReportState());

  Future<void> load({required String fromDate, required String toDate}) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      fromDate: fromDate,
      toDate: toDate,
    );
    try {
      final res = isSales
          ? await _repo.salesTaxRegister(fromDate: fromDate, toDate: toDate)
          : await _repo.purchaseTaxRegister(fromDate: fromDate, toDate: toDate);
      state = state.copyWith(
        isLoading: false,
        data: res['data'] as Map<String, dynamic>?,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final gstr1Provider = StateNotifierProvider<Gstr1Notifier, GstReportState>((
  ref,
) {
  return Gstr1Notifier(ref.watch(gstReportRepositoryProvider));
});

final gstr3bProvider = StateNotifierProvider<Gstr3bNotifier, GstReportState>((
  ref,
) {
  return Gstr3bNotifier(ref.watch(gstReportRepositoryProvider));
});

final itcRegisterProvider =
    StateNotifierProvider<ItcRegisterNotifier, GstReportState>((ref) {
      return ItcRegisterNotifier(ref.watch(gstReportRepositoryProvider));
    });

final salesTaxRegisterProvider =
    StateNotifierProvider<TaxRegisterNotifier, GstReportState>((ref) {
      return TaxRegisterNotifier(
        ref.watch(gstReportRepositoryProvider),
        isSales: true,
      );
    });

final purchaseTaxRegisterProvider =
    StateNotifierProvider<TaxRegisterNotifier, GstReportState>((ref) {
      return TaxRegisterNotifier(
        ref.watch(gstReportRepositoryProvider),
        isSales: false,
      );
    });
