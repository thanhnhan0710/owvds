class SupplierCategory {
  final int categoryId;
  final String categoryName;
  final String? description;

  SupplierCategory({
    required this.categoryId,
    required this.categoryName,
    this.description,
  });

  factory SupplierCategory.fromJson(Map<String, dynamic> json) {
    return SupplierCategory(
      categoryId: json['category_id'] ?? 0,
      categoryName: json['category_name'] ?? '',
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'category_name': categoryName, 'description': description};
  }
}
