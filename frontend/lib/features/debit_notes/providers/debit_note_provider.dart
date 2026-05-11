import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';

class DebitNoteSummary {
  final int id;
  final String debitNoteNumber;
  final String debitNoteDate;
  final int vendorId;
  final String vendorName;
  final double totalAmount;
  final String status;

  const DebitNoteSummary({
    required this.id,
    required this.debitNoteNumber,
    required this.debitNoteDate,
    required this.vendorId,
    required this.vendorName,
    required this.totalAmount,
    required this.status,
  });

  factory DebitNoteSummary.fromJson(Map<String, dynamic> j) {
    final vendor = (j['vendor'] as Map<String, dynamic>?) ?? {};
    return DebitNoteSummary(
      id: j['id'] as int,
      debitNoteNumber: j['debit_note_number'] as String,
      debitNoteDate: j['debit_note_date'] as String,
      vendorId: j['vendor_id'] as int,
      vendorName: vendor['name'] as String? ?? '',
      totalAmount: (j['total_amount'] as num).toDouble(),
      status: j['status'] as String,
    );
  }
}

class DebitNoteRepository {
  final ApiClient _client;
  DebitNoteRepository(this._client);

  Future<Map<String, dynamic>> list({
    int page = 1,
    String? search,
    String? status,
  }) async {
    final res = await _client.dio.get(
      '/api/v1/debit-notes',
      queryParameters: {
        'page': page,
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null) 'status': status,
      },
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> get(int id) async {
    final res = await _client.dio.get('/api/v1/debit-notes/$id');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final res = await _client.dio.post('/api/v1/debit-notes', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> update(int id, Map<String, dynamic> data) async {
    final res = await _client.dio.put('/api/v1/debit-notes/$id', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> post(int id) async {
    final res = await _client.dio.post('/api/v1/debit-notes/$id/post');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> cancel(int id) async {
    final res = await _client.dio.post('/api/v1/debit-notes/$id/cancel');
    return res.data as Map<String, dynamic>;
  }

  String pdfUrl(int id) =>
      '${_client.dio.options.baseUrl}/api/v1/debit-notes/$id/pdf';
}

class DebitNoteListState {
  final List<DebitNoteSummary> items;
  final bool isLoading;
  final String? error;

  const DebitNoteListState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  DebitNoteListState copyWith({
    List<DebitNoteSummary>? items,
    bool? isLoading,
    String? error,
  }) {
    return DebitNoteListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class DebitNoteListNotifier extends StateNotifier<DebitNoteListState> {
  final DebitNoteRepository _repo;

  DebitNoteListNotifier(this._repo) : super(const DebitNoteListState()) {
    load();
  }

  Future<void> load({String? search}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repo.list(search: search);
      final raw = (data['data'] as List<dynamic>)
          .map((e) => DebitNoteSummary.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(items: raw, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => load();
}

final debitNoteRepositoryProvider = Provider<DebitNoteRepository>((ref) {
  return DebitNoteRepository(ref.read(apiClientProvider));
});

final debitNoteListProvider =
    StateNotifierProvider<DebitNoteListNotifier, DebitNoteListState>((ref) {
      return DebitNoteListNotifier(ref.read(debitNoteRepositoryProvider));
    });
