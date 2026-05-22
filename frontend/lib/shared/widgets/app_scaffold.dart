import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_notifier.dart';

class AppScaffold extends ConsumerWidget {
  final Widget? child;
  final String? title;
  final Widget? body;
  final Widget? floatingActionButton;
  final List<Widget>? actions;

  const AppScaffold({
    super.key,
    this.child,
    this.title,
    this.body,
    this.floatingActionButton,
    this.actions,
  }) : assert(
         child != null || body != null,
         'AppScaffold requires either child or body',
       );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Widget content = body != null
        ? Scaffold(
            appBar: title != null
                ? AppBar(title: Text(title!), actions: actions)
                : null,
            body: body!,
            floatingActionButton: floatingActionButton,
          )
        : child!;

    return Scaffold(
      body: Row(
        children: [
          ExcludeFocusTraversal(
            child: SizedBox(
              width: 220,
              child: ListView(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 28, 16, 16),
                    child: Text(
                      'Hexbase Retail',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(),
                  _NavItem(
                    icon: Icons.dashboard,
                    label: 'Dashboard',
                    route: '/dashboard',
                  ),
                  _SectionHeader('SALES'),
                  _NavItem(
                    icon: Icons.receipt_long,
                    label: 'Sales Invoices',
                    route: '/invoices',
                  ),
                  _NavItem(
                    icon: Icons.request_quote,
                    label: 'Quotations',
                    route: '/quotations',
                  ),
                  _NavItem(
                    icon: Icons.local_shipping,
                    label: 'Delivery Challans',
                    route: '/delivery-challans',
                  ),
                  _NavItem(
                    icon: Icons.note_alt,
                    label: 'Credit Notes',
                    route: '/credit-notes',
                  ),
                  _SectionHeader('PURCHASES'),
                  _NavItem(
                    icon: Icons.shopping_cart,
                    label: 'Purchase Invoices',
                    route: '/purchase-invoices',
                  ),
                  _NavItem(
                    icon: Icons.list_alt,
                    label: 'Purchase Orders',
                    route: '/purchase-orders',
                  ),
                  _NavItem(
                    icon: Icons.note_alt_outlined,
                    label: 'Debit Notes',
                    route: '/debit-notes',
                  ),
                  _SectionHeader('FINANCE'),
                  _NavItem(
                    icon: Icons.payments,
                    label: 'Receipts',
                    route: '/receipts',
                  ),
                  _NavItem(
                    icon: Icons.payment,
                    label: 'Payments',
                    route: '/payments',
                  ),
                  _NavItem(
                    icon: Icons.money_off,
                    label: 'Expenses',
                    route: '/expenses',
                  ),
                  _SectionHeader('MASTERS'),
                  _NavItem(
                    icon: Icons.people,
                    label: 'Customers',
                    route: '/customers',
                  ),
                  _NavItem(
                    icon: Icons.store,
                    label: 'Vendors',
                    route: '/vendors',
                  ),
                  _NavItem(
                    icon: Icons.inventory_2,
                    label: 'Products',
                    route: '/products',
                  ),
                  _SectionHeader('GST REPORTS'),
                  _NavItem(
                    icon: Icons.bar_chart,
                    label: 'GSTR-1',
                    route: '/reports/gstr1',
                  ),
                  _NavItem(
                    icon: Icons.summarize,
                    label: 'GSTR-3B',
                    route: '/reports/gstr3b',
                  ),
                  _NavItem(
                    icon: Icons.receipt,
                    label: 'Tax Register',
                    route: '/reports/tax-register',
                  ),
                  _NavItem(
                    icon: Icons.account_balance_wallet,
                    label: 'ITC Register',
                    route: '/reports/itc-register',
                  ),
                  _SectionHeader('FINANCIAL REPORTS'),
                  _NavItem(
                    icon: Icons.balance,
                    label: 'Trial Balance',
                    route: '/reports/trial-balance',
                  ),
                  _NavItem(
                    icon: Icons.trending_up,
                    label: 'Profit & Loss',
                    route: '/reports/profit-loss',
                  ),
                  _NavItem(
                    icon: Icons.assessment,
                    label: 'Balance Sheet',
                    route: '/reports/balance-sheet',
                  ),
                  _NavItem(
                    icon: Icons.book,
                    label: 'Day Book',
                    route: '/reports/day-book',
                  ),
                  _NavItem(
                    icon: Icons.savings,
                    label: 'Cash Book',
                    route: '/reports/cash-book',
                  ),
                  _NavItem(
                    icon: Icons.hourglass_bottom,
                    label: 'Aging Report',
                    route: '/reports/aging',
                  ),
                  _SectionHeader('ADMIN'),
                  _NavItem(
                    icon: Icons.business,
                    label: 'Company Settings',
                    route: '/admin/company-settings',
                  ),
                  _NavItem(
                    icon: Icons.group,
                    label: 'Users',
                    route: '/admin/users',
                  ),
                  _NavItem(
                    icon: Icons.account_balance,
                    label: 'Bank Accounts',
                    route: '/admin/bank-accounts',
                  ),
                  _NavItem(
                    icon: Icons.format_list_numbered,
                    label: 'Numbering',
                    route: '/admin/numbering-sequences',
                  ),
                  _NavItem(
                    icon: Icons.picture_as_pdf,
                    label: 'PDF Templates',
                    route: '/admin/pdf-templates',
                  ),
                  _NavItem(
                    icon: Icons.backup,
                    label: 'Backups',
                    route: '/admin/backups',
                  ),
                  _NavItem(
                    icon: Icons.history,
                    label: 'Activity Log',
                    route: '/admin/activity-log',
                  ),
                  const Divider(),
                  _LogoutButton(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: content),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final selected = location.startsWith(route);

    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      selected: selected,
      dense: true,
      onTap: () => context.go(route),
    );
  }
}

class _LogoutButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.logout, color: Colors.red),
      title: const Text('Logout', style: TextStyle(color: Colors.red)),
      dense: true,
      onTap: () async {
        await ref.read(authNotifierProvider.notifier).logout();
        if (context.mounted) {
          context.go('/login');
        }
      },
    );
  }
}
