class ProductShort {
  final int productId;
  final String itemCode;
  final String? imageUrl;

  ProductShort({
    required this.productId,
    required this.itemCode,
    this.imageUrl,
  });

  factory ProductShort.fromJson(Map<String, dynamic> json) {
    return ProductShort(
      productId: json['product_id'] ?? 0,
      itemCode: json['item_code'] ?? '',
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'item_code': itemCode,
      'image_url': imageUrl,
    };
  }
}

class Standard {
  final int standardId;
  final int productId;
  final String widthMm;
  final String thicknessMm;
  final String breakingStrengthDan;
  final String elongationAtLoadPercent;
  final String? curved;
  final String weftDensity;
  final String weightGm;
  final String? note;

  // Nested Object
  final ProductShort? product;

  Standard({
    required this.standardId,
    required this.productId,
    required this.widthMm,
    required this.thicknessMm,
    required this.breakingStrengthDan,
    required this.elongationAtLoadPercent,
    this.curved,
    required this.weftDensity,
    required this.weightGm,
    this.note,
    this.product,
  });

  factory Standard.fromJson(Map<String, dynamic> json) {
    return Standard(
      standardId: json['standard_id'] ?? 0,
      productId: json['product_id'] ?? 0,
      widthMm: json['width_mm'] ?? '',
      thicknessMm: json['thickness_mm'] ?? '',
      breakingStrengthDan: json['breaking_strength_dan'] ?? '',
      elongationAtLoadPercent: json['elongation_at_load_percent'] ?? '',
      curved: json['curved'],
      weftDensity: json['weft_density'] ?? '',
      weightGm: json['weight_gm'] ?? '',
      note: json['note'],
      product: json['product'] != null
          ? ProductShort.fromJson(json['product'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'width_mm': widthMm,
      'thickness_mm': thicknessMm,
      'breaking_strength_dan': breakingStrengthDan,
      'elongation_at_load_percent': elongationAtLoadPercent,
      'curved': curved,
      'weft_density': weftDensity,
      'weight_gm': weightGm,
      'note': note,
    };
  }
}
