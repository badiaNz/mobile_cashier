import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/product_model.dart';
import '../../core/database_helper.dart';
import 'auth_provider.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

// Cart State
class CartState {
  final List<CartItem> items;
  final String? customerId;
  final String? customerName;
  final DiscountType discountType;
  final double discountValue;
  final double taxPercentage;
  final PaymentMethod paymentMethod;
  final String? notes;

  const CartState({
    this.items = const [],
    this.customerId,
    this.customerName,
    this.discountType = DiscountType.none,
    this.discountValue = 0,
    this.taxPercentage = 11.0,
    this.paymentMethod = PaymentMethod.cash,
    this.notes,
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.subtotal);

  double get discountAmount {
    if (discountType == DiscountType.none) return 0;
    if (discountType == DiscountType.percentage) return subtotal * discountValue / 100;
    return discountValue;
  }

  double get afterDiscount => subtotal - discountAmount;

  double get taxAmount => afterDiscount * taxPercentage / 100;

  double get total {
    final raw = afterDiscount + taxAmount;
    // Round to nearest 500
    return (raw / 500).round() * 500.0;
  }

  double get rounding => total - (afterDiscount + taxAmount);

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  CartState copyWith({
    List<CartItem>? items,
    String? customerId,
    String? customerName,
    DiscountType? discountType,
    double? discountValue,
    double? taxPercentage,
    PaymentMethod? paymentMethod,
    String? notes,
  }) {
    return CartState(
      items: items ?? this.items,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      taxPercentage: taxPercentage ?? this.taxPercentage,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
    );
  }

  CartState clearCustomer() => CartState(
    items: items,
    discountType: discountType,
    discountValue: discountValue,
    taxPercentage: taxPercentage,
    paymentMethod: paymentMethod,
    notes: notes,
  );

  CartState clearDiscount() => CartState(
    items: items,
    customerId: customerId,
    customerName: customerName,
    taxPercentage: taxPercentage,
    paymentMethod: paymentMethod,
    notes: notes,
  );
}

class CartNotifier extends StateNotifier<CartState> {
  final DatabaseHelper _db;
  final Ref _ref;

  CartNotifier(this._db, this._ref) : super(const CartState());

  void addItem(ProductModel product, {int quantity = 1}) {
    final existingIndex = state.items.indexWhere((i) => i.productId == product.id);
    if (existingIndex >= 0) {
      final updated = List<CartItem>.from(state.items);
      final existing = updated[existingIndex];
      updated[existingIndex] = existing.copyWith(quantity: existing.quantity + quantity);
      state = state.copyWith(items: updated);
    } else {
      state = state.copyWith(
        items: [...state.items, CartItem(
          productId: product.id,
          productName: product.name,
          price: product.price,
          quantity: quantity,
        )],
      );
    }
  }

  void removeItem(String productId) {
    state = state.copyWith(
      items: state.items.where((i) => i.productId != productId).toList(),
    );
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    final updated = state.items.map((item) {
      if (item.productId == productId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();
    state = state.copyWith(items: updated);
  }

  void setItemDiscount(String productId, double discountPercentage) {
    final updated = state.items.map((item) {
      if (item.productId == productId) {
        return item.copyWith(discountPercentage: discountPercentage);
      }
      return item;
    }).toList();
    state = state.copyWith(items: updated);
  }

  void setDiscount(DiscountType type, double value) {
    state = state.copyWith(discountType: type, discountValue: value);
  }

  void setCustomer(String? id, String? name) {
    if (id == null) {
      state = state.clearCustomer();
    } else {
      state = state.copyWith(customerId: id, customerName: name);
    }
  }

  void setPaymentMethod(PaymentMethod method) {
    state = state.copyWith(paymentMethod: method);
  }

  void clearCart() {
    state = const CartState();
  }

  Future<TransactionModel?> checkout(double amountPaid) async {
    if (state.items.isEmpty) return null;
    final user = _ref.read(currentUserProvider);
    if (user == null) return null;

    try {
      final now = DateTime.now();
      final invoiceNumber = 'INV${now.millisecondsSinceEpoch}';
      final transactionId = _uuid.v4();

      final transaction = TransactionModel(
        id: transactionId,
        invoiceNumber: invoiceNumber,
        cashierId: user.id,
        customerId: state.customerId,
        items: state.items.map((item) => TransactionItem(
          id: _uuid.v4(),
          transactionId: transactionId,
          productId: item.productId,
          productName: item.productName,
          productPrice: item.price,
          quantity: item.quantity,
          discountPercentage: item.discountPercentage,
          subtotal: item.subtotal,
        )).toList(),
        subtotal: state.subtotal,
        discountType: state.discountType,
        discountValue: state.discountValue,
        discountAmount: state.discountAmount,
        taxPercentage: state.taxPercentage,
        taxAmount: state.taxAmount,
        rounding: state.rounding,
        total: state.total,
        paymentMethod: state.paymentMethod,
        amountPaid: amountPaid,
        changeAmount: amountPaid - state.total,
        status: TransactionStatus.completed,
        notes: state.notes,
        createdAt: now,
      );

      // Save to DB
      await _db.insert('transactions', transaction.toMap());
      for (final item in transaction.items) {
        await _db.insert('transaction_items', item.toMap());
      }

      // Update stock for each item & record movement
      for (final item in state.items) {
        // Get current stock before update
        final prodRows = await _db.query('products',
          where: 'id = ?', whereArgs: [item.productId]);
        if (prodRows.isNotEmpty) {
          final beforeStock = prodRows.first['stock'] as int;
          final afterStock = beforeStock - item.quantity;

          await _db.rawUpdate(
            'UPDATE products SET stock = ?, updated_at = ? WHERE id = ? AND track_stock = 1',
            [afterStock < 0 ? 0 : afterStock, now.toIso8601String(), item.productId],
          );

          // Record stock movement
          await _db.insert('stock_movements', {
            'id': _uuid.v4(),
            'product_id': item.productId,
            'type': 'sale',
            'quantity': -item.quantity,
            'before_stock': beforeStock,
            'after_stock': afterStock < 0 ? 0 : afterStock,
            'reason': 'Penjualan - ${transaction.invoiceNumber}',
            'reference_id': transactionId,
            'created_at': now.toIso8601String(),
            'created_by': user.id,
          });
        }
      }

      // Update customer spending
      if (state.customerId != null) {
        await _db.rawUpdate(
          'UPDATE customers SET total_spending = total_spending + ?, points = points + ?, updated_at = ? WHERE id = ?',
          [state.total, (state.total / 10000).floor(), now.toIso8601String(), state.customerId],
        );
      }

      clearCart();
      return transaction;
    } catch (e) {
      return null;
    }
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier(DatabaseHelper.instance, ref);
});

// Transactions list
final transactionsProvider = FutureProvider.family<List<TransactionModel>, Map<String, dynamic>?>((ref, filters) async {
  final db = DatabaseHelper.instance;
  String where = '1=1';
  final args = <dynamic>[];

  if (filters != null) {
    if (filters['date_from'] != null) {
      where += ' AND t.created_at >= ?';
      args.add(filters['date_from']);
    }
    if (filters['date_to'] != null) {
      where += ' AND t.created_at <= ?';
      args.add(filters['date_to']);
    }
    if (filters['status'] != null) {
      where += ' AND t.status = ?';
      args.add(filters['status']);
    }
    if (filters['payment_method'] != null) {
      where += ' AND t.payment_method = ?';
      args.add(filters['payment_method']);
    }
  }

  final maps = await db.rawQuery('''
    SELECT t.*,
           u.name as cashier_name,
           c.name as customer_name
    FROM transactions t
    LEFT JOIN users u ON t.cashier_id = u.id
    LEFT JOIN customers c ON t.customer_id = c.id
    WHERE $where
    ORDER BY t.created_at DESC
    LIMIT 200
  ''', args);

  return maps.map((m) => TransactionModel.fromMap(m)).toList();
});

// Today's stats
final todayStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final db = DatabaseHelper.instance;
  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day).toIso8601String();
  final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59).toIso8601String();

  final results = await db.rawQuery('''
    SELECT
      COUNT(*) as transaction_count,
      COALESCE(SUM(total), 0) as total_revenue,
      COALESCE(SUM(discount_amount), 0) as total_discount,
      COALESCE(AVG(total), 0) as avg_transaction
    FROM transactions
    WHERE created_at BETWEEN ? AND ? AND status = 'completed'
  ''', [startOfDay, endOfDay]);

  final items = await db.rawQuery('''
    SELECT COALESCE(SUM(ti.quantity), 0) as items_sold
    FROM transaction_items ti
    JOIN transactions t ON ti.transaction_id = t.id
    WHERE t.created_at BETWEEN ? AND ? AND t.status = 'completed'
  ''', [startOfDay, endOfDay]);

  return {
    ...results.first,
    ...items.first,
  };
});
