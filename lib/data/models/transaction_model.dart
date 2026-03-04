import 'package:equatable/equatable.dart';

enum PaymentMethod { cash, transfer, qris, card, other }

enum DiscountType { none, percentage, fixed }

enum TransactionStatus { completed, cancelled, refunded, pending }

extension PaymentMethodExt on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.cash: return 'Tunai';
      case PaymentMethod.transfer: return 'Transfer Bank';
      case PaymentMethod.qris: return 'QRIS';
      case PaymentMethod.card: return 'Kartu';
      case PaymentMethod.other: return 'Lainnya';
    }
  }

  String get icon {
    switch (this) {
      case PaymentMethod.cash: return '💵';
      case PaymentMethod.transfer: return '🏦';
      case PaymentMethod.qris: return '📱';
      case PaymentMethod.card: return '💳';
      case PaymentMethod.other: return '🔄';
    }
  }

  static PaymentMethod fromString(String value) {
    return PaymentMethod.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PaymentMethod.cash,
    );
  }
}

class CartItem extends Equatable {
  final String productId;
  final String? variantId;
  final String productName;
  final double price;
  int quantity;
  double discountPercentage;
  final String? notes;

  CartItem({
    required this.productId,
    this.variantId,
    required this.productName,
    required this.price,
    required this.quantity,
    this.discountPercentage = 0,
    this.notes,
  });

  double get subtotal => price * quantity * (1 - discountPercentage / 100);
  double get discountAmount => price * quantity * (discountPercentage / 100);
  double get originalTotal => price * quantity;

  CartItem copyWith({int? quantity, double? discountPercentage}) {
    return CartItem(
      productId: productId,
      variantId: variantId,
      productName: productName,
      price: price,
      quantity: quantity ?? this.quantity,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      notes: notes,
    );
  }

  @override
  List<Object?> get props => [productId, variantId];
}

class TransactionModel extends Equatable {
  final String id;
  final String invoiceNumber;
  final String cashierId;
  final String? cashierName;
  final String? customerId;
  final String? customerName;
  final List<TransactionItem> items;
  final double subtotal;
  final DiscountType discountType;
  final double discountValue;
  final double discountAmount;
  final double taxPercentage;
  final double taxAmount;
  final double rounding;
  final double total;
  final PaymentMethod paymentMethod;
  final double amountPaid;
  final double changeAmount;
  final TransactionStatus status;
  final String? notes;
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    required this.invoiceNumber,
    required this.cashierId,
    this.cashierName,
    this.customerId,
    this.customerName,
    required this.items,
    required this.subtotal,
    required this.discountType,
    required this.discountValue,
    required this.discountAmount,
    required this.taxPercentage,
    required this.taxAmount,
    required this.rounding,
    required this.total,
    required this.paymentMethod,
    required this.amountPaid,
    required this.changeAmount,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map, {List<TransactionItem>? items}) {
    return TransactionModel(
      id: map['id'] as String,
      invoiceNumber: map['invoice_number'] as String,
      cashierId: map['cashier_id'] as String,
      cashierName: map['cashier_name'] as String?,
      customerId: map['customer_id'] as String?,
      customerName: map['customer_name'] as String?,
      items: items ?? [],
      subtotal: (map['subtotal'] as num).toDouble(),
      discountType: DiscountType.values.firstWhere(
        (e) => e.name == map['discount_type'],
        orElse: () => DiscountType.none,
      ),
      discountValue: (map['discount_value'] as num).toDouble(),
      discountAmount: (map['discount_amount'] as num).toDouble(),
      taxPercentage: (map['tax_percentage'] as num).toDouble(),
      taxAmount: (map['tax_amount'] as num).toDouble(),
      rounding: (map['rounding'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      paymentMethod: PaymentMethodExt.fromString(map['payment_method'] as String),
      amountPaid: (map['amount_paid'] as num).toDouble(),
      changeAmount: (map['change_amount'] as num).toDouble(),
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TransactionStatus.completed,
      ),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'invoice_number': invoiceNumber,
    'cashier_id': cashierId,
    'customer_id': customerId,
    'subtotal': subtotal,
    'discount_type': discountType.name,
    'discount_value': discountValue,
    'discount_amount': discountAmount,
    'tax_percentage': taxPercentage,
    'tax_amount': taxAmount,
    'rounding': rounding,
    'total': total,
    'payment_method': paymentMethod.name,
    'amount_paid': amountPaid,
    'change_amount': changeAmount,
    'status': status.name,
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [id, invoiceNumber, total, status];
}

class TransactionItem extends Equatable {
  final String id;
  final String transactionId;
  final String productId;
  final String? variantId;
  final String productName;
  final double productPrice;
  final int quantity;
  final double discountPercentage;
  final double subtotal;
  final String? notes;

  const TransactionItem({
    required this.id,
    required this.transactionId,
    required this.productId,
    this.variantId,
    required this.productName,
    required this.productPrice,
    required this.quantity,
    required this.discountPercentage,
    required this.subtotal,
    this.notes,
  });

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      id: map['id'] as String,
      transactionId: map['transaction_id'] as String,
      productId: map['product_id'] as String,
      variantId: map['variant_id'] as String?,
      productName: map['product_name'] as String,
      productPrice: (map['product_price'] as num).toDouble(),
      quantity: map['quantity'] as int,
      discountPercentage: (map['discount_percentage'] as num).toDouble(),
      subtotal: (map['subtotal'] as num).toDouble(),
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'transaction_id': transactionId,
    'product_id': productId,
    'variant_id': variantId,
    'product_name': productName,
    'product_price': productPrice,
    'quantity': quantity,
    'discount_percentage': discountPercentage,
    'subtotal': subtotal,
    'notes': notes,
  };

  @override
  List<Object?> get props => [id, productId, quantity, subtotal];
}

class CustomerModel extends Equatable {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final int points;
  final double totalSpending;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CustomerModel({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    required this.points,
    required this.totalSpending,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      address: map['address'] as String?,
      points: map['points'] as int,
      totalSpending: (map['total_spending'] as num).toDouble(),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'phone': phone,
    'email': email,
    'address': address,
    'points': points,
    'total_spending': totalSpending,
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  String get memberLevel {
    if (totalSpending >= 10000000) return 'Platinum';
    if (totalSpending >= 5000000) return 'Gold';
    if (totalSpending >= 1000000) return 'Silver';
    return 'Bronze';
  }

  @override
  List<Object?> get props => [id, name, phone, points, totalSpending];
}
