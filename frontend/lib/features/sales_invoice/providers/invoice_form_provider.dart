import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../sales_invoice_repository.dart';
import 'invoice_list_provider.dart';
import '../../admin/providers/admin_provider.dart';

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
  final String invoiceNumber;
  final int? customerId;
  final String customerName;
  final String billingAddress;
  final String billingCity;
  final String billingState;
  final String billingPincode;
  final String shippingAddress;
  final String customerGstin;
  final String companyGstin;
  final String customerPhone;
  final String invoiceDate;
  final String? dueDate;
  final String invoiceType; // b2b | b2c | export
  final String placeOfSupply;
  final String? paymentTerms;
  final String narration;
  final String internalNotes;
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
    this.invoiceNumber = '',
    this.customerId,
    this.customerName = '',
    this.billingAddress = '',
    this.billingCity = '',
    this.billingState = '',
    this.billingPincode = '',
    this.shippingAddress = '',
    this.customerGstin = '',
    this.companyGstin = '',
    this.customerPhone = '',
    String? invoiceDate,
    this.dueDate,
    this.invoiceType = 'b2b',
    this.placeOfSupply = '',
    this.paymentTerms,
    this.narration = '',
    this.internalNotes = '',
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
    String? invoiceNumber,
    int? customerId,
    String? customerName,
    String? billingAddress,
    String? billingCity,
    String? billingState,
    String? billingPincode,
    String? shippingAddress,
    String? customerGstin,
    String? companyGstin,
    String? customerPhone,
    String? invoiceDate,
    String? dueDate,
    String? invoiceType,
    String? placeOfSupply,
    String? paymentTerms,
    String? narration,
    String? internalNotes,
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
    invoiceNumber: invoiceNumber ?? this.invoiceNumber,
    customerId: customerId ?? this.customerId,
    customerName: customerName ?? this.customerName,
    billingAddress: billingAddress ?? this.billingAddress,
    billingCity: billingCity ?? this.billingCity,
    billingState: billingState ?? this.billingState,
    billingPincode: billingPincode ?? this.billingPincode,
    shippingAddress: shippingAddress ?? this.shippingAddress,
    customerGstin: customerGstin ?? this.customerGstin,
    companyGstin: companyGstin ?? this.companyGstin,
    customerPhone: customerPhone ?? this.customerPhone,
    invoiceDate: invoiceDate ?? this.invoiceDate,
    dueDate: dueDate ?? this.dueDate,
    invoiceType: invoiceType ?? this.invoiceType,
    placeOfSupply: placeOfSupply ?? this.placeOfSupply,
    paymentTerms: paymentTerms ?? this.paymentTerms,
    narration: narration ?? this.narration,
    internalNotes: internalNotes ?? this.internalNotes,
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
  final CompanySettingsRepository _companyRepo;
  Timer? _calcDebounce;

  InvoiceFormNotifier(this._repo, this._companyRepo)
    : super(InvoiceFormState());

  // ── Initialisation ────────────────────────────────────────────────────────

  Future<void> init() async {
    try {
      final settings = await _companyRepo.get();
      state = state.copyWith(companyGstin: settings['gstin']?.toString() ?? '');
    } catch (e) {
      // Ignored
    }
  }

  /// Load an existing invoice for editing.
  Future<void> loadForEdit(int id) async {
    await init();
    final detail = await _repo.show(id);
    state = state.copyWith(
      editingId: id,
      invoiceNumber: detail.invoiceNumber,
      customerId: detail.customerId,
      customerName: detail.customerName,
      billingAddress: detail.customerBillingAddress,
      billingCity: detail.customerBillingCity,
      billingState: detail.customerBillingState,
      billingPincode: detail.customerBillingPincode,
      shippingAddress: detail.customerShippingAddress,
      customerGstin: detail.customerGstin ?? '',
      customerPhone: detail.customerPhone,
      invoiceDate: detail.invoiceDate,
      dueDate: detail.dueDate,
      invoiceType: detail.invoiceType,
      placeOfSupply: detail.placeOfSupply,
      paymentTerms: detail.paymentTerms,
      narration: detail.narration ?? '',
      internalNotes: detail.internalNotes ?? '',
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

  Future<void> reset() async {
    _calcDebounce?.cancel();
    state = InvoiceFormState();
    await init();
  }

  // ── Header fields ─────────────────────────────────────────────────────────

  void setCustomer(
    int id,
    String name, {
    String billingAddress = '',
    String billingCity = '',
    String billingState = '',
    String billingPincode = '',
    String shippingAddress = '',
    String customerGstin = '',
    String customerPhone = '',
    String placeOfSupply = '',
  }) {
    // Auto-fill invoice type: b2b if GSTIN exists, else b2c
    String invoiceType = customerGstin.isNotEmpty ? 'b2b' : 'b2c';

    state = state.copyWith(
      customerId: id,
      customerName: name,
      billingAddress: billingAddress,
      billingCity: billingCity,
      billingState: billingState,
      billingPincode: billingPincode,
      shippingAddress: shippingAddress,
      customerGstin: customerGstin,
      customerPhone: customerPhone,
      invoiceType: invoiceType,
      placeOfSupply: placeOfSupply.isNotEmpty ? placeOfSupply : null,
    );
    _calculateLocally();
  }

  void setInvoiceDate(String date) => state = state.copyWith(invoiceDate: date);

  void setDueDate(String? date) => state = state.copyWith(dueDate: date);

  void setInvoiceType(String type) {
    state = state.copyWith(invoiceType: type);
    _calculateLocally();
  }

  void setPlaceOfSupply(String pos) {
    state = state.copyWith(placeOfSupply: pos);
    _calculateLocally();
  }

  void setPaymentTerms(String? terms) =>
      state = state.copyWith(paymentTerms: terms);

  void setNarration(String text) => state = state.copyWith(narration: text);
  void setInternalNotes(String text) =>
      state = state.copyWith(internalNotes: text);
  void setInvoiceNumber(String text) =>
      state = state.copyWith(invoiceNumber: text);
  void setBillingAddress(String text) =>
      state = state.copyWith(billingAddress: text);
  void setCustomerPhone(String text) =>
      state = state.copyWith(customerPhone: text);
  void setBillingPincode(String text) =>
      state = state.copyWith(billingPincode: text);
  void setCustomerGstin(String text) =>
      state = state.copyWith(customerGstin: text);

  void updateShippingAddress(String address) =>
      state = state.copyWith(shippingAddress: address);

  // ── Line operations ───────────────────────────────────────────────────────

  void addLine() {
    final lines = [...state.lines, const InvoiceLineForm()];
    state = state.copyWith(lines: lines);
  }

  void removeLine(int index) {
    final lines = [...state.lines]..removeAt(index);
    state = state.copyWith(lines: lines);
    _calculateLocally();
  }

  void updateLine(int index, InvoiceLineForm updated) {
    final lines = [...state.lines];
    lines[index] = updated;
    state = state.copyWith(lines: lines);
    _calculateLocally();
  }

  void setRoundOff(double value) {
    final newTotal =
        state.taxableAmount +
        state.cgstAmount +
        state.sgstAmount +
        state.igstAmount +
        value;
    state = state.copyWith(roundOff: value, totalAmount: newTotal);
  }

  // ── Tax calculation ───────────────────────────────────────────────────────

  /// Instant local GST calculation — runs synchronously for responsive UI.
  void _calculateLocally() {
    final isExport = state.invoiceType == 'export';

    // Supply Type detection: intra vs inter
    bool isInter = false;
    if (!isExport) {
      // If customer GST is null or absent, default to intra
      if (state.customerGstin.trim().isEmpty) {
        isInter = false;
      } else {
        final compState = state.companyGstin.length >= 2
            ? state.companyGstin.substring(0, 2)
            : '';
        final custState = state.placeOfSupply.length >= 2
            ? state.placeOfSupply.substring(0, 2)
            : (state.customerGstin.length >= 2
                  ? state.customerGstin.substring(0, 2)
                  : '');

        if (compState.isNotEmpty &&
            custState.isNotEmpty &&
            compState != custState) {
          isInter = true;
        }
      }
    }

    double subtotal = 0;
    double discountTotal = 0;
    double taxableTotal = 0;
    double cgstTotal = 0;
    double sgstTotal = 0;
    double igstTotal = 0;

    final updatedLines = state.lines.map((l) {
      if (l.productId == null || l.quantity <= 0) return l;
      final lineSubtotal = l.quantity * l.unitPrice;
      final discount = lineSubtotal * l.discountPct / 100;
      final taxable = lineSubtotal - discount;

      double cgst = 0, sgst = 0, igst = 0;
      if (isExport || isInter) {
        igst = taxable * l.gstRate / 100;
      } else {
        cgst = taxable * (l.gstRate / 2) / 100;
        sgst = taxable * (l.gstRate / 2) / 100;
      }

      final total = taxable + cgst + sgst + igst;
      subtotal += lineSubtotal;
      discountTotal += discount;
      taxableTotal += taxable;
      cgstTotal += cgst;
      sgstTotal += sgst;
      igstTotal += igst;
      return l.copyWith(
        taxableAmount: taxable,
        cgstAmount: cgst,
        sgstAmount: sgst,
        igstAmount: igst,
        lineTotal: total,
      );
    }).toList();

    final rawTotal = taxableTotal + cgstTotal + sgstTotal + igstTotal;
    final rounded = (rawTotal * 100).round() / 100;
    final autoRoundOff = double.parse((rounded - rawTotal).toStringAsFixed(2));
    state = state.copyWith(
      lines: updatedLines,
      subtotal: subtotal,
      discountAmount: discountTotal,
      taxableAmount: taxableTotal,
      cgstAmount: cgstTotal,
      sgstAmount: sgstTotal,
      igstAmount: igstTotal,
      roundOff: autoRoundOff,
      totalAmount: rounded,
    );
  }

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

  // ── Error helpers ─────────────────────────────────────────────────────────

  static String _extractError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        final errors = data['errors'];
        if (errors is Map) {
          return errors.values
              .expand((v) => v is List ? v.cast<String>() : [v.toString()])
              .join('\n');
        }
        final msg = data['message'];
        if (msg is String && msg.isNotEmpty) return msg;
      }
    }
    return e.toString();
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Map<String, dynamic> _buildPayload(String status) => {
    if (state.invoiceNumber.isNotEmpty) 'invoice_number': state.invoiceNumber,
    'customer_id': state.customerId,
    'customer_billing_address': state.billingAddress,
    'customer_phone': state.customerPhone,
    'customer_pincode': state.billingPincode,
    'customer_gstin': state.customerGstin,
    'invoice_date': state.invoiceDate,
    if (state.dueDate != null && state.dueDate!.isNotEmpty)
      'due_date': state.dueDate,
    'invoice_type': state.invoiceType,
    'place_of_supply': state.placeOfSupply,
    if (state.paymentTerms != null) 'payment_terms': state.paymentTerms,
    'narration': state.narration,
    'internal_notes': state.internalNotes,
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
      state = state.copyWith(isSaving: false, error: _extractError(e));
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
      state = state.copyWith(isSaving: false, error: _extractError(e));
      return null;
    }
  }
}

final invoiceFormProvider =
    StateNotifierProvider.autoDispose<InvoiceFormNotifier, InvoiceFormState>((
      ref,
    ) {
      final repo = ref.watch(salesInvoiceRepositoryProvider);
      final companyRepo = ref.watch(companySettingsRepositoryProvider);
      return InvoiceFormNotifier(repo, companyRepo);
    });
