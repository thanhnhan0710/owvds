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
