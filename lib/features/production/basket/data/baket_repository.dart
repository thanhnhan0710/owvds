import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart'; // [MỚI]
import 'package:http_parser/http_parser.dart'; // [MỚI]
import 'package:flutter/widgets.dart';
import 'package:owvds/features/production/basket/doamain/basket_model.dart';
import '../../../../core/network/api_client.dart';

class BasketRepository {
  final Dio _dio = ApiClient().dio;

  Future<List<Basket>> getBaskets() async {
    try {
      // [ĐÃ SỬA] Thêm queryParameters để ghi đè limit mặc định của Backend
      final response = await _dio.get(
        '/api/v1/baskets/',
        queryParameters: {'skip': 0, 'limit': 2000}, // Lấy tối đa 2000 rổ
      );

      if (response.data is List) {
        return (response.data as List).map((e) => Basket.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to load baskets: $e");
    }
  }

  Future<List<Basket>> searchBaskets(String keyword) async {
    try {
      final response = await _dio.get(
        '/api/v1/baskets/search/',
        queryParameters: {'keyword': keyword, 'skip': 0, 'limit': 100},
      );
      if (response.data is List) {
        return (response.data as List).map((e) => Basket.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to search baskets: $e");
    }
  }

  Future<void> createBasket(Basket item) async {
    try {
      await _dio.post('/api/v1/baskets/', data: item.toJson());
    } catch (e) {
      throw Exception("Failed to create basket: $e");
    }
  }

  Future<void> updateBasket(Basket item) async {
    try {
      await _dio.put('/api/v1/baskets/${item.id}', data: item.toJson());
    } catch (e) {
      throw Exception("Failed to update basket: $e");
    }
  }

  Future<void> deleteBasket(int id) async {
    try {
      await _dio.delete('/api/v1/baskets/$id');
    } catch (e) {
      throw Exception("Failed to delete basket: $e");
    }
  }

  // --- [MỚI] IMPORT EXCEL ---
  Future<Map<String, dynamic>> importExcel(PlatformFile file) async {
    try {
      if (file.bytes == null) throw Exception("Dữ liệu file trống.");

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          file.bytes!,
          filename: file.name,
          contentType: MediaType('application', 'vnd.ms-excel'),
        ),
      });

      final response = await _dio.post(
        '/api/v1/baskets/import',
        data: formData,
      );
      return response.data;
    } on DioException catch (e) {
      debugPrint("❌ IMPORT ERROR: ${e.response?.data}");
      throw Exception(
        e.response?.data['detail'] ?? "Lỗi không xác định từ Server.",
      );
    } catch (e) {
      throw Exception("Lỗi khi gửi file: $e");
    }
  }
}
