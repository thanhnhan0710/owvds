class MaterialInventory {
  final int id;
  final int warehouseId;
  final int materialId;
  final String? materialCode;
  final int batchId;

  final String? batchCode;
  final String? poNumber;
  final int? numberOfPallets;

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
    this.materialCode, // [MỚI]
    required this.batchId,
    this.batchCode,
    this.poNumber,
    this.numberOfPallets,
    required this.location,
    required this.quantityKg,
    required this.quantityCones,
    required this.reservedQuantityKg,
    required this.reservedQuantityCones,
    required this.lastCountedDate,
  });

  factory MaterialInventory.fromJson(Map<String, dynamic> json) {
    String? matCode;
    if (json['material'] != null) {
      matCode = json['material']['material_code'];
    }
    return MaterialInventory(
      id: json['inventory_id'] ?? 0,
      warehouseId: json['warehouse_id'] ?? 0,
      materialId: json['material_id'] ?? 0,
      batchId: json['batch_id'] ?? 0,
      batchCode: json['batch_code'],
      poNumber: json['po_number'],
      numberOfPallets: json['number_of_pallets'],
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
      'batch_code': batchCode,
      'po_number': poNumber,
      'number_of_pallets': numberOfPallets,
      'location': location,
      'quantity_kg': quantityKg,
      'quantity_cones': quantityCones,
      'reserved_quantity_kg': reservedQuantityKg,
      'reserved_quantity_cones': reservedQuantityCones,
      'last_counted_date': lastCountedDate,
    };
  }

  // [QUAN TRỌNG - SỬA LỖI 422]: API Update của Backend chỉ nhận một số field nhất định.
  // Nếu gửi thừa hoặc gửi ngày rỗng ("") sẽ bị lỗi 422.
  Map<String, dynamic> toJsonForUpdate() {
    return {
      'location': location,
      'number_of_pallets': numberOfPallets,
      'quantity_kg': quantityKg,
      'quantity_cones': quantityCones,
      'reserved_quantity_kg': reservedQuantityKg,
      'reserved_quantity_cones': reservedQuantityCones,
      'last_counted_date': lastCountedDate.isEmpty ? null : lastCountedDate,
    };
  }

  MaterialInventory copyWith({
    int? id,
    int? warehouseId,
    int? materialId,
    int? batchId,
    String? batchCode,
    String? poNumber,
    int? numberOfPallets,
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
      batchCode: batchCode ?? this.batchCode,
      poNumber: poNumber ?? this.poNumber,
      numberOfPallets: numberOfPallets ?? this.numberOfPallets,
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
