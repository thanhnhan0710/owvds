class Shift {
  final int id;
  final String name;
  final String note;

  Shift({
    required this.id,
    required this.name,
    required this.note,
  });

  // Map từ JSON của FastAPI (department_id, department_name...)
  factory Shift.fromJson(Map<String, dynamic> json) {
    return Shift(
      id: json['shift_id'] ?? 0,
      name: json['shift_name'] ?? '',
      note: json['note'] ?? '',
    );
  }

  get startTime => null;

  get endTime => null;

  // Map ngược lại để gửi lên API
  Map<String, dynamic> toJson() {
    return {
      'shift_name': name,
      'note': note,
    };
  }
}
