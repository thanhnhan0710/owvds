import 'package:dio/dio.dart';
import 'package:owvds/core/network/api_client.dart';

import '../domain/product_type_model.dart';

class ProductTypeRepository {
  final Dio _dio = ApiClient().dio;

  Future<List<ProductType>> getProductTypes() async {
    try {
      final response = await _dio.get('/api/v1/product-types/');
      if (response.data is List) {
        return (response.data as List)
            .map((e) => ProductType.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to load product types: $e");
    }
  }

  Future<List<ProductType>> searchProductTypes(String keyword) async {
    try {
      final response = await _dio.get(
        '/api/v1/product-types/search',
        queryParameters: {'keyword': keyword, 'skip': 0, 'limit': 1000},
      );
      if (response.data is List) {
        return (response.data as List)
            .map((e) => ProductType.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to search product types: $e");
    }
  }

  Future<void> createProductType(ProductType item) async {
    try {
      await _dio.post('/api/v1/product-types/', data: item.toJson());
    } catch (e) {
      throw Exception("Failed to create product type: $e");
    }
  }

  Future<void> updateProductType(ProductType item) async {
    try {
      await _dio.put('/api/v1/product-types/${item.id}', data: item.toJson());
    } catch (e) {
      throw Exception("Failed to update product type: $e");
    }
  }

  Future<void> deleteProductType(int id) async {
    try {
      await _dio.delete('/api/v1/product-types/$id');
    } catch (e) {
      throw Exception("Failed to delete product type: $e");
    }
  }
}
