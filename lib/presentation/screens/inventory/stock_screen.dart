import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/app_theme.dart';
import '../../../core/database_helper.dart';
import '../../../data/models/product_model.dart';
import '../../providers/product_provider.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

// Provider untuk stock movements
final stockMovementsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final db = DatabaseHelper.instance;
  return await db.rawQuery('''
    SELECT sm.*, p.name as product_name
    FROM stock_movements sm
    LEFT JOIN products p ON sm.product_id = p.id
    ORDER BY sm.created_at DESC
    LIMIT 100
  ''');
});

class StockScreen extends ConsumerStatefulWidget {
  const StockScreen({super.key});

  @override
  ConsumerState<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends ConsumerState<StockScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manajemen Stok'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          tabs: const [
            Tab(text: 'Stok Produk'),
            Tab(text: 'Riwayat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _StockListTab(onRefresh: () {
            ref.invalidate(allProductsProvider);
          }),
          _StockHistoryTab(),
        ],
      ),
    );
  }
}

class _StockListTab extends ConsumerWidget {
  final VoidCallback onRefresh;
  const _StockListTab({required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(allProductsProvider);

    return productsAsync.when(
      data: (products) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(allProductsProvider);
        },
        color: AppColors.primary,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: products.length,
          itemBuilder: (context, i) {
            final p = products[i];
            return _StockCard(
              product: p,
              onAdjust: () => _showAdjustDialog(context, ref, p),
            ).animate().fadeIn(delay: (i * 20).ms);
          },
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  void _showAdjustDialog(BuildContext context, WidgetRef ref, ProductModel product) {
    final controller = TextEditingController();
    String type = 'in'; // 'in' or 'out'
    String reason = 'Penyesuaian stok';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Sesuaikan Stok - ${product.name}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Stok Saat Ini', style: TextStyle(color: AppColors.textHint, fontSize: 13)),
                    Text('${product.stock} ${product.unit}',
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Type toggle
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setDialogState(() => type = 'in'),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: type == 'in' ? AppColors.success.withOpacity(0.2) : AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: type == 'in' ? AppColors.success : AppColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle_outline, size: 16, color: type == 'in' ? AppColors.success : AppColors.textHint),
                            const SizedBox(width: 6),
                            Text('Tambah', style: TextStyle(color: type == 'in' ? AppColors.success : AppColors.textHint, fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setDialogState(() => type = 'out'),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: type == 'out' ? AppColors.error.withOpacity(0.2) : AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: type == 'out' ? AppColors.error : AppColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.remove_circle_outline, size: 16, color: type == 'out' ? AppColors.error : AppColors.textHint),
                            const SizedBox(width: 6),
                            Text('Kurangi', style: TextStyle(color: type == 'out' ? AppColors.error : AppColors.textHint, fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Jumlah', prefixIcon: Icon(Icons.inventory_2_outlined, color: AppColors.textHint)),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: reason,
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                decoration: const InputDecoration(labelText: 'Keterangan'),
                items: const [
                  DropdownMenuItem(value: 'Penyesuaian stok', child: Text('Penyesuaian stok')),
                  DropdownMenuItem(value: 'Stok opname', child: Text('Stok opname')),
                  DropdownMenuItem(value: 'Barang rusak', child: Text('Barang rusak')),
                  DropdownMenuItem(value: 'Barang kadaluarsa', child: Text('Barang kadaluarsa')),
                  DropdownMenuItem(value: 'Pembelian', child: Text('Pembelian')),
                  DropdownMenuItem(value: 'Retur', child: Text('Retur')),
                ],
                onChanged: (v) => reason = v ?? reason,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                final qty = int.tryParse(controller.text) ?? 0;
                if (qty <= 0) return;
                final db = DatabaseHelper.instance;
                final now = DateTime.now();
                final adjustedQty = type == 'in' ? qty : -qty;
                final newStock = (product.stock + adjustedQty).clamp(0, 99999);

                await db.rawUpdate(
                  'UPDATE products SET stock = ?, updated_at = ? WHERE id = ?',
                  [newStock, now.toIso8601String(), product.id],
                );
                await db.insert('stock_movements', {
                  'id': _uuid.v4(),
                  'product_id': product.id,
                  'type': type == 'in' ? 'adjustment_in' : 'adjustment_out',
                  'quantity': adjustedQty,
                  'before_stock': product.stock,
                  'after_stock': newStock,
                  'reason': reason,
                  'created_at': now.toIso8601String(),
                });

                if (ctx.mounted) Navigator.pop(ctx);
                ref.invalidate(allProductsProvider);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onAdjust;
  const _StockCard({required this.product, required this.onAdjust});

  @override
  Widget build(BuildContext context) {
    final isLow = product.isLowStock;
    final stockPercent = product.minStock > 0
        ? (product.stock / (product.minStock * 3)).clamp(0.0, 1.0)
        : 1.0;
    final stockColor = isLow ? AppColors.error : product.stock < product.minStock * 2 ? AppColors.warning : AppColors.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isLow ? AppColors.error.withOpacity(0.4) : AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: stockColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.inventory_2_rounded, color: stockColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(product.categoryName ?? 'Uncategorized', style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${product.stock}', style: TextStyle(color: stockColor, fontWeight: FontWeight.w700, fontSize: 18)),
                  Text(product.unit, style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
                ],
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onAdjust,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.edit_rounded, color: AppColors.primary, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: stockPercent,
                    backgroundColor: AppColors.surfaceElevated,
                    color: stockColor,
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text('Min: ${product.minStock}', style: const TextStyle(color: AppColors.textHint, fontSize: 10)),
            ],
          ),
          if (isLow) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 14),
                const SizedBox(width: 4),
                Text('Stok menipis! Segera restok', style: const TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StockHistoryTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movementsAsync = ref.watch(stockMovementsProvider);
    return movementsAsync.when(
      data: (movements) {
        if (movements.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_rounded, size: 60, color: AppColors.textHint),
                SizedBox(height: 12),
                Text('Belum ada riwayat pergerakan stok', style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: movements.length,
          itemBuilder: (context, i) {
            final m = movements[i];
            final qty = (m['quantity'] as int?) ?? 0;
            final isIn = qty > 0;
            final type = m['type']?.toString() ?? '';
            final typeLabel = {
              'sale': '🛒 Penjualan',
              'adjustment_in': '➕ Tambah Stok',
              'adjustment_out': '➖ Kurangi Stok',
              'return': '↩️ Retur',
              'purchase': '📦 Pembelian',
            }[type] ?? type;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 0.3),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: isIn ? AppColors.success.withOpacity(0.15) : AppColors.error.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isIn ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                      color: isIn ? AppColors.success : AppColors.error, size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m['product_name']?.toString() ?? '-',
                          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                        Text(typeLabel, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                        Text(m['reason']?.toString() ?? '',
                          style: const TextStyle(color: AppColors.textHint, fontSize: 10)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isIn ? '+' : ''}$qty',
                        style: TextStyle(color: isIn ? AppColors.success : AppColors.error, fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      Text(
                        '${m['before_stock']} → ${m['after_stock']}',
                        style: const TextStyle(color: AppColors.textHint, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(delay: (i * 15).ms);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
