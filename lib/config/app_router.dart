import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/pin_screen.dart';
import '../presentation/screens/dashboard/dashboard_screen.dart';
import '../presentation/screens/pos/pos_screen.dart';
import '../presentation/screens/products/products_screen.dart';
import '../presentation/screens/products/product_form_screen.dart';
import '../presentation/screens/transactions/transactions_screen.dart';
import '../presentation/screens/transactions/transaction_detail_screen.dart';
import '../presentation/screens/reports/reports_screen.dart';
import '../presentation/screens/customers/customers_screen.dart';
import '../presentation/screens/employees/employees_screen.dart';
import '../presentation/screens/settings/settings_screen.dart';
import '../presentation/screens/main_shell_screen.dart';
import '../presentation/screens/inventory/stock_screen.dart';
import '../presentation/screens/pos/barcode_scanner_screen.dart';
import '../presentation/providers/auth_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isLoginRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/pin';

      if (!isAuthenticated && !isLoginRoute) return '/login';
      if (isAuthenticated && isLoginRoute) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/pin',
        name: 'pin',
        builder: (context, state) => const PinScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/pos',
            name: 'pos',
            builder: (context, state) => const PosScreen(),
          ),
          GoRoute(
            path: '/products',
            name: 'products',
            builder: (context, state) => const ProductsScreen(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'product-new',
                builder: (context, state) => const ProductFormScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                name: 'product-edit',
                builder: (context, state) =>
                    ProductFormScreen(productId: state.pathParameters['id']),
              ),
            ],
          ),
          GoRoute(
            path: '/transactions',
            name: 'transactions',
            builder: (context, state) => const TransactionsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                name: 'transaction-detail',
                builder: (context, state) => TransactionDetailScreen(
                    transactionId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/reports',
            name: 'reports',
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: '/customers',
            name: 'customers',
            builder: (context, state) => const CustomersScreen(),
          ),
          GoRoute(
            path: '/employees',
            name: 'employees',
            builder: (context, state) => const EmployeesScreen(),
          ),
          GoRoute(
            path: '/stock',
            name: 'stock',
            builder: (context, state) => const StockScreen(),
          ),
          GoRoute(
            path: '/scanner',
            name: 'scanner',
            builder: (context, state) => const BarcodeScannerScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
});
