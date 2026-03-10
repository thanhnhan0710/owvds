class MaterialReceiptDetail {
  final int? detailId;
  final int? receiptId;
  final int materialId;
  final double poQuantityKg;
  final int poQuantityCones;
  final double receivedQuantityKg;
  final int receivedQuantityCones;
  final int numberOfPallets;
  final String? supplierBatchNo;
  final String? originCountry;
  final String? location;
  final String? note;

  MaterialReceiptDetail({
    this.detailId,
    this.receiptId,
    required this.materialId,
    this.poQuantityKg = 0.0,
    this.poQuantityCones = 0,
    required this.receivedQuantityKg,
    this.receivedQuantityCones = 0,
    this.numberOfPallets = 0,
    this.supplierBatchNo,
    this.originCountry,
    this.location,
    this.note,
  });

  factory MaterialReceiptDetail.fromJson(Map<String, dynamic> json) {
    return MaterialReceiptDetail(
      detailId: json['detail_id'],
      receiptId: json['receipt_id'],
      materialId: json['material_id'] ?? 0,
      poQuantityKg: (json['po_quantity_kg'] ?? 0).toDouble(),
      poQuantityCones: json['po_quantity_cones'] ?? 0,
      receivedQuantityKg: (json['received_quantity_kg'] ?? 0).toDouble(),
      receivedQuantityCones: json['received_quantity_cones'] ?? 0,
      numberOfPallets: json['number_of_pallets'] ?? 0,
      supplierBatchNo: json['supplier_batch_no'],
      originCountry: json['origin_country'],
      location: json['location'],
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (detailId != null) 'detail_id': detailId,
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
    int? materialId,
    double? receivedQuantityKg,
    int? receivedQuantityCones,
    String? location,
    String? supplierBatchNo,
    String? originCountry,
  }) {
    return MaterialReceiptDetail(
      detailId: detailId,
      receiptId: receiptId,
      materialId: materialId ?? this.materialId,
      poQuantityKg: poQuantityKg,
      poQuantityCones: poQuantityCones,
      receivedQuantityKg: receivedQuantityKg ?? this.receivedQuantityKg,
      receivedQuantityCones:
          receivedQuantityCones ?? this.receivedQuantityCones,
      numberOfPallets: numberOfPallets,
      supplierBatchNo: supplierBatchNo ?? this.supplierBatchNo,
      originCountry: originCountry ?? this.originCountry,
      location: location ?? this.location,
      note: note,
    );
  }
}

class MaterialReceipt {
  final int? receiptId;
  final String? receiptNumber;
  final String? receiptDate;
  final int? poHeaderId;
  final int warehouseId;
  final String? containerNo;
  final String? sealNo;
  final String status;
  final String? note;
  final String? createdBy;
  final List<MaterialReceiptDetail> details;

  MaterialReceipt({
    this.receiptId,
    this.receiptNumber,
    this.receiptDate,
    this.poHeaderId,
    required this.warehouseId,
    this.containerNo,
    this.sealNo,
    this.status = "Draft",
    this.note,
    this.createdBy,
    this.details = const [],
  });

  factory MaterialReceipt.fromJson(Map<String, dynamic> json) {
    return MaterialReceipt(
      receiptId: json['receipt_id'],
      receiptNumber: json['receipt_number'],
      receiptDate: json['receipt_date'],
      poHeaderId: json['po_header_id'],
      warehouseId: json['warehouse_id'] ?? 0,
      containerNo: json['container_no'],
      sealNo: json['seal_no'],
      status: json['status'] ?? 'Draft',
      note: json['note'],
      createdBy: json['created_by'],
      details: json['details'] != null
          ? (json['details'] as List)
                .map((i) => MaterialReceiptDetail.fromJson(i))
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (receiptId != null) 'receipt_id': receiptId,
      if (receiptNumber != null) 'receipt_number': receiptNumber,
      if (receiptDate != null) 'receipt_date': receiptDate,
      if (poHeaderId != null) 'po_header_id': poHeaderId,
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
    String? status,
    String? note,
    String? containerNo,
    String? sealNo,
  }) {
    return MaterialReceipt(
      receiptId: receiptId,
      receiptNumber: receiptNumber,
      receiptDate: receiptDate,
      poHeaderId: poHeaderId,
      warehouseId: warehouseId,
      containerNo: containerNo ?? this.containerNo,
      sealNo: sealNo ?? this.sealNo,
      status: status ?? this.status,
      note: note ?? this.note,
      createdBy: createdBy,
      details: details,
    );
  }
}
