import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../sales_invoice_repository.dart';
import 'invoice_list_provider.dart';

// ── Line form model ──────────────────────────────────────────────────────────

class InvoiceLineForm {
  final int? productId;
  final String productName;
  final String description;
  final String hsnSac;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double discountPct;
  final double gstRate;
  final double cessRate;
  // Computed from /calculate
  final double taxableAmount;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double lineTotal;

  const InvoiceLineForm({
    this.productId,
    this.productName = '',
    this.description = '',
    this.hsnSac = '',
    this.quantity = 1,
    this.unit = 'PCS',
    this.unitPrice = 0,
    this.discountPct = 0,
    this.gstRate = 18,
    this.cessRate = 0,
    this.taxableAmount = 0,
    this.cgstAmount = 0,
    this.sgstAmount = 0,
    this.igstAmount = 0,
    this.lineTotal = 0,
  });

  InvoiceLineForm copyWith({
    int? productId,
    String? productName,
    String? description,
    String? hsnSac,
    double? quantity,
    String? unit,
    double? unitPrice,
    double? discountPct,
    double? gstRate,
    double? cessRate,
    double? taxableAmount,
    double? cgstAmount,
    double? sgstAmount,
    double? igstAmount,
    double? lineTotal,
  }) => InvoiceLineForm(
    productId: productId ?? this.productId,
    productName: productName ?? this.productName,
    description: description ?? this.description,
    hsnSac: hsnSac ?? this.hsnSac,
    quantity: quantity ?? this.quantity,
    unit: unit ?? this.unit,
    unitPrice: unitPrice ?? this.unitPrice,
    discountPct: discountPct ?? this.discountPct,
    gstRate: gstRate ?? this.gstRate,
    cessRate: cessRate ?? this.cessRate,
    taxableAmount: taxableAmount ?? this.taxableAmount,
    cgstAmount: cgstAmount ?? this.cgstAmount,
    sgstAmount: sgstAmount ?? this.sgstAmount,
    igstAmount: igstAmount ?? this.igstAmount,
    lineTotal: lineTotal ?? this.lineTotal,
  );

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'description': description,
    'hsn_sac': hsnSac,
    'quantity': quantity,
    'unit': unit,
    'rate': unitPrice,
    'discount_percent': discountPct,
    'gst_rate': gstRate,
    'cess_rate': cessRate,
  };
}

// ── Form State ───────────────────────────────────────────────────────────────

class InvoiceFormState {
  final int? editingId;
  final int? customerId;
  final String customerName;
  final String invoiceDate;
  final String? dueDate;
  final String invoiceType; // b2b | b2c | export
  final String placeOfSupply;
  final String? paymentTerms;
  final String narration;
  final List<InvoiceLineForm> lines;
  // Aggregated totals from /calculate
  final double subtotal;
  final double discountAmount;
  final double taxableAmount;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double cessAmount;
  final double roundOff;
  final double totalAmount;
  // Async state
  final bool isSaving;
  final bool isCalculating;
  final String? error;
  final bool saved;

  const InvoiceFormState({
    this.editingId,
    this.customerId,
    this.customerName = '',
    String? invoiceDate,
    this.dueDate,
    this.invoiceType = 'b2b',
    this.placeOfSupply = '',
    this.paymentTerms,
    this.narration = '',
    this.lines = const [],
    this.subtotal = 0,
    this.discountAmount = 0,
    this.taxableAmount = 0,
    this.cgstAmount = 0,
    this.sgstAmount = 0,
    this.igstAmount = 0,
    this.cessAmount = 0,
    this.roundOff = 0,
    this.totalAmount = 0,
    this.isSaving = false,
    this.isCalculating = false,
    this.error,
    this.saved = false,
  }) : invoiceDate = invoiceDate ?? '';

