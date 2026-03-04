import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../providers/auth_provider.dart';

class MainShellScreen extends ConsumerWidget {
  final Widget child;
  const MainShellScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;

    int selectedIndex = 0;
    if (location.startsWith('/dashboard')) selectedIndex = 0;
    else if (location.startsWith('/pos')) selectedIndex = 1;
    else if (location.startsWith('/products')) selectedIndex = 2;
    else if (location.startsWith('/transactions')) selectedIndex = 3;
    else if (location.startsWith('/reports')) selectedIndex = 4;
    else if (location.startsWith('/customers')) selectedIndex = 5;
    else if (location.startsWith('/settings')) selectedIndex = 6;

    final user = ref.watch(currentUserProvider);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: Icons.dashboard_rounded, label: 'Beranda', index: 0, selected: selectedIndex, onTap: () => context.go('/dashboard')),
                _NavItem(icon: Icons.point_of_sale_rounded, label: 'Kasir', index: 1, selected: selectedIndex, onTap: () => context.go('/pos')),
                _NavItem(icon: Icons.inventory_2_rounded, label: 'Produk', index: 2, selected: selectedIndex, onTap: () => context.go('/products')),
                _NavItem(icon: Icons.receipt_long_rounded, label: 'Transaksi', index: 3, selected: selectedIndex, onTap: () => context.go('/transactions')),
                _NavItem(icon: Icons.bar_chart_rounded, label: 'Laporan', index: 4, selected: selectedIndex, onTap: () => context.go('/reports')),
                if (user?.isManager == true)
                  _NavItem(icon: Icons.people_rounded, label: 'Pelanggan', index: 5, selected: selectedIndex, onTap: () => context.go('/customers')),
                _NavItem(icon: Icons.settings_rounded, label: 'Pengaturan', index: 6, selected: selectedIndex, onTap: () => context.go('/settings')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == index;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textHint,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.primary : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
