import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// Auth
import '../features/auth/screens/login_screen.dart';

// Masters
import '../features/customers/screens/customer_list_screen.dart';
import '../features/customers/screens/customer_form_screen.dart';
import '../features/vendors/screens/vendor_list_screen.dart';
import '../features/vendors/screens/vendor_form_screen.dart';
import '../features/products/screens/product_list_screen.dart';
import '../features/products/screens/product_form_screen.dart';
import '../features/products/screens/inventory_movements_screen.dart';
import '../features/products/screens/stock_summary_screen.dart';

// Sales
import '../features/sales_invoice/screens/sales_invoice_list_screen.dart';
import '../features/sales_invoice/screens/sales_invoice_form_screen.dart';
import '../features/sales_invoice/screens/sales_invoice_pdf_screen.dart';
import '../features/quotations/screens/quotation_list_screen.dart';
import '../features/quotations/screens/quotation_form_screen.dart';
import '../features/quotations/screens/quotation_detail_screen.dart';
import '../features/delivery_challans/screens/delivery_challan_list_screen.dart';
import '../features/delivery_challans/screens/delivery_challan_form_screen.dart';
import '../features/credit_notes/screens/credit_note_list_screen.dart';
import '../features/credit_notes/screens/credit_note_form_screen.dart';

// Purchases
import '../features/purchase_invoice/screens/purchase_invoice_list_screen.dart';
import '../features/purchase_invoice/screens/purchase_invoice_form_screen.dart';
import '../features/purchase_orders/screens/purchase_order_list_screen.dart';
import '../features/purchase_orders/screens/purchase_order_form_screen.dart';
import '../features/debit_notes/screens/debit_note_list_screen.dart';
import '../features/debit_notes/screens/debit_note_form_screen.dart';

// Finance
import '../features/receipts/screens/receipt_list_screen.dart';
import '../features/receipts/screens/receipt_form_screen.dart';
import '../features/payments/screens/payment_list_screen.dart';
import '../features/payments/screens/payment_form_screen.dart';
import '../features/expenses/screens/expense_list_screen.dart';
import '../features/expenses/screens/expense_form_screen.dart';

// Reports
import '../features/reports/screens/gstr1_screen.dart';
import '../features/reports/screens/gstr3b_screen.dart';
import '../features/reports/screens/tax_register_screen.dart';
import '../features/reports/screens/itc_register_screen.dart';
import '../features/reports/screens/trial_balance_screen.dart';
import '../features/reports/screens/profit_loss_screen.dart';
import '../features/reports/screens/balance_sheet_screen.dart';
import '../features/reports/screens/day_book_screen.dart';
import '../features/reports/screens/aging_report_screen.dart';

// Admin
import '../features/admin/screens/company_settings_screen.dart';
import '../features/admin/screens/users_screen.dart';
import '../features/admin/screens/bank_accounts_screen.dart';
import '../features/admin/screens/numbering_sequences_screen.dart';
import '../features/admin/screens/pdf_templates_screen.dart';
import '../features/admin/screens/backup_screen.dart';
import '../features/admin/screens/activity_log_screen.dart';

// Shared
import '../shared/widgets/app_scaffold.dart';

part 'routes.g.dart';

