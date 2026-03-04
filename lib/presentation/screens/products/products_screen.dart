import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/app_theme.dart';
import '../../providers/product_provider.dart';
import '../../../data/models/product_model.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: 'Rp ', decimalDigits: 0);
    final filteredProducts = ref.watch(filteredProductsProvider);
    final lowStockProducts = ref.watch(lowStockProductsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manajemen Produk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          tabs: [
            const Tab(text: 'Semua Produk'),
            Tab(text: 'Stok Rendah (${lowStockProducts.value?.length ?? 0})'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Cari produk...',
                prefixIcon: Icon(Icons.search_rounded, color: AppColors.textHint),
              ),
              onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
            ),
          ),
          const SizedBox(height: 8),
          // Category chips
          ref.watch(categoriesProvider).when(
            data: (cats) => SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _Chip(label: 'Semua', selected: ref.watch(selectedCategoryProvider) == null,
                    onTap: () => ref.read(selectedCategoryProvider.notifier).state = null),
                  ...cats.map((c) => _Chip(
                    label: '${c.icon ?? ''} ${c.name}',
                    selected: ref.watch(selectedCategoryProvider) == c.id,
                    onTap: () => ref.read(selectedCategoryProvider.notifier).state = c.id,
                  )),
                ],
              ),
            ),
            loading: () => const SizedBox(height: 34),
            error: (_, __) => const SizedBox(height: 34),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // All products
                filteredProducts.when(
                  data: (products) => products.isEmpty
                      ? const Center(child: Text('Tidak ada produk', style: TextStyle(color: AppColors.textSecondary)))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                          itemCount: products.length,
                          itemBuilder: (context, i) => _ProductListItem(
                            product: products[i],
                            formatter: formatter,
                            onEdit: () => context.go('/products/${products[i].id}/edit'),
                            onDelete: () => _confirmDelete(context, ref, products[i].id),
                          ).animate().fadeIn(delay: (i * 30).ms),
                        ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
                // Low stock
                lowStockProducts.when(
                  data: (products) => products.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_rounded, color: AppColors.success, size: 60),
                              SizedBox(height: 12),
                              Text('Semua stok aman!', style: TextStyle(color: AppColors.textSecondary)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                          itemCount: products.length,
                          itemBuilder: (context, i) => _ProductListItem(
                            product: products[i],
                            formatter: formatter,
                            onEdit: () => context.go('/products/${products[i].id}/edit'),
                            onDelete: () => _confirmDelete(context, ref, products[i].id),
                            showLowStockBadge: true,
                          ),
                        ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/products/new'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Tambah Produk', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Hapus Produk?', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('Produk ini tidak akan muncul di kasir.', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              ref.read(productNotifierProvider.notifier).deleteProduct(id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

class _ProductListItem extends StatelessWidget {
  final ProductModel product;
  final NumberFormat formatter;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool showLowStockBadge;

  const _ProductListItem({
    required this.product,
    required this.formatter,
    required this.onEdit,
    required this.onDelete,
    this.showLowStockBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: showLowStockBadge && product.isLowStock
            ? Border.all(color: AppColors.warning.withOpacity(0.4))
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(12)),
          child: product.imagePath != null
              ? CachedNetworkImage(
                  imageUrl: product.imagePath!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const Center(
                    child: SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))),
                  errorWidget: (_, __, ___) => const Icon(Icons.fastfood_rounded, color: AppColors.textHint, size: 26),
                )
              : const Icon(Icons.fastfood_rounded, color: AppColors.textHint, size: 26),
        ),
        title: Text(product.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(formatter.format(product.price), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
            Row(
              children: [
                Text('Stok: ${product.stock} ${product.unit}',
                    style: TextStyle(color: product.isLowStock ? AppColors.warning : AppColors.textHint, fontSize: 11)),
                if (product.isLowStock) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                    child: const Text('Stok Rendah', style: TextStyle(color: AppColors.warning, fontSize: 9, fontWeight: FontWeight.w600)),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          color: AppColors.surfaceElevated,
          onSelected: (value) {
            if (value == 'edit') onEdit();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 16, color: AppColors.textSecondary), SizedBox(width: 8), Text('Edit', style: TextStyle(color: AppColors.textPrimary))])),
            const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 16, color: AppColors.error), SizedBox(width: 8), Text('Hapus', style: TextStyle(color: AppColors.error))])),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: selected ? AppColors.primary : AppColors.border),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: selected ? Colors.white : AppColors.textSecondary)),
    ),
  );
}