  InvoiceFormState copyWith({
    int? editingId,
    int? customerId,
    String? customerName,
    String? invoiceDate,
    String? dueDate,
    String? invoiceType,
    String? placeOfSupply,
    String? paymentTerms,
    String? narration,
    List<InvoiceLineForm>? lines,
    double? subtotal,
    double? discountAmount,
    double? taxableAmount,
    double? cgstAmount,
    double? sgstAmount,
    double? igstAmount,
    double? cessAmount,
    double? roundOff,
    double? totalAmount,
    bool? isSaving,
    bool? isCalculating,
    String? error,
    bool? saved,
    bool clearError = false,
  }) => InvoiceFormState(
    editingId: editingId ?? this.editingId,
    customerId: customerId ?? this.customerId,
    customerName: customerName ?? this.customerName,
    invoiceDate: invoiceDate ?? this.invoiceDate,
    dueDate: dueDate ?? this.dueDate,
    invoiceType: invoiceType ?? this.invoiceType,
    placeOfSupply: placeOfSupply ?? this.placeOfSupply,
    paymentTerms: paymentTerms ?? this.paymentTerms,
    narration: narration ?? this.narration,
    lines: lines ?? this.lines,
    subtotal: subtotal ?? this.subtotal,
    discountAmount: discountAmount ?? this.discountAmount,
    taxableAmount: taxableAmount ?? this.taxableAmount,
    cgstAmount: cgstAmount ?? this.cgstAmount,
    sgstAmount: sgstAmount ?? this.sgstAmount,
    igstAmount: igstAmount ?? this.igstAmount,
    cessAmount: cessAmount ?? this.cessAmount,
    roundOff: roundOff ?? this.roundOff,
    totalAmount: totalAmount ?? this.totalAmount,
    isSaving: isSaving ?? this.isSaving,
    isCalculating: isCalculating ?? this.isCalculating,
    error: clearError ? null : (error ?? this.error),
    saved: saved ?? this.saved,
  );

  bool get isEditing => editingId != null;
}

// ── InvoiceFormNotifier ──────────────────────────────────────────────────────

class InvoiceFormNotifier extends StateNotifier<InvoiceFormState> {
  final SalesInvoiceRepository _repo;
  Timer? _calcDebounce;

  InvoiceFormNotifier(this._repo) : super(InvoiceFormState());

  // ── Initialisation ────────────────────────────────────────────────────────

  /// Load an existing invoice for editing.
  Future<void> loadForEdit(int id) async {
    final detail = await _repo.show(id);
    state = InvoiceFormState(
      editingId: id,
      customerId: detail.customerId,
      customerName: detail.customerName,
      invoiceDate: detail.invoiceDate,
      dueDate: detail.dueDate,
      invoiceType: detail.invoiceType,
      placeOfSupply: detail.placeOfSupply,
      narration: detail.narration ?? '',
      lines: detail.lines
          .map(
            (l) => InvoiceLineForm(
              productId: l.productId,
              productName: l.productName ?? '',
              description: l.description ?? '',
              hsnSac: l.hsnSac ?? '',
              quantity: l.quantity,
              unit: l.unit,
              unitPrice: l.unitPrice,
              discountPct: l.discountPct,
              gstRate: l.gstRate,
              taxableAmount: l.taxableAmount,
              cgstAmount: l.cgstAmount,
              sgstAmount: l.sgstAmount,
              igstAmount: l.igstAmount,
              lineTotal: l.lineTotal,
            ),
          )
          .toList(),
      subtotal: detail.subtotal,
      discountAmount: detail.discountAmount,
      taxableAmount: detail.taxableAmount,
      cgstAmount: detail.cgstAmount,
      sgstAmount: detail.sgstAmount,
      igstAmount: detail.igstAmount,
      cessAmount: detail.cessAmount,
      roundOff: detail.roundOff,
      totalAmount: detail.totalAmount,
    );
  }

  void reset() {
    _calcDebounce?.cancel();
    state = InvoiceFormState();
  }

  // ── Header fields ─────────────────────────────────────────────────────────

  void setCustomer(int id, String name) {
    state = state.copyWith(customerId: id, customerName: name);
    _scheduleCalculate();
  }

  void setInvoiceDate(String date) => state = state.copyWith(invoiceDate: date);

  void setDueDate(String? date) => state = state.copyWith(dueDate: date);

  void setInvoiceType(String type) {
    state = state.copyWith(invoiceType: type);
    _scheduleCalculate();
  }

  void setPlaceOfSupply(String pos) {
    state = state.copyWith(placeOfSupply: pos);
    _scheduleCalculate();
  }

  void setPaymentTerms(String? terms) =>
      state = state.copyWith(paymentTerms: terms);

  void setNarration(String text) => state = state.copyWith(narration: text);

  // ── Line operations ───────────────────────────────────────────────────────

  void addLine() {
    final lines = [...state.lines, const InvoiceLineForm()];
    state = state.copyWith(lines: lines);
  }

  void removeLine(int index) {
    final lines = [...state.lines]..removeAt(index);
    state = state.copyWith(lines: lines);
    _scheduleCalculate();
  }

