class WeavingRecord {
  final int id;
  final int machineId;
  final int line;
  final int basketId;
  final int? weavingTicketId;
  final int? shiftId;

  final double totalWeight;
  final double runWaste;
  final String? runWasteReason; // ← THÊM: Lý do phế run
  final double setupWaste;
  final int? updatedById;

  final String? machineName;
  final String? basketCode;
  final String? shiftName;
  final String? updatedByName;
  final DateTime? updatedAt;

  WeavingRecord({
    required this.id,
    required this.machineId,
    required this.line,
    required this.basketId,
    this.weavingTicketId,
    this.shiftId,
    this.updatedById,
    required this.totalWeight,
    required this.runWaste,
    this.runWasteReason, // ← THÊM
    required this.setupWaste,
    this.machineName,
    this.basketCode,
    this.shiftName,
    this.updatedByName,
    this.updatedAt,
  });

  WeavingRecord copyWith({
    int? id,
    int? machineId,
    int? line,
    int? basketId,
    int? shiftId,
    int? updatedById,
    double? totalWeight,
    double? runWaste,
    String? runWasteReason, // ← THÊM
    double? setupWaste,
    String? machineName,
    String? basketName,
    String? shiftName,
  }) {
    return WeavingRecord(
      id: id ?? this.id,
      machineId: machineId ?? this.machineId,
      line: line ?? this.line,
      basketId: basketId ?? this.basketId,
      shiftId: shiftId ?? this.shiftId,
      updatedById: updatedById ?? this.updatedById,
      totalWeight: totalWeight ?? this.totalWeight,
      runWaste: runWaste ?? this.runWaste,
      runWasteReason: runWasteReason ?? this.runWasteReason, // ← THÊM
      setupWaste: setupWaste ?? this.setupWaste,
      machineName: machineName ?? this.machineName,
      basketCode: basketName ?? basketCode,
      shiftName: shiftName ?? this.shiftName,
      updatedByName: updatedByName,
      updatedAt: updatedAt,
    );
  }

  factory WeavingRecord.fromJson(Map<String, dynamic> json) {
    return WeavingRecord(
      id: json['id'] ?? 0,
      machineId: json['machine_id'] ?? 0,
      line: json['line'] ?? 0,
      basketId: json['basket_id'] ?? 0,
      weavingTicketId: json['weaving_ticket_id'],
      shiftId: json['shift_id'],
      totalWeight: (json['total_weight'] ?? 0).toDouble(),
      runWaste: (json['run_waste'] ?? 0).toDouble(),
      runWasteReason: json['run_waste_reason'], // ← THÊM: Map từ JSON
      setupWaste: (json['setup_waste'] ?? 0).toDouble(),
      machineName: json['machine']?['machine_name'],
      basketCode: json['basket']?['basket_code'] ?? json['basket']?['code'],
      shiftName: json['shift']?['shift_name'] ?? json['shift']?['name'],
      updatedByName: json['updated_by']?['full_name'],
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'machine_id': machineId,
      'line': line,
      'basket_id': basketId,
      'weaving_ticket_id': weavingTicketId,
      'updated_by_id': updatedById,
      'shift_id': shiftId,
      'total_weight': totalWeight,
      'run_waste': runWaste,
      'run_waste_reason': runWasteReason, // ← THÊM: Gửi lên Backend
      'setup_waste': setupWaste,
    };
  }
}
