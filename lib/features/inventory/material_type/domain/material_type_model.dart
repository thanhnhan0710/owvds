class MaterialType {
  final int typeId;
  final String typeName;
  final String? description;

  MaterialType({
    required this.typeId,
    required this.typeName,
    this.description,
  });

  factory MaterialType.fromJson(Map<String, dynamic> json) {
    return MaterialType(
      typeId: json['type_id'] ?? 0,
      typeName: json['type_name'] ?? '',
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'type_name': typeName, 'description': description};
  }
}
