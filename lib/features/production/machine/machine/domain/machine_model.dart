// Sử dụng Fat Model để hứng dữ liệu Đa hình từ Backend
import 'package:owvds/features/area/domain/area_model.dart';
import 'package:owvds/features/production/machine/machine_status/domain/machine_status_model.dart';
import 'package:owvds/features/production/machine/machine_type/domain/machine_type_model.dart';

class Machine {
  final int id;
  final String machineName;
  final String? serialNumber;

  final int? machineTypeId;
  final int? statusId;
  final int? areaId;

  final String
  polymorphicType; // "weaving_machine", "dyeing_machine", "base_machine"

  // Các trường đặc thù của Máy Dệt
  final int? totalLines;
  final int? speed;
  final String? purpose;

  // Các trường đặc thù của Máy Nhuộm
  final double? capacityKg;
  final double? maxTemperature;

  // Object lồng nhau (Để hiển thị giao diện không cần fetch lại)
  final MachineType? machineType;
  final MachineStatus? status;
  final Area? area;

  Machine({
    required this.id,
    required this.machineName,
    this.serialNumber,
    this.machineTypeId,
    this.statusId,
    this.areaId,
    required this.polymorphicType,
    this.totalLines,
    this.speed,
    this.purpose,
    this.capacityKg,
    this.maxTemperature,
    this.machineType,
    this.status,
    this.area,
  });

  factory Machine.fromJson(Map<String, dynamic> json) {
    return Machine(
      id: json['machine_id'] ?? 0,
      machineName: json['machine_name'] ?? '',
      serialNumber: json['serial_number'],
      machineTypeId: json['machine_type_id'],
      statusId: json['status_id'],
      areaId: json['area_id'],
      polymorphicType: json['polymorphic_type'] ?? 'base_machine',
      totalLines: json['total_lines'],
      speed: json['speed'],
      purpose: json['purpose'],
      capacityKg: json['capacity_kg'] != null
          ? (json['capacity_kg'] as num).toDouble()
          : null,
      maxTemperature: json['max_temperature'] != null
          ? (json['max_temperature'] as num).toDouble()
          : null,
      machineType: json['machine_type'] != null
          ? MachineType.fromJson(json['machine_type'])
          : null,
      status: json['status'] != null
          ? MachineStatus.fromJson(json['status'])
          : null,
      area: json['area'] != null ? Area.fromJson(json['area']) : null,
    );
  }

  /// Tạo bản sao với một số field được thay đổi.
  /// [statusName]: chuỗi tên trạng thái dùng cho optimistic update
  /// (tạo MachineStatus tạm thời để hiển thị ngay trên UI trước khi reload).
  Machine copyWith({
    int? id,
    String? machineName,
    String? serialNumber,
    int? machineTypeId,
    int? statusId,
    int? areaId,
    String? polymorphicType,
    int? totalLines,
    int? speed,
    String? purpose,
    double? capacityKg,
    double? maxTemperature,
    MachineType? machineType,
    MachineStatus? status,
    String? statusName, // Tiện ích để optimistic update bằng tên chuỗi
    Area? area,
  }) {
    // Nếu chỉ truyền statusName mà không truyền status object,
    // tạo một MachineStatus tạm thời để hiển thị ngay trên UI.
    MachineStatus? resolvedStatus = status ?? this.status;
    if (statusName != null && status == null) {
      resolvedStatus = MachineStatus.fromJson({
        'status_id': this.statusId ?? 0,
        'status_name': statusName,
      });
    }

    return Machine(
      id: id ?? this.id,
      machineName: machineName ?? this.machineName,
      serialNumber: serialNumber ?? this.serialNumber,
      machineTypeId: machineTypeId ?? this.machineTypeId,
      statusId: statusId ?? this.statusId,
      areaId: areaId ?? this.areaId,
      polymorphicType: polymorphicType ?? this.polymorphicType,
      totalLines: totalLines ?? this.totalLines,
      speed: speed ?? this.speed,
      purpose: purpose ?? this.purpose,
      capacityKg: capacityKg ?? this.capacityKg,
      maxTemperature: maxTemperature ?? this.maxTemperature,
      machineType: machineType ?? this.machineType,
      status: resolvedStatus,
      area: area ?? this.area,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'machine_name': machineName,
      'serial_number': serialNumber,
      'machine_type_id': machineTypeId,
      'status_id': statusId,
      'area_id': areaId,
      'polymorphic_type': polymorphicType,
      'total_lines': totalLines,
      'speed': speed,
      'purpose': purpose,
      'capacity_kg': capacityKg,
      'max_temperature': maxTemperature,
    };
  }
}
