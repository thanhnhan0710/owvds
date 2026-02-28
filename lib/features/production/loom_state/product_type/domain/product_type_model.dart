class ProductType {
  final int id;
  final String typeName;
  final String? description;

  ProductType({required this.id, required this.typeName, this.description});

  factory ProductType.fromJson(Map<String, dynamic> json) {
    return ProductType(
      id: json['product_type_id'] ?? 0,
      typeName: json['type_name'] ?? '',
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'type_name': typeName, 'description': description};
  }

  // Tiện ích để copy object khi update giao diện
  ProductType copyWith({int? id, String? typeName, String? description}) {
    return ProductType(
      id: id ?? this.id,
      typeName: typeName ?? this.typeName,
      description: description ?? this.description,
    );
  }
}
