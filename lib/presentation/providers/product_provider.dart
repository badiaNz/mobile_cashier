import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/product_model.dart';
import '../../core/database_helper.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

// Products list provider
final productsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final db = DatabaseHelper.instance;
  final maps = await db.rawQuery('''
    SELECT p.*, c.name as category_name
    FROM products p
    LEFT JOIN categories c ON p.category_id = c.id
    WHERE p.is_active = 1
    ORDER BY p.name ASC
  ''');
  return maps.map((m) => ProductModel.fromMap(m)).toList();
});

// Categories provider
final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final db = DatabaseHelper.instance;
  final maps = await db.query('categories', orderBy: 'sort_order ASC');
  return maps.map((m) => CategoryModel.fromMap(m)).toList();
});

// Selected category filter
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

// Search query
final searchQueryProvider = StateProvider<String>((ref) => '');

// Filtered products
final filteredProductsProvider = Provider<AsyncValue<List<ProductModel>>>((ref) {
  final products = ref.watch(productsProvider);
  final category = ref.watch(selectedCategoryProvider);
  final search = ref.watch(searchQueryProvider);

  return products.whenData((list) {
    var filtered = list;
    if (category != null) {
      filtered = filtered.where((p) => p.categoryId == category).toList();
    }
    if (search.isNotEmpty) {
      final q = search.toLowerCase();
      filtered = filtered.where((p) =>
          p.name.toLowerCase().contains(q) ||
          (p.barcode?.contains(q) ?? false) ||
          (p.sku?.toLowerCase().contains(q) ?? false)).toList();
    }
    return filtered;
  });
});

// Product CRUD notifier
class ProductNotifier extends StateNotifier<AsyncValue<void>> {
  final DatabaseHelper _db;
  final Ref _ref;

  ProductNotifier(this._db, this._ref) : super(const AsyncData(null));

  Future<bool> addProduct(ProductModel product) async {
    state = const AsyncLoading();
    try {
      final now = DateTime.now().toIso8601String();
      await _db.insert('products', {
        ...product.toMap(),
        'id': _uuid.v4(),
        'created_at': now,
        'updated_at': now,
      });
      _ref.invalidate(productsProvider);
      state = const AsyncData(null);
      return true;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }

  Future<bool> updateProduct(ProductModel product) async {
    state = const AsyncLoading();
    try {
      await _db.update(
        'products',
        {...product.toMap(), 'updated_at': DateTime.now().toIso8601String()},
        'id = ?',
        [product.id],
      );
      _ref.invalidate(productsProvider);
      state = const AsyncData(null);
      return true;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }

  Future<bool> deleteProduct(String id) async {
    state = const AsyncLoading();
    try {
      await _db.update('products', {'is_active': 0}, 'id = ?', [id]);
      _ref.invalidate(productsProvider);
      state = const AsyncData(null);
      return true;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }

  Future<bool> updateStock(String productId, int newStock, {String? reason}) async {
    try {
      final products = await _db.query('products', where: 'id = ?', whereArgs: [productId]);
      if (products.isEmpty) return false;
      final current = ProductModel.fromMap(products.first);

      await _db.update('products', {'stock': newStock, 'updated_at': DateTime.now().toIso8601String()}, 'id = ?', [productId]);

      // Record stock movement
      await _db.insert('stock_movements', {
        'id': _uuid.v4(),
        'product_id': productId,
        'type': newStock > current.stock ? 'in' : 'out',
        'quantity': (newStock - current.stock).abs(),
        'before_stock': current.stock,
        'after_stock': newStock,
        'reason': reason ?? 'Manual adjustment',
        'created_at': DateTime.now().toIso8601String(),
      });

      _ref.invalidate(productsProvider);
      return true;
    } catch (e) {
      return false;
    }
  }
}

final productNotifierProvider = StateNotifierProvider<ProductNotifier, AsyncValue<void>>((ref) {
  return ProductNotifier(DatabaseHelper.instance, ref);
});

// Low stock products
final lowStockProductsProvider = Provider<AsyncValue<List<ProductModel>>>((ref) {
  return ref.watch(productsProvider).whenData(
    (list) => list.where((p) => p.isLowStock).toList(),
  );
});

// All products provider for inventory management
final allProductsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final db = DatabaseHelper.instance;
  final maps = await db.rawQuery('''
    SELECT p.*, c.name as category_name
    FROM products p
    LEFT JOIN categories c ON p.category_id = c.id
    WHERE p.is_active = 1
    ORDER BY p.name ASC
  ''');
  return maps.map((m) => ProductModel.fromMap(m)).toList();
});
