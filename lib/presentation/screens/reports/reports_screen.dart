import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../config/app_theme.dart';
import '../../../core/database_helper.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _period = 'week'; // week, month, year

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(_reportsProvider(_period));
    final formatter = NumberFormat.currency(symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Laporan Penjualan'),
        actions: [
          IconButton(icon: const Icon(Icons.file_download_outlined), onPressed: () {}),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          onTap: (i) => setState(() => _period = ['week', 'month', 'year'][i]),
          tabs: const [Tab(text: 'Minggu Ini'), Tab(text: 'Bulan Ini'), Tab(text: 'Tahun Ini')],
        ),
      ),
      body: reportsAsync.when(
        data: (data) => TabBarView(
          controller: _tabController,
          children: [
            _ReportView(data: data, formatter: formatter),
            _ReportView(data: data, formatter: formatter),
            _ReportView(data: data, formatter: formatter),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _ReportView extends StatelessWidget {
  final Map<String, dynamic> data;
  final NumberFormat formatter;

  const _ReportView({required this.data, required this.formatter});

  @override
  Widget build(BuildContext context) {
    final totalRevenue = (data['total_revenue'] as num?)?.toDouble() ?? 0;
    final transactionCount = (data['transaction_count'] as num?)?.toInt() ?? 0;
    final avgTransaction = transactionCount > 0 ? totalRevenue / transactionCount : 0.0;
    final topProducts = data['top_products'] as List? ?? [];
    final chartData = data['chart_data'] as List? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          Row(
            children: [
              Expanded(child: _SummaryCard(title: 'Total Pendapatan', value: formatter.format(totalRevenue), icon: Icons.trending_up_rounded, color: AppColors.success)),
              const SizedBox(width: 12),
              Expanded(child: _SummaryCard(title: 'Jumlah Transaksi', value: '$transactionCount', icon: Icons.receipt_rounded, color: AppColors.info)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _SummaryCard(title: 'Rata-rata Transaksi', value: formatter.format(avgTransaction), icon: Icons.analytics_rounded, color: AppColors.accentOrange)),
              const SizedBox(width: 12),
              Expanded(child: _SummaryCard(title: 'Items Terjual', value: '${data['items_sold'] ?? 0}', icon: Icons.shopping_bag_rounded, color: AppColors.secondary)),
            ],
          ),
          const SizedBox(height: 20),

          // Sales chart
          if (chartData.isNotEmpty) ...[
            const Text('Grafik Penjualan', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border, width: 0.5)),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.border, strokeWidth: 0.5),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        getTitlesWidget: (value, meta) => Text(
                          '${value.toInt() + 1}',
                          style: const TextStyle(color: AppColors.textHint, fontSize: 10),
                        ),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: chartData.asMap().entries.map((e) {
                        final value = (e.value['total'] as num?)?.toDouble() ?? 0;
                        return FlSpot(e.key.toDouble(), value);
                      }).toList(),
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 2.5,
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primary.withOpacity(0.12),
                      ),
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Top products
          if (topProducts.isNotEmpty) ...[
            const Text('Produk Terlaris', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border, width: 0.5)),
              child: Column(
                children: topProducts.take(5).toList().asMap().entries.map((e) {
                  final i = e.key;
                  final p = e.value as Map<String, dynamic>;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: i < (topProducts.length - 1).clamp(0, 4)
                          ? const Border(bottom: BorderSide(color: AppColors.border, width: 0.5))
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 30, height: 30,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(child: Text('${i + 1}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(p['product_name']?.toString() ?? '-', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500, fontSize: 13))),
                        Text('${p['total_qty'] ?? 0} terjual', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        const SizedBox(width: 10),
                        Text(formatter.format((p['total_revenue'] as num?)?.toDouble() ?? 0),
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border, width: 0.5)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 10),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 2),
        Text(title, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
      ],
    ),
  );
}

final _reportsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, period) async {
  final db = DatabaseHelper.instance;
  final now = DateTime.now();
  DateTime from;

  switch (period) {
    case 'week':
      from = now.subtract(Duration(days: now.weekday - 1));
      break;
    case 'month':
      from = DateTime(now.year, now.month, 1);
      break;
    case 'year':
      from = DateTime(now.year, 1, 1);
      break;
    default:
      from = now.subtract(const Duration(days: 7));
  }

  final fromStr = DateTime(from.year, from.month, from.day).toIso8601String();
  final toStr = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();

  final summary = await db.rawQuery('''
    SELECT COUNT(*) as transaction_count, COALESCE(SUM(total), 0) as total_revenue,
           COALESCE(SUM(discount_amount), 0) as total_discount
    FROM transactions WHERE created_at BETWEEN ? AND ? AND status = 'completed'
  ''', [fromStr, toStr]);

  final itemsSold = await db.rawQuery('''
    SELECT COALESCE(SUM(ti.quantity), 0) as items_sold
    FROM transaction_items ti
    JOIN transactions t ON ti.transaction_id = t.id
    WHERE t.created_at BETWEEN ? AND ? AND t.status = 'completed'
  ''', [fromStr, toStr]);

  final topProducts = await db.rawQuery('''
    SELECT ti.product_name, SUM(ti.quantity) as total_qty, SUM(ti.subtotal) as total_revenue
    FROM transaction_items ti
    JOIN transactions t ON ti.transaction_id = t.id
    WHERE t.created_at BETWEEN ? AND ? AND t.status = 'completed'
    GROUP BY ti.product_id ORDER BY total_revenue DESC LIMIT 5
  ''', [fromStr, toStr]);

  final chartData = await db.rawQuery('''
    SELECT DATE(created_at) as date, SUM(total) as total
    FROM transactions WHERE created_at BETWEEN ? AND ? AND status = 'completed'
    GROUP BY DATE(created_at) ORDER BY date ASC
  ''', [fromStr, toStr]);

  return {
    ...summary.first,
    ...itemsSold.first,
    'top_products': topProducts,
    'chart_data': chartData,
  };
});


