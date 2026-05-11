import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class CreditNoteSummary {
  final int id;
  final String creditNoteNumber;
  final String creditNoteDate;
  final int customerId;
  final String customerName;
  final double totalAmount;
  final String status;

  const CreditNoteSummary({
    required this.id,
    required this.creditNoteNumber,
    required this.creditNoteDate,
    required this.customerId,
    required this.customerName,
    required this.totalAmount,
    required this.status,
  });

  factory CreditNoteSummary.fromJson(Map<String, dynamic> j) {
    final customer = (j['customer'] as Map<String, dynamic>?) ?? {};
    return CreditNoteSummary(
      id: j['id'] as int,
      creditNoteNumber: j['credit_note_number'] as String,
      creditNoteDate: j['credit_note_date'] as String,
      customerId: j['customer_id'] as int,
      customerName: customer['name'] as String? ?? '',
      totalAmount: (j['total_amount'] as num).toDouble(),
      status: j['status'] as String,
    );
  }
}

// ── Repository ────────────────────────────────────────────────────────────────

class CreditNoteRepository {
  final ApiClient _client;
  CreditNoteRepository(this._client);

  Future<Map<String, dynamic>> list({
    int page = 1,
    String? search,
    String? status,
  }) async {
    final res = await _client.dio.get(
      '/api/v1/credit-notes',
      queryParameters: {
        'page': page,
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null) 'status': status,
      },
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> get(int id) async {
    final res = await _client.dio.get('/api/v1/credit-notes/$id');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final res = await _client.dio.post('/api/v1/credit-notes', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> update(int id, Map<String, dynamic> data) async {
    final res = await _client.dio.put('/api/v1/credit-notes/$id', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> post(int id) async {
    final res = await _client.dio.post('/api/v1/credit-notes/$id/post');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> cancel(int id) async {
    final res = await _client.dio.post('/api/v1/credit-notes/$id/cancel');
    return res.data as Map<String, dynamic>;
  }

  String pdfUrl(int id) =>
      '${_client.dio.options.baseUrl}/api/v1/credit-notes/$id/pdf';
}

// ── State ─────────────────────────────────────────────────────────────────────

class CreditNoteListState {
  final List<CreditNoteSummary> items;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int lastPage;

  const CreditNoteListState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.lastPage = 1,
  });

  CreditNoteListState copyWith({
    List<CreditNoteSummary>? items,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? lastPage,
  }) {
    return CreditNoteListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class CreditNoteListNotifier extends StateNotifier<CreditNoteListState> {
  final CreditNoteRepository _repo;

  CreditNoteListNotifier(this._repo) : super(const CreditNoteListState()) {
    load();
  }

  Future<void> load({String? search}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repo.list(search: search);
      final meta = data['meta'] as Map<String, dynamic>;
      final raw = (data['data'] as List<dynamic>)
          .map((e) => CreditNoteSummary.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(
        items: raw,
        isLoading: false,
        currentPage: meta['current_page'] as int,
        lastPage: meta['last_page'] as int,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => load();
}

// ── Providers ─────────────────────────────────────────────────────────────────

final creditNoteRepositoryProvider = Provider<CreditNoteRepository>((ref) {
  return CreditNoteRepository(ref.read(apiClientProvider));
});

final creditNoteListProvider =
    StateNotifierProvider<CreditNoteListNotifier, CreditNoteListState>((ref) {
      return CreditNoteListNotifier(ref.read(creditNoteRepositoryProvider));
    });
