class Area {
  final int id;
  final String areaName;
  final String? description;

  Area({required this.id, required this.areaName, this.description});

  factory Area.fromJson(Map<String, dynamic> json) {
    return Area(
      id: json['area_id'] ?? 0,
      areaName: json['area_name'] ?? '',
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'area_name': areaName, 'description': description};
  }
}