@riverpod
GoRouter router(RouterRef ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      ShellRoute(
        // Each screen manages its own AppScaffold with the sidebar.
        // The shell just groups authenticated routes together.
        builder: (context, state, child) => child,
        routes: [
          // ── DASHBOARD ───────────────────────────────────────────────────
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const _DashboardScreen(),
          ),

          // ── MASTERS ─────────────────────────────────────────────────────
          GoRoute(
            path: '/customers',
            builder: (context, state) => const CustomerListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const CustomerFormScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                builder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return CustomerFormScreen(customerId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/vendors',
            builder: (context, state) => const VendorListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const VendorFormScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                builder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return VendorFormScreen(vendorId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/products',
            builder: (context, state) => const ProductListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const ProductFormScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                builder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return ProductFormScreen(productId: id);
                },
              ),
              GoRoute(
                path: ':id/movements',
                builder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return InventoryMovementsScreen(productId: id);
                },
              ),
              GoRoute(
                path: ':id/stock',
                builder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  final name = state.uri.queryParameters['name'] ?? '';
                  return StockSummaryScreen(productId: id, productName: name);
                },
              ),
            ],
          ),

          // ── SALES ───────────────────────────────────────────────────────
          GoRoute(
            path: '/invoices',
            builder: (context, state) => const SalesInvoiceListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const SalesInvoiceFormScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return SalesInvoiceFormScreen(invoiceId: id);
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) {
                      final id = int.parse(state.pathParameters['id']!);
                      return SalesInvoiceFormScreen(invoiceId: id);
                    },
                  ),
                  GoRoute(
                    path: 'pdf',
                    builder: (context, state) {
                      final id = int.parse(state.pathParameters['id']!);
                      return SalesInvoicePdfScreen(invoiceId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/quotations',
            builder: (context, state) => const QuotationListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const QuotationFormScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return QuotationDetailScreen(quotationId: id);
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) {
                      final id = int.parse(state.pathParameters['id']!);
                      return QuotationFormScreen(quotationId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/delivery-challans',
            builder: (context, state) => const DeliveryChallanListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const DeliveryChallanFormScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                builder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return DeliveryChallanFormScreen(challanId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/credit-notes',
            builder: (context, state) => const CreditNoteListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const CreditNoteFormScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                builder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return CreditNoteFormScreen(noteId: id);
                },
              ),
            ],
          ),

          // ── PURCHASES ───────────────────────────────────────────────────
          GoRoute(
            path: '/purchase-invoices',
            builder: (context, state) => const PurchaseInvoiceListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const PurchaseInvoiceFormScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                builder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return PurchaseInvoiceFormScreen(invoiceId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/purchase-orders',
            builder: (context, state) => const PurchaseOrderListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const PurchaseOrderFormScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                builder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return PurchaseOrderFormScreen(orderId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/debit-notes',
            builder: (context, state) => const DebitNoteListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const DebitNoteFormScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                builder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return DebitNoteFormScreen(noteId: id);
                },
              ),
            ],
          ),

          // ── FINANCE ─────────────────────────────────────────────────────
          GoRoute(
            path: '/receipts',
            builder: (context, state) => const ReceiptListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const ReceiptFormScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                builder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return ReceiptFormScreen(receiptId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/payments',
            builder: (context, state) => const PaymentListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const PaymentFormScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                builder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return PaymentFormScreen(paymentId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/expenses',
            builder: (context, state) => const ExpenseListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const ExpenseFormScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                builder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return ExpenseFormScreen(expenseId: id);
                },
              ),
            ],
          ),

          // ── GST REPORTS ─────────────────────────────────────────────────
          GoRoute(
            path: '/reports/gstr1',
            builder: (context, state) => const Gstr1Screen(),
          ),
          GoRoute(
            path: '/reports/gstr3b',
            builder: (context, state) => const Gstr3bScreen(),
          ),
          GoRoute(
            path: '/reports/tax-register',
            builder: (context, state) => const TaxRegisterScreen(),
          ),
          GoRoute(
            path: '/reports/purchase-tax-register',
            builder: (context, state) =>
                const TaxRegisterScreen(isSales: false),
          ),
          GoRoute(
            path: '/reports/itc-register',
            builder: (context, state) => const ItcRegisterScreen(),
          ),

          // ── FINANCIAL REPORTS ────────────────────────────────────────────
          GoRoute(
            path: '/reports/trial-balance',
            builder: (context, state) => const TrialBalanceScreen(),
          ),
          GoRoute(
            path: '/reports/profit-loss',
            builder: (context, state) => const ProfitLossScreen(),
          ),
          GoRoute(
            path: '/reports/balance-sheet',
            builder: (context, state) => const BalanceSheetScreen(),
          ),
          GoRoute(
            path: '/reports/day-book',
            builder: (context, state) => const DayBookScreen(),
          ),
          GoRoute(
            path: '/reports/cash-book',
            builder: (context, state) => const CashBookScreen(),
          ),
          GoRoute(
            path: '/reports/aging',
            builder: (context, state) => const AgingReportScreen(),
          ),

          // ── ADMIN ───────────────────────────────────────────────────────
          GoRoute(
            path: '/admin/company-settings',
            builder: (context, state) => const CompanySettingsScreen(),
          ),
          GoRoute(
            path: '/admin/users',
            builder: (context, state) => const UsersScreen(),
          ),
          GoRoute(
            path: '/admin/bank-accounts',
            builder: (context, state) => const BankAccountsScreen(),
          ),
          GoRoute(
            path: '/admin/numbering-sequences',
            builder: (context, state) => const NumberingSequencesScreen(),
          ),
          GoRoute(
            path: '/admin/pdf-templates',
            builder: (context, state) => const PdfTemplatesScreen(),
          ),
          GoRoute(
            path: '/admin/backups',
            builder: (context, state) => const BackupScreen(),
          ),
          GoRoute(
            path: '/admin/activity-log',
            builder: (context, state) => const ActivityLogScreen(),
          ),
        ],
      ),
    ],
  );
}

class _DashboardScreen extends StatelessWidget {
  const _DashboardScreen();

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Dashboard',
      body: Center(child: Text('Dashboard — Coming Soon')),
    );
  }
}
