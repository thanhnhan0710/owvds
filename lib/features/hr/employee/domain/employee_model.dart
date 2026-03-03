class Employee {
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final String address;
  final String position;
  final int departmentId;
  final String note;
  final String avatarUrl;

  Employee({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.address,
    required this.position,
    required this.departmentId,
    required this.note,
    required this.avatarUrl,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['employee_id'] ?? 0,
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      position: json['position'] ?? '',
      departmentId: json['department_id'] ?? 0,
      note: json['note'] ?? '',
      avatarUrl: json['avatar_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'address': address,
      'position': position,
      'department_id': departmentId,
      'note': note,
      'avatar_url': avatarUrl,
    };
  }
}