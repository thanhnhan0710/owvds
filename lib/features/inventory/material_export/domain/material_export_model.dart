// ==========================================
// CÁC CLASS PHỤ TRỢ (SIMPLE INFO)
// ==========================================

// Model cho batch đang hoạt động trên máy (dùng khi tạo phiếu dệt)
class ActiveBatchOnMachine {
  final int batchId;
  final String batchCode;
  final double quantityKg;
  final String? yarnRole; // componentType: 'WARP' / 'WEFT' / ...

  ActiveBatchOnMachine({
    required this.batchId,
    required this.batchCode,
    required this.quantityKg,
    this.yarnRole,
  });

  factory ActiveBatchOnMachine.fromJson(Map<String, dynamic> json) =>
      ActiveBatchOnMachine(
        batchId: json['batch_id'] ?? 0,
        batchCode: json['batch_code'] ?? '',
        quantityKg: (json['quantity_kg'] ?? 0).toDouble(),
        yarnRole: json['yarn_role'] ?? json['component_type'],
      );
}

class SimpleWarehouse {
  final int warehouseId;
  final String? name;

  SimpleWarehouse({required this.warehouseId, this.name});

  factory SimpleWarehouse.fromJson(Map<String, dynamic> json) =>
      SimpleWarehouse(
        warehouseId: json['warehouse_id'] ?? 0,
        name: json['name'],
      );
}

class SimpleEmployee {
  final int employeeId;
  final String? fullName;

  SimpleEmployee({required this.employeeId, this.fullName});

  factory SimpleEmployee.fromJson(Map<String, dynamic> json) => SimpleEmployee(
    employeeId: json['employee_id'] ?? 0,
    fullName: json['full_name'],
  );
}

class SimpleMaterial {
  final int materialId;
  final String materialCode;
  final String? materialName;

  SimpleMaterial({
    required this.materialId,
    required this.materialCode,
    this.materialName,
  });

  factory SimpleMaterial.fromJson(Map<String, dynamic> json) => SimpleMaterial(
    materialId: json['material_id'] ?? 0,
    materialCode: json['material_code'] ?? '',
    materialName: json['material_name'],
  );
}

class SimpleBatch {
  final int batchId;
  final String batchCode;
  final String? supplierBatchNo;

  SimpleBatch({
    required this.batchId,
    required this.batchCode,
    this.supplierBatchNo,
  });

  factory SimpleBatch.fromJson(Map<String, dynamic> json) => SimpleBatch(
    batchId: json['batch_id'] ?? 0,
    batchCode: json['batch_code'] ?? '',
    supplierBatchNo: json['supplier_batch_no'],
  );
}

class SimpleLoomInfo {
  final int id;
  final int machineId;
  final int lineNumber;
  final String? machineName;
  final String? productCode;

  SimpleLoomInfo({
    required this.id,
    required this.machineId,
    required this.lineNumber,
    this.machineName,
    this.productCode,
  });

  factory SimpleLoomInfo.fromJson(Map<String, dynamic> json) {
    // Tự động map từ các object lồng nhau nếu có
    final machineInfo = json['machine'];
    final productInfo = json['product'];

    return SimpleLoomInfo(
      id: json['id'] ?? 0,
      machineId: json['machine_id'] ?? 0,
      lineNumber: json['line_number'] ?? 1,
      machineName: machineInfo != null
          ? machineInfo['machine_name']
          : json['machine_name'],
      productCode: productInfo != null
          ? productInfo['item_code']
          : json['product_code'],
    );
  }
}

// ==========================================
// CLASS CHI TIẾT PHIẾU XUẤT (DETAIL)
// ==========================================
class MaterialExportDetail {
  final int detailId;
  final int exportId;
  final int materialId;
  final int batchId;

  final double quantityKg;
  final int quantityCones;
  final int numberOfPallets;

  final String? componentType;
  final int? loomId;
  final String? note;

  final SimpleMaterial? material;
  final SimpleBatch? batch;
  final SimpleLoomInfo? loomInfo;

  MaterialExportDetail({
    required this.detailId,
    required this.exportId,
    required this.materialId,
    required this.batchId,
    required this.quantityKg,
    required this.quantityCones,
    required this.numberOfPallets,
    this.componentType,
    this.loomId,
    this.note,
    this.material,
    this.batch,
    this.loomInfo,
  });

