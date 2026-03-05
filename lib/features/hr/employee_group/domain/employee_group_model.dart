class EmployeeGroup {
  final int id;
  final String name;
  final String? description;
  final int? departmentId;

  EmployeeGroup({
    required this.id,
    required this.name,
    this.description,
    this.departmentId,
  });

  factory EmployeeGroup.fromJson(Map<String, dynamic> json) {
    return EmployeeGroup(
      id: json['group_id'] ?? 0,
      name: json['group_name'] ?? '',
      description: json['description'],
      departmentId: json['department_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'group_name': name,
      if (description != null) 'description': description,
      if (departmentId != null) 'department_id': departmentId,
    };
  }

  EmployeeGroup copyWith({
    int? id,
    String? name,
    String? description,
    int? departmentId,
  }) {
    return EmployeeGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      departmentId: departmentId ?? this.departmentId,
    );
  }
}
