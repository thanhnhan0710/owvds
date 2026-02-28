import 'package:owvds/features/production/loom_state/product_type/domain/product_type_model.dart';

class Product {
  final int id;
  final String itemCode;
  final int? productTypeId; // [CẬP NHẬT] Thêm Khóa ngoại
  final String note;
  final String imageUrl;
  final ProductType?
  productType; // [CẬP NHẬT] Thêm Object để lấy Tên loại hiển thị UI

  Product({
    required this.id,
    required this.itemCode,
    this.productTypeId,
    required this.note,
    required this.imageUrl,
    this.productType,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['product_id'] ?? 0,
      itemCode: json['item_code'] ?? '',
      productTypeId: json['product_type_id'],
      note: json['note'] ?? '',
      imageUrl: json['image_url'] ?? '',
      // Map đối tượng product_type nếu Backend trả về (nhờ joinedload)
      productType: json['product_type'] != null
          ? ProductType.fromJson(json['product_type'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_code': itemCode,
      'product_type_id': productTypeId, // Gửi ID lên Backend khi lưu
      'note': note,
      'image_url': imageUrl,
    };
  }
}
