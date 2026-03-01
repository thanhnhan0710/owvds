// --- BỔ SUNG MODEL ---
class MachineBasicInfo {
  final int machineId;
  final String machineName;
  MachineBasicInfo({required this.machineId, required this.machineName});
  factory MachineBasicInfo.fromJson(Map<String, dynamic> json) =>
      MachineBasicInfo(
        machineId: json['machine_id'] ?? 0,
        machineName: json['machine_name'] ?? 'Không rõ tên',
      );
}

class ProductBasicInfo {
  final int productId;
  final String? itemCode;
  ProductBasicInfo({required this.productId, this.itemCode});
  factory ProductBasicInfo.fromJson(Map<String, dynamic> json) =>
      ProductBasicInfo(
        productId: json['product_id'] ?? 0,
        itemCode: json['item_code'],
      );
}

class MachineProductHistory {
  final int id;
  final int machineId;
  final int productId;
  final DateTime startTime;
  final DateTime? endTime;
  final String? notes;
  final ProductBasicInfo? product;
  final MachineBasicInfo? machine; // Bổ sung

  MachineProductHistory({
    required this.id,
    required this.machineId,
    required this.productId,
    required this.startTime,
    this.endTime,
    this.notes,
    this.product,
    this.machine,
  });

  factory MachineProductHistory.fromJson(Map<String, dynamic> json) {
    return MachineProductHistory(
      id: json['id'] ?? 0,
      machineId: json['machine_id'] ?? 0,
      productId: json['product_id'] ?? 0,
      startTime: DateTime.parse(json['start_time']).toLocal(),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time']).toLocal()
          : null,
      notes: json['notes'],
      product: json['product'] != null
          ? ProductBasicInfo.fromJson(json['product'])
          : null,
      machine: json['machine'] != null
          ? MachineBasicInfo.fromJson(json['machine'])
          : null,
    );
  }
}
