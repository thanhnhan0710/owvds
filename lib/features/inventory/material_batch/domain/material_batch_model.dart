class MaterialBatch {
  final int id;
  final String batchCode;
  final int materialId;
  final int receiptDetailId;
  final String supplierBatchNo;
  final String originCountry;
  final String manufacturingDate;
  final String expirationDate;
  final double initialQuantityKg;
  final int initialQuantityCones;
  final String status;

  MaterialBatch({
    required this.id,
    required this.batchCode,
    required this.materialId,
    required this.receiptDetailId,
    required this.supplierBatchNo,
    required this.originCountry,
    required this.manufacturingDate,
    required this.expirationDate,
    required this.initialQuantityKg,
    required this.initialQuantityCones,
    required this.status,
  });

  factory MaterialBatch.fromJson(Map<String, dynamic> json) {
    return MaterialBatch(
      id: json['batch_id'] ?? 0,
      batchCode: json['batch_code'] ?? '',
      materialId: json['material_id'] ?? 0,
      receiptDetailId: json['receipt_detail_id'] ?? 0,
      supplierBatchNo: json['supplier_batch_no'] ?? '',
      originCountry: json['origin_country'] ?? '',
      manufacturingDate: json['manufacturing_date'] ?? '',
      expirationDate: json['expiration_date'] ?? '',
      initialQuantityKg: (json['initial_quantity_kg'] ?? 0).toDouble(),
      initialQuantityCones: json['initial_quantity_cones'] ?? 0,
      status: json['status'] ?? 'Available',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'batch_id': id,
      'batch_code': batchCode,
      'material_id': materialId,
      'receipt_detail_id': receiptDetailId,
      'supplier_batch_no': supplierBatchNo,
      'origin_country': originCountry,
      'manufacturing_date': manufacturingDate,
      'expiration_date': expirationDate,
      'initial_quantity_kg': initialQuantityKg,
      'initial_quantity_cones': initialQuantityCones,
      'status': status,
    };
  }

  MaterialBatch copyWith({
    int? id,
    String? batchCode,
    int? materialId,
    int? receiptDetailId,
    String? supplierBatchNo,
    String? originCountry,
    String? manufacturingDate,
    String? expirationDate,
    double? initialQuantityKg,
    int? initialQuantityCones,
    String? status,
  }) {
    return MaterialBatch(
      id: id ?? this.id,
      batchCode: batchCode ?? this.batchCode,
      materialId: materialId ?? this.materialId,
      receiptDetailId: receiptDetailId ?? this.receiptDetailId,
      supplierBatchNo: supplierBatchNo ?? this.supplierBatchNo,
      originCountry: originCountry ?? this.originCountry,
      manufacturingDate: manufacturingDate ?? this.manufacturingDate,
      expirationDate: expirationDate ?? this.expirationDate,
      initialQuantityKg: initialQuantityKg ?? this.initialQuantityKg,
      initialQuantityCones: initialQuantityCones ?? this.initialQuantityCones,
      status: status ?? this.status,
    );
  }
}
