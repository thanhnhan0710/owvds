class MaterialInventory {
  final int id;
  final int warehouseId;
  final int materialId;
  final int batchId;
  final String location;
  final double quantityKg;
  final int quantityCones;
  final double reservedQuantityKg;
  final int reservedQuantityCones;
  final String lastCountedDate;

  MaterialInventory({
    required this.id,
    required this.warehouseId,
    required this.materialId,
    required this.batchId,
    required this.location,
    required this.quantityKg,
    required this.quantityCones,
    required this.reservedQuantityKg,
    required this.reservedQuantityCones,
    required this.lastCountedDate,
  });

  factory MaterialInventory.fromJson(Map<String, dynamic> json) {
    return MaterialInventory(
      id: json['inventory_id'] ?? 0,
      warehouseId: json['warehouse_id'] ?? 0,
      materialId: json['material_id'] ?? 0,
      batchId: json['batch_id'] ?? 0,
      location: json['location'] ?? '',
      quantityKg: (json['quantity_kg'] ?? 0).toDouble(),
      quantityCones: json['quantity_cones'] ?? 0,
      reservedQuantityKg: (json['reserved_quantity_kg'] ?? 0).toDouble(),
      reservedQuantityCones: json['reserved_quantity_cones'] ?? 0,
      lastCountedDate: json['last_counted_date'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'inventory_id': id,
      'warehouse_id': warehouseId,
      'material_id': materialId,
      'batch_id': batchId,
      'location': location,
      'quantity_kg': quantityKg,
      'quantity_cones': quantityCones,
      'reserved_quantity_kg': reservedQuantityKg,
      'reserved_quantity_cones': reservedQuantityCones,
      'last_counted_date': lastCountedDate,
    };
  }

  MaterialInventory copyWith({
    int? id,
    int? warehouseId,
    int? materialId,
    int? batchId,
    String? location,
    double? quantityKg,
    int? quantityCones,
    double? reservedQuantityKg,
    int? reservedQuantityCones,
    String? lastCountedDate,
  }) {
    return MaterialInventory(
      id: id ?? this.id,
      warehouseId: warehouseId ?? this.warehouseId,
      materialId: materialId ?? this.materialId,
      batchId: batchId ?? this.batchId,
      location: location ?? this.location,
      quantityKg: quantityKg ?? this.quantityKg,
      quantityCones: quantityCones ?? this.quantityCones,
      reservedQuantityKg: reservedQuantityKg ?? this.reservedQuantityKg,
      reservedQuantityCones:
          reservedQuantityCones ?? this.reservedQuantityCones,
      lastCountedDate: lastCountedDate ?? this.lastCountedDate,
    );
  }
}
