class WorkSchedule {
  final int id;
  final String workDate;
  final int employeeId;
  final int shiftId;

  // Nested Objects (Read-only for display)
  final String? employeeName;
  final String? shiftName;
  final String? startTime;
  final String? endTime;

  // [MỚI] Trường lưu số giờ tăng ca
  final double overtimeHours;

  WorkSchedule({
    required this.id,
    required this.workDate,
    required this.employeeId,
    required this.shiftId,
    this.employeeName,
    this.shiftName,
    this.startTime,
    this.endTime,
    this.overtimeHours = 0.0, // Mặc định là 0
  });

  factory WorkSchedule.fromJson(Map<String, dynamic> json) {
    // Parse nested objects
    final empObj = json['employee'];
    final shiftObj = json['shift'];

    return WorkSchedule(
      id: json['id'] ?? 0,
      workDate: json['work_date'] ?? '',
      employeeId: json['employee_id'] ?? 0,
      shiftId: json['shift_id'] ?? 0,

      employeeName: empObj != null ? empObj['full_name'] : null,
      shiftName: shiftObj != null ? shiftObj['shift_name'] : null,
      startTime: shiftObj != null ? shiftObj['start_time'] : null,
      endTime: shiftObj != null ? shiftObj['end_time'] : null,

      // [MỚI] Parse an toàn từ dynamic sang double
      overtimeHours: (json['overtime_hours'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'work_date': workDate,
      'employee_id': employeeId,
      'shift_id': shiftId,
      'overtime_hours': overtimeHours, // [MỚI] Gửi số giờ tăng ca lên BE
    };
  }
}
