class MachineStatus {
  final int id;
  final String statusName;
  final String? colorCode;
  final String? description;

  MachineStatus({
    required this.id,
    required this.statusName,
    this.colorCode,
    this.description,
  });

  factory MachineStatus.fromJson(Map<String, dynamic> json) {
    return MachineStatus(
      id: json['status_id'] ?? 0,
      statusName: json['status_name'] ?? '',
      colorCode: json['color_code'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() => {
    'status_name': statusName,
    'color_code': colorCode,
    'description': description,
  };
}