  factory MaterialExportDetail.fromJson(Map<String, dynamic> json) {
    return MaterialExportDetail(
      detailId: json['detail_id'] ?? 0,
      exportId: json['export_id'] ?? 0,
      materialId: json['material_id'] ?? 0,
      batchId: json['batch_id'] ?? 0,
      quantityKg: (json['quantity_kg'] ?? 0).toDouble(),
      quantityCones: json['quantity_cones'] ?? 0,
      numberOfPallets: json['number_of_pallets'] ?? 0,
      componentType: json['component_type'],
      loomId: json['loom_id'],
      note: json['note'],
      material: json['material'] != null
          ? SimpleMaterial.fromJson(json['material'])
          : null,
      batch: json['batch'] != null ? SimpleBatch.fromJson(json['batch']) : null,
      loomInfo: json['loom'] != null
          ? SimpleLoomInfo.fromJson(json['loom'])
          : null, // Backend đang trả về key là 'loom'
    );
  }
}

// ==========================================
// CLASS PHIẾU XUẤT (HEADER)
// ==========================================
class MaterialExport {
  final int id;
  final String exportCode;
  final DateTime exportDate;
  final int warehouseId;
  final int? exporterId;
  final int? receiverId;
  final int? departmentId;
  final int? shiftId;
  final String? note;
  final DateTime createdAt;
  final String? createdBy;

  final SimpleWarehouse? warehouse;
  final SimpleEmployee? exporter;
  final SimpleEmployee? receiver;
  final List<MaterialExportDetail> details;

  MaterialExport({
    required this.id,
    required this.exportCode,
    required this.exportDate,
    required this.warehouseId,
    this.exporterId,
    this.receiverId,
    this.departmentId,
    this.shiftId,
    this.note,
    required this.createdAt,
    this.createdBy,
    this.warehouse,
    this.exporter,
    this.receiver,
    this.details = const [],
  });

  factory MaterialExport.fromJson(Map<String, dynamic> json) {
    return MaterialExport(
      id: json['id'] ?? 0,
      exportCode: json['export_code'] ?? '',
      exportDate: DateTime.parse(json['export_date']).toLocal(),
      warehouseId: json['warehouse_id'] ?? 0,
      exporterId: json['exporter_id'],
      receiverId: json['receiver_id'],
      departmentId: json['department_id'],
      shiftId: json['shift_id'],
      note: json['note'],
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      createdBy: json['created_by'],
      warehouse: json['warehouse'] != null
          ? SimpleWarehouse.fromJson(json['warehouse'])
          : null,
      exporter: json['exporter'] != null
          ? SimpleEmployee.fromJson(json['exporter'])
          : null,
      receiver: json['receiver'] != null
          ? SimpleEmployee.fromJson(json['receiver'])
          : null,
      details: json['details'] != null
          ? (json['details'] as List)
                .map((i) => MaterialExportDetail.fromJson(i))
                .toList()
          : [],
    );
  }
}

// ==========================================
// REQUEST DTO (Dùng để gửi dữ liệu lên API tạo mới)
// ==========================================
class MaterialExportDetailRequest {
  final int materialId;
  final int batchId;
  final double quantityKg;
  final int quantityCones;
  final int numberOfPallets;
  final String? componentType;
  final int? loomId;
  final String? note;

  MaterialExportDetailRequest({
    required this.materialId,
    required this.batchId,
    required this.quantityKg,
    required this.quantityCones,
    required this.numberOfPallets,
    this.componentType,
    this.loomId,
    this.note,
  });

  Map<String, dynamic> toJson() => {
    'material_id': materialId,
    'batch_id': batchId,
    'quantity_kg': quantityKg,
    'quantity_cones': quantityCones,
    'number_of_pallets': numberOfPallets,
    if (componentType != null) 'component_type': componentType,
    if (loomId != null) 'loom_id': loomId,
    if (note != null) 'note': note,
  };
}

class MaterialExportRequest {
  final String? exportCode;
  final String exportDate; // Format YYYY-MM-DD
  final int warehouseId;
  final int? exporterId;
  final int? receiverId;
  final int? departmentId;
  final int? shiftId;
  final String? note;
  final List<MaterialExportDetailRequest> details;

  MaterialExportRequest({
    this.exportCode,
    required this.exportDate,
    required this.warehouseId,
    this.exporterId,
    this.receiverId,
    this.departmentId,
    this.shiftId,
    this.note,
    required this.details,
  });

  Map<String, dynamic> toJson() => {
    if (exportCode != null && exportCode!.isNotEmpty) 'export_code': exportCode,
    'export_date': exportDate,
    'warehouse_id': warehouseId,
    if (exporterId != null) 'exporter_id': exporterId,
    if (receiverId != null) 'receiver_id': receiverId,
    if (departmentId != null) 'department_id': departmentId,
    if (shiftId != null) 'shift_id': shiftId,
    if (note != null) 'note': note,
    'details': details.map((d) => d.toJson()).toList(),
  };
}
