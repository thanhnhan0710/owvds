class MachineType {
  final int id;
  final String typeName;
  final String? description;

  MachineType({required this.id, required this.typeName, this.description});

  factory MachineType.fromJson(Map<String, dynamic> json) {
    return MachineType(
      id: json['machine_type_id'] ?? 0,
      typeName: json['type_name'] ?? '',
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() => {
    'type_name': typeName,
    'description': description,
  };
}