  void updateLine(int index, InvoiceLineForm updated) {
    final lines = [...state.lines];
    lines[index] = updated;
    state = state.copyWith(lines: lines);
    _scheduleCalculate();
  }

  // ── Tax calculation ───────────────────────────────────────────────────────

  void _scheduleCalculate() {
    _calcDebounce?.cancel();
    _calcDebounce = Timer(const Duration(milliseconds: 600), _calculate);
  }

  Future<void> _calculate() async {
    if (state.customerId == null) return;
    if (state.lines.isEmpty) return;
    final validLines = state.lines
        .where((l) => l.productId != null && l.quantity > 0 && l.unitPrice >= 0)
        .toList();
    if (validLines.isEmpty) return;

    state = state.copyWith(isCalculating: true);
    try {
      final result = await _repo.calculate({
        'customer_id': state.customerId,
        'place_of_supply': state.placeOfSupply,
        'invoice_type': state.invoiceType,
        'lines': validLines.map((l) => l.toJson()).toList(),
      });

      final calcLines = (result['lines'] as List<dynamic>?) ?? [];
      final updatedLines = <InvoiceLineForm>[];
      int calcIdx = 0;
      for (final line in state.lines) {
        if (line.productId != null &&
            line.quantity > 0 &&
            line.unitPrice >= 0) {
          if (calcIdx < calcLines.length) {
            final cl = calcLines[calcIdx] as Map<String, dynamic>;
            updatedLines.add(
              line.copyWith(
                taxableAmount: _d(cl['taxable_amount']),
                cgstAmount: _d(cl['cgst_amount']),
                sgstAmount: _d(cl['sgst_amount']),
                igstAmount: _d(cl['igst_amount']),
                lineTotal: _d(cl['line_total']),
              ),
            );
            calcIdx++;
          } else {
            updatedLines.add(line);
          }
        } else {
          updatedLines.add(line);
        }
      }

      state = state.copyWith(
        lines: updatedLines,
        subtotal: _d(result['subtotal']),
        discountAmount: _d(result['discount_amount']),
        taxableAmount: _d(result['taxable_amount']),
        cgstAmount: _d(result['cgst_amount']),
        sgstAmount: _d(result['sgst_amount']),
        igstAmount: _d(result['igst_amount']),
        cessAmount: _d(result['cess_amount']),
        roundOff: _d(result['round_off']),
        totalAmount: _d(result['grand_total']),
        isCalculating: false,
      );
    } catch (e) {
      state = state.copyWith(isCalculating: false);
    }
  }

  static double _d(dynamic v) =>
      v == null ? 0.0 : double.tryParse(v.toString()) ?? 0.0;

  // ── Save ──────────────────────────────────────────────────────────────────

  Map<String, dynamic> _buildPayload(String status) => {
    'customer_id': state.customerId,
    'invoice_date': state.invoiceDate,
    if (state.dueDate != null) 'due_date': state.dueDate,
    'invoice_type': state.invoiceType,
    'place_of_supply': state.placeOfSupply,
    if (state.paymentTerms != null) 'payment_terms': state.paymentTerms,
    'narration': state.narration,
    'status': status,
    'lines': state.lines
        .where((l) => l.productId != null)
        .map((l) => l.toJson())
        .toList(),
  };

  Future<int?> saveDraft() async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final SalesInvoiceDetail result;
      if (state.isEditing) {
        result = await _repo.update(state.editingId!, _buildPayload('draft'));
      } else {
        result = await _repo.store(_buildPayload('draft'));
      }
      state = state.copyWith(
        isSaving: false,
        saved: true,
        editingId: result.id,
      );
      return result.id;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return null;
    }
  }

  Future<int?> saveAndPost() async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final SalesInvoiceDetail result;
      if (state.isEditing) {
        result = await _repo.update(state.editingId!, _buildPayload('draft'));
        await _repo.post(result.id);
      } else {
        result = await _repo.store(_buildPayload('draft'));
        await _repo.post(result.id);
      }
      state = state.copyWith(
        isSaving: false,
        saved: true,
        editingId: result.id,
      );
      return result.id;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return null;
    }
  }
}

final invoiceFormProvider =
    StateNotifierProvider.autoDispose<InvoiceFormNotifier, InvoiceFormState>((
      ref,
    ) {
      final repo = ref.watch(salesInvoiceRepositoryProvider);
      return InvoiceFormNotifier(repo);
    });
