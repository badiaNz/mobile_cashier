import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final todayStats = ref.watch(todayStatsProvider);
    final lowStock = ref.watch(lowStockProductsProvider);
    final formatter = NumberFormat.currency(symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.background,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, Color(0xFF8B78ED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Selamat datang,',
                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                                Text(
                                  user?.name ?? 'Kasir',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () => context.go('/settings'),
                              child: CircleAvatar(
                                radius: 22,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                child: Text(
                                  (user?.name ?? 'A').substring(0, 1).toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formattedDate(),
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Quick action: Start POS
                GestureDetector(
                  onTap: () => context.go('/pos'),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.point_of_sale_rounded, color: Colors.white, size: 40),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Mulai Transaksi', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                            const Text('Buka kasir sekarang', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: 20),

                // Stats header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Statistik Hari Ini', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.textPrimary)),
                    TextButton(onPressed: () => context.go('/reports'), child: const Text('Lihat Semua')),
                  ],
                ),
                const SizedBox(height: 12),

                // Stats cards
                todayStats.when(
                  data: (stats) => Row(
                    children: [
                      Expanded(child: _StatCard(
                        title: 'Pendapatan',
                        value: formatter.format(stats['total_revenue'] ?? 0),
                        icon: Icons.attach_money_rounded,
                        color: AppColors.accentGreen,
                        subtitle: '${stats['transaction_count'] ?? 0} transaksi',
                      ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.3, end: 0)),
                      const SizedBox(width: 12),
                      Expanded(child: _StatCard(
                        title: 'Item Terjual',
                        value: '${stats['items_sold'] ?? 0}',
                        icon: Icons.shopping_bag_outlined,
                        color: AppColors.secondary,
                        subtitle: 'unit hari ini',
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0)),
                    ],
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const SizedBox(),
                ),
                const SizedBox(height: 12),
                todayStats.when(
                  data: (stats) {
                    final avg = (stats['avg_transaction'] as num?)?.toDouble() ?? 0;
                    final disc = (stats['total_discount'] as num?)?.toDouble() ?? 0;
                    return Row(
                      children: [
                        Expanded(child: _StatCard(
                          title: 'Rata-rata',
                          value: formatter.format(avg),
                          icon: Icons.analytics_outlined,
                          color: AppColors.accentOrange,
                          subtitle: 'per transaksi',
                        ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.3, end: 0)),
                        const SizedBox(width: 12),
                        Expanded(child: _StatCard(
                          title: 'Total Diskon',
                          value: formatter.format(disc),
                          icon: Icons.local_offer_outlined,
                          color: AppColors.accent,
                          subtitle: 'diberikan hari ini',
                        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3, end: 0)),
                      ],
                    );
                  },
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),
                const SizedBox(height: 24),

                // Quick menu grid
                const Text('Menu Cepat', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    _QuickMenuCard(icon: Icons.inventory_2_rounded, label: 'Produk', color: AppColors.primary, onTap: () => context.go('/products')),
                    _QuickMenuCard(icon: Icons.receipt_long_rounded, label: 'Transaksi', color: AppColors.secondary, onTap: () => context.go('/transactions')),
                    _QuickMenuCard(icon: Icons.people_rounded, label: 'Pelanggan', color: AppColors.accentGreen, onTap: () => context.go('/customers')),
                    _QuickMenuCard(icon: Icons.bar_chart_rounded, label: 'Laporan', color: AppColors.accentOrange, onTap: () => context.go('/reports')),
                    _QuickMenuCard(icon: Icons.person_rounded, label: 'Pegawai', color: AppColors.accentYellow, onTap: () => context.go('/employees')),
                    _QuickMenuCard(icon: Icons.local_offer_rounded, label: 'Diskon', color: AppColors.accent, onTap: () {}),
                    _QuickMenuCard(icon: Icons.warehouse_rounded, label: 'Stok', color: AppColors.info, onTap: () => context.go('/stock')),
                    _QuickMenuCard(icon: Icons.settings_rounded, label: 'Pengaturan', color: AppColors.textSecondary, onTap: () => context.go('/settings')),
                  ],
                ).animate().fadeIn(delay: 350.ms),
                const SizedBox(height: 24),

                // Low stock warning
                lowStock.when(
                  data: (products) {
                    if (products.isEmpty) return const SizedBox();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18),
                                const SizedBox(width: 6),
                                Text('Stok Hampir Habis (${products.length})', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.textPrimary)),
                              ],
                            ),
                            TextButton(onPressed: () => context.go('/products'), child: const Text('Kelola')),
                          ],
                        ),
                        ...products.take(3).map((p) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(p.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('${p.stock} ${p.unit}', style: const TextStyle(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ).animate().fadeIn(delay: 400.ms);
                  },
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
        ],
      ),
    );
  }
}

class _QuickMenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickMenuCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

String _formattedDate() {
  final now = DateTime.now();
  const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
  final dayName = days[now.weekday - 1];
  final monthName = months[now.month - 1];
  return '$dayName, ${now.day} $monthName ${now.year}';
}

