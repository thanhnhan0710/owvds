import '../../material_type/domain/material_type_model.dart';
import '../../supplier/domain/supplier_model.dart';

// Đặt tên là MaterialItem để tránh trùng với thư viện Material Design của Flutter
class MaterialItem {
  final int materialId;
  final String materialCode;
  final String materialName;
  final int? typeId;
  final int? supplierId;

  final String? color;
  final int? dtex;
  final String? filament;

  final double minStockLevel;
  final double? kgPerBobbin;

  // Nested relations
  final MaterialType? materialType;
  final Supplier? supplier;

  MaterialItem({
    required this.materialId,
    required this.materialCode,
    required this.materialName,
    this.typeId,
    this.supplierId,
    this.color,
    this.dtex,
    this.filament,
    this.minStockLevel = 0.0,
    this.kgPerBobbin,
    this.materialType,
    this.supplier,
  });

  factory MaterialItem.fromJson(Map<String, dynamic> json) {
    return MaterialItem(
      materialId: json['material_id'] ?? 0,
      materialCode: json['material_code'] ?? '',
      materialName: json['material_name'] ?? '',
      typeId: json['type_id'],
      supplierId: json['supplier_id'],
      color: json['color'],
      dtex: json['dtex'],
      filament: json['filament'],
      minStockLevel: (json['min_stock_level'] ?? 0.0).toDouble(),
      kgPerBobbin: json['kg_per_bobbin']?.toDouble(),

      materialType: json['material_type'] != null
          ? MaterialType.fromJson(json['material_type'])
          : null,
      supplier: json['supplier'] != null
          ? Supplier.fromJson(json['supplier'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'material_code': materialCode,
      'material_name': materialName,
      'type_id': typeId,
      'supplier_id': supplierId,
      'color': color,
      'dtex': dtex,
      'filament': filament,
      'min_stock_level': minStockLevel,
      'kg_per_bobbin': kgPerBobbin,
    };
  }
}
