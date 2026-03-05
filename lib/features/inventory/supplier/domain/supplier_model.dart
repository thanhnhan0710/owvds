import '../../supplier_category/domain/supplier_category_model.dart';

class Supplier {
  final int supplierId;
  final String supplierName;
  final String? shortName;
  final String? address;
  final bool isActive;
  final int? categoryId;

  // Nested Object
  final SupplierCategory? category;

  Supplier({
    required this.supplierId,
    required this.supplierName,
    this.shortName,
    this.address,
    this.isActive = true,
    this.categoryId,
    this.category,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      supplierId: json['supplier_id'] ?? 0,
      supplierName: json['supplier_name'] ?? '',
      shortName: json['short_name'],
      address: json['address'],
      isActive: json['is_active'] ?? true,
      categoryId: json['category_id'],
      category: json['category'] != null
          ? SupplierCategory.fromJson(json['category'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'supplier_name': supplierName,
      'short_name': shortName,
      'address': address,
      'is_active': isActive,
      'category_id': categoryId,
    };
  }
}
