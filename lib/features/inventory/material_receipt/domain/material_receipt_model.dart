class MaterialReceiptDetail {
  final int id;
  final int materialId;
  final double poQuantityKg;
  final int poQuantityCones;
  final double receivedQuantityKg;
  final int receivedQuantityCones;
  final int numberOfPallets;
  final String supplierBatchNo;
  final String originCountry;
  final String location;
  final String note;

  MaterialReceiptDetail({
    required this.id,
    required this.materialId,
    required this.poQuantityKg,
    required this.poQuantityCones,
    required this.receivedQuantityKg,
    required this.receivedQuantityCones,
    required this.numberOfPallets,
    required this.supplierBatchNo,
    required this.originCountry,
    required this.location,
    required this.note,
  });

  factory MaterialReceiptDetail.fromJson(Map<String, dynamic> json) {
    return MaterialReceiptDetail(
      id: json['detail_id'] ?? 0,
      materialId: json['material_id'] ?? 0,
      poQuantityKg: (json['po_quantity_kg'] ?? 0).toDouble(),
      poQuantityCones: json['po_quantity_cones'] ?? 0,
      receivedQuantityKg: (json['received_quantity_kg'] ?? 0).toDouble(),
      receivedQuantityCones: json['received_quantity_cones'] ?? 0,
      numberOfPallets: json['number_of_pallets'] ?? 0,
      supplierBatchNo: json['supplier_batch_no'] ?? '',
      originCountry: json['origin_country'] ?? '',
      location: json['location'] ?? '',
      note: json['note'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'detail_id': id,
      'material_id': materialId,
      'po_quantity_kg': poQuantityKg,
      'po_quantity_cones': poQuantityCones,
      'received_quantity_kg': receivedQuantityKg,
      'received_quantity_cones': receivedQuantityCones,
      'number_of_pallets': numberOfPallets,
      'supplier_batch_no': supplierBatchNo,
      'origin_country': originCountry,
      'location': location,
      'note': note,
    };
  }

  MaterialReceiptDetail copyWith({
    int? id,
    int? materialId,
    double? poQuantityKg,
    int? poQuantityCones,
    double? receivedQuantityKg,
    int? receivedQuantityCones,
    int? numberOfPallets,
    String? supplierBatchNo,
    String? originCountry,
    String? location,
    String? note,
  }) {
    return MaterialReceiptDetail(
      id: id ?? this.id,
      materialId: materialId ?? this.materialId,
      poQuantityKg: poQuantityKg ?? this.poQuantityKg,
      poQuantityCones: poQuantityCones ?? this.poQuantityCones,
      receivedQuantityKg: receivedQuantityKg ?? this.receivedQuantityKg,
      receivedQuantityCones:
          receivedQuantityCones ?? this.receivedQuantityCones,
      numberOfPallets: numberOfPallets ?? this.numberOfPallets,
      supplierBatchNo: supplierBatchNo ?? this.supplierBatchNo,
      originCountry: originCountry ?? this.originCountry,
      location: location ?? this.location,
      note: note ?? this.note,
    );
  }
}

class MaterialReceipt {
  final int id;
  final String receiptNumber;
  final String receiptDate;
  final int poHeaderId;
  final int warehouseId;
  final String containerNo;
  final String sealNo;
  final String status;
  final String note;
  final String createdBy;
  final List<MaterialReceiptDetail> details;

  MaterialReceipt({
    required this.id,
    required this.receiptNumber,
    required this.receiptDate,
    required this.poHeaderId,
    required this.warehouseId,
    required this.containerNo,
    required this.sealNo,
    required this.status,
    required this.note,
    required this.createdBy,
    required this.details,
  });

  factory MaterialReceipt.fromJson(Map<String, dynamic> json) {
    return MaterialReceipt(
      id: json['receipt_id'] ?? 0,
      receiptNumber: json['receipt_number'] ?? '',
      receiptDate: json['receipt_date'] ?? '',
      poHeaderId: json['po_header_id'] ?? 0,
      warehouseId: json['warehouse_id'] ?? 0,
      containerNo: json['container_no'] ?? '',
      sealNo: json['seal_no'] ?? '',
      status: json['status'] ?? 'Draft',
      note: json['note'] ?? '',
      createdBy: json['created_by'] ?? '',
      details: json['details'] != null
          ? (json['details'] as List)
                .map((i) => MaterialReceiptDetail.fromJson(i))
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'receipt_id': id,
      'receipt_number': receiptNumber,
      'receipt_date': receiptDate,
      'po_header_id': poHeaderId,
      'warehouse_id': warehouseId,
      'container_no': containerNo,
      'seal_no': sealNo,
      'status': status,
      'note': note,
      'created_by': createdBy,
      'details': details.map((e) => e.toJson()).toList(),
    };
  }

  MaterialReceipt copyWith({
    int? id,
    String? receiptNumber,
    String? receiptDate,
    int? poHeaderId,
    int? warehouseId,
    String? containerNo,
    String? sealNo,
    String? status,
    String? note,
    String? createdBy,
    List<MaterialReceiptDetail>? details,
  }) {
    return MaterialReceipt(
      id: id ?? this.id,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      receiptDate: receiptDate ?? this.receiptDate,
      poHeaderId: poHeaderId ?? this.poHeaderId,
      warehouseId: warehouseId ?? this.warehouseId,
      containerNo: containerNo ?? this.containerNo,
      sealNo: sealNo ?? this.sealNo,
      status: status ?? this.status,
      note: note ?? this.note,
      createdBy: createdBy ?? this.createdBy,
      details: details ?? this.details,
    );
  }
}
