import 'package:equatable/equatable.dart';

class CategoryModel extends Equatable {
  final String id;
  final String name;
  final String? icon;
  final String? color;
  final int sortOrder;
  final DateTime createdAt;

  const CategoryModel({
    required this.id,
    required this.name,
    this.icon,
    this.color,
    required this.sortOrder,
    required this.createdAt,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: map['icon'] as String?,
      color: map['color'] as String?,
      sortOrder: map['sort_order'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'icon': icon,
    'color': color,
    'sort_order': sortOrder,
    'created_at': createdAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [id, name];
}

class ProductModel extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? categoryId;
  final String? categoryName;
  final String? barcode;
  final String? sku;
  final double price;
  final double costPrice;
  final int stock;
  final int minStock;
  final String unit;
  final String? imagePath;
  final bool isActive;
  final bool trackStock;
  final bool hasVariants;
  final List<ProductVariant> variants;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductModel({
    required this.id,
    required this.name,
    this.description,
    this.categoryId,
    this.categoryName,
    this.barcode,
    this.sku,
    required this.price,
    required this.costPrice,
    required this.stock,
    required this.minStock,
    required this.unit,
    this.imagePath,
    required this.isActive,
    required this.trackStock,
    required this.hasVariants,
    this.variants = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      categoryId: map['category_id'] as String?,
      categoryName: map['category_name'] as String?,
      barcode: map['barcode'] as String?,
      sku: map['sku'] as String?,
      price: (map['price'] as num).toDouble(),
      costPrice: (map['cost_price'] as num).toDouble(),
      stock: map['stock'] as int,
      minStock: map['min_stock'] as int,
      unit: map['unit'] as String,
      imagePath: map['image_path'] as String?,
      isActive: (map['is_active'] as int) == 1,
      trackStock: (map['track_stock'] as int) == 1,
      hasVariants: (map['has_variants'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'category_id': categoryId,
    'barcode': barcode,
    'sku': sku,
    'price': price,
    'cost_price': costPrice,
    'stock': stock,
    'min_stock': minStock,
    'unit': unit,
    'image_path': imagePath,
    'is_active': isActive ? 1 : 0,
    'track_stock': trackStock ? 1 : 0,
    'has_variants': hasVariants ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  bool get isLowStock => trackStock && stock <= minStock;
  double get profitMargin => price > 0 ? ((price - costPrice) / price) * 100 : 0;

  ProductModel copyWith({
    String? name,
    String? description,
    String? categoryId,
    String? barcode,
    String? sku,
    double? price,
    double? costPrice,
    int? stock,
    int? minStock,
    String? unit,
    String? imagePath,
    bool? isActive,
    bool? trackStock,
  }) {
    return ProductModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      barcode: barcode ?? this.barcode,
      sku: sku ?? this.sku,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
      unit: unit ?? this.unit,
      imagePath: imagePath ?? this.imagePath,
      isActive: isActive ?? this.isActive,
      trackStock: trackStock ?? this.trackStock,
      hasVariants: hasVariants,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, name, price, stock];
}

class ProductVariant extends Equatable {
  final String id;
  final String productId;
  final String name;
  final double price;
  final double costPrice;
  final int stock;
  final String? barcode;
  final String? sku;

  const ProductVariant({
    required this.id,
    required this.productId,
    required this.name,
    required this.price,
    required this.costPrice,
    required this.stock,
    this.barcode,
    this.sku,
  });

  factory ProductVariant.fromMap(Map<String, dynamic> map) {
    return ProductVariant(
      id: map['id'] as String,
      productId: map['product_id'] as String,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      costPrice: (map['cost_price'] as num).toDouble(),
      stock: map['stock'] as int,
      barcode: map['barcode'] as String?,
      sku: map['sku'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, productId, name, price];
}
