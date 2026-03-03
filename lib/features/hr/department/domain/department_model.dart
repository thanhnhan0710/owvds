class Department {
  final int id;
  final String name;
  final String description;

  Department({
    required this.id,
    required this.name,
    required this.description,
  });

  // Map từ JSON của FastAPI (department_id, department_name...)
  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['department_id'] ?? 0,
      name: json['department_name'] ?? '',
      description: json['description'] ?? '',
    );
  }

  // Map ngược lại để gửi lên API
  Map<String, dynamic> toJson() {
    return {
      'department_name': name,
      'description': description,
    };
  }
}