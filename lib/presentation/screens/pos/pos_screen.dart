import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:badges/badges.dart' as badges;
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/app_theme.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../../data/models/product_model.dart';
import 'package:go_router/go_router.dart';
import 'checkout_sheet.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final filteredProducts = ref.watch(filteredProductsProvider);
    final categories = ref.watch(categoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final formatter = NumberFormat.currency(symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kasir'),
        actions: [
          badges.Badge(
            showBadge: cart.itemCount > 0,
            badgeContent: Text('${cart.itemCount}', style: const TextStyle(color: Colors.white, fontSize: 10)),
            badgeStyle: const badges.BadgeStyle(badgeColor: AppColors.accent),
            child: IconButton(
              icon: const Icon(Icons.shopping_cart_rounded),
              onPressed: cart.items.isEmpty ? null : () => _showCartSheet(context),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Cari produk atau scan barcode...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textHint),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
                  onPressed: () async {
                    final code = await GoRouter.of(context).push<String>('/scanner');
                    if (code != null && mounted) {
                      final products = await ref.read(productsProvider.future);
                      final product = products.where((p) => p.barcode == code || p.sku == code).firstOrNull;
                      
                      if (product != null) {
                        ref.read(cartProvider.notifier).addItem(product);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Ditambahkan: ${product.name}'),
                              duration: const Duration(seconds: 1),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Produk tidak ditemukan!'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    }
                  },
                ),
              ),
              onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
            ),
          ),
          const SizedBox(height: 12),

          // Category filter
          categories.when(
            data: (cats) => SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _CategoryChip(label: 'Semua', selected: selectedCategory == null, onTap: () => ref.read(selectedCategoryProvider.notifier).state = null),
                  ...cats.map((c) => _CategoryChip(
                    label: '${c.icon ?? ''} ${c.name}',
                    selected: selectedCategory == c.id,
                    onTap: () => ref.read(selectedCategoryProvider.notifier).state = c.id,
                  )),
                ],
              ),
            ),
            loading: () => const SizedBox(height: 38),
            error: (_, __) => const SizedBox(height: 38),
          ),
          const SizedBox(height: 12),

          // Products grid + bottom cart bar stacked
          Expanded(
            child: Stack(
              children: [
                // Products grid
                filteredProducts.when(
                  data: (products) {
                    if (products.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded, size: 60, color: AppColors.textHint),
                            SizedBox(height: 12),
                            Text('Produk tidak ditemukan', style: TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      );
                    }
                    return GridView.builder(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, cart.items.isEmpty ? 20 : 90),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.82,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, i) {
                        final product = products[i];
                        final cartItem = cart.items.where((item) => item.productId == product.id).firstOrNull;
                        return _ProductCard(
                          product: product,
                          cartQuantity: cartItem?.quantity ?? 0,
                          formatter: formatter,
                          onAdd: () => ref.read(cartProvider.notifier).addItem(product),
                          onRemove: () {
                            if (cartItem != null) {
                              ref.read(cartProvider.notifier).updateQuantity(product.id, cartItem.quantity - 1);
                            }
                          },
                        ).animate().fadeIn(delay: (i * 30).ms);
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),

                // Bottom cart bar — pinned at bottom with auto height
                if (cart.items.isNotEmpty)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: () => _showCartSheet(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: const BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, -3))],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('${cart.itemCount} item', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            ),
                            const Spacer(),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Total', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                Text(formatter.format(cart.total), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                              ],
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCartSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CheckoutSheet(),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final int cartQuantity;
  final NumberFormat formatter;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _ProductCard({
    required this.product,
    required this.cartQuantity,
    required this.formatter,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isInCart = cartQuantity > 0;
    final isOutOfStock = product.trackStock && product.stock <= 0;

    return GestureDetector(
      onTap: isOutOfStock ? null : onAdd,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isInCart ? AppColors.primary.withOpacity(0.12) : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isInCart ? AppColors.primary.withOpacity(0.5) : AppColors.border,
            width: isInCart ? 1.5 : 0.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image
              Expanded(
                child: Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: product.imagePath != null
                        ? CachedNetworkImage(
                            imageUrl: product.imagePath!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const Center(
                              child: SizedBox(width: 22, height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))),
                            errorWidget: (_, __, ___) => const Icon(Icons.fastfood_rounded, color: AppColors.textHint, size: 36),
                          )
                        : const Icon(Icons.fastfood_rounded, color: AppColors.textHint, size: 36),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              if (product.trackStock)
                Text(
                  'Stok: ${product.stock} ${product.unit}',
                  style: TextStyle(
                    fontSize: 10,
                    color: product.isLowStock ? AppColors.warning : AppColors.textHint,
                  ),
                ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      formatter.format(product.price),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (isInCart)
                    Row(
                      children: [
                        GestureDetector(
                          onTap: onRemove,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.remove_rounded, size: 14, color: AppColors.accent),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text('$cartQuantity', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 12)),
                        ),
                        GestureDetector(
                          onTap: onAdd,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.add_rounded, size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    )
                  else
                    GestureDetector(
                      onTap: isOutOfStock ? null : onAdd,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isOutOfStock ? AppColors.border : AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          size: 18,
                          color: isOutOfStock ? AppColors.textHint : Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
