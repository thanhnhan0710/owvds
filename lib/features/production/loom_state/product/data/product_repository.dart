import 'package:dio/dio.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:owvds/core/network/api_client.dart';
import '../domain/product_model.dart';

class ProductRepository {
  final Dio _dio = ApiClient().dio;

  // [CẬP NHẬT] Thêm tùy chọn lọc theo Loại
  Future<List<Product>> getProducts({int? typeId}) async {
    try {
      final Map<String, dynamic> queryParams = {'skip': 0, 'limit': 1000};
      if (typeId != null) {
        queryParams['product_type_id'] = typeId;
      }

      final response = await _dio.get(
        '/api/v1/products/',
        queryParameters: queryParams,
      );
      if (response.data is List) {
        return (response.data as List).map((e) => Product.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to load products: $e");
    }
  }

  Future<List<Product>> searchProducts(String keyword) async {
    try {
      final response = await _dio.get(
        '/api/v1/products/search',
        queryParameters: {'keyword': keyword, 'skip': 0, 'limit': 1000},
      );
      if (response.data is List) {
        return (response.data as List).map((e) => Product.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to search products: $e");
    }
  }

  Future<void> createProduct(Product item) async {
    try {
      await _dio.post('/api/v1/products/', data: item.toJson());
    } catch (e) {
      throw Exception("Failed to create product: $e");
    }
  }

  Future<void> updateProduct(Product item) async {
    try {
      await _dio.put('/api/v1/products/${item.id}', data: item.toJson());
    } catch (e) {
      throw Exception("Failed to update product: $e");
    }
  }

  Future<void> deleteProduct(int id) async {
    try {
      await _dio.delete('/api/v1/products/$id');
    } catch (e) {
      throw Exception("Failed to delete product: $e");
    }
  }

  Future<String> uploadProductImage(PlatformFile file) async {
    try {
      if (file.bytes == null) throw Exception("File empty");

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          file.bytes!,
          filename: file.name,
          contentType: MediaType('image', 'jpeg'),
        ),
      });

      final response = await _dio.post(
        '/api/v1/upload/product',
        data: formData,
      );
      return response.data['url'] ?? '';
    } catch (e) {
      throw Exception("Failed to upload image: $e");
    }
  }

  Future<Map<String, dynamic>> importExcel(PlatformFile file) async {
    try {
      if (file.bytes == null) {
        throw Exception(
          "File data is empty. Please ensure you are picking a file with data.",
        );
      }

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(file.bytes!, filename: file.name),
      });

      final response = await _dio.post(
        '/api/v1/products/import',
        data: formData,
      );
      return response.data;
    } on DioException catch (e) {
      debugPrint("❌ IMPORT ERROR: ${e.response?.data}");
      throw Exception(e.response?.data['detail'] ?? e.message);
    } catch (e) {
      throw Exception("Failed to import products: $e");
    }
  }

  Future<Uint8List> exportExcel() async {
    try {
      final response = await _dio.get(
        '/api/v1/products/export',
        options: Options(responseType: ResponseType.bytes),
      );

      return Uint8List.fromList(response.data);
    } on DioException catch (e) {
      debugPrint("❌ EXPORT ERROR: ${e.response?.data}");
      throw Exception(e.message);
    } catch (e) {
      throw Exception("Failed to export products: $e");
    }
  }
}
