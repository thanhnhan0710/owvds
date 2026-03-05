import 'package:dio/dio.dart';
import '../../../../../core/network/api_client.dart';
import '../domain/supplier_category_model.dart';

class SupplierCategoryRepository {
  final Dio _dio = ApiClient().dio;

  Future<int> getCategoryCount() async {
    try {
      final response = await _dio.get('/api/v1/supplier-categories/count');
      return response.data as int;
    } catch (e) {
      return 0; // Trả về 0 nếu API đếm chưa được implement ở Backend
    }
  }

  Future<List<SupplierCategory>> getCategories({
    int skip = 0,
    int limit = 200,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{'skip': skip, 'limit': limit};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await _dio.get(
        '/api/v1/supplier-categories/',
        queryParameters: queryParams,
      );
      if (response.data is List) {
        return (response.data as List)
            .map((e) => SupplierCategory.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to load supplier categories: $e");
    }
  }

  Future<void> createCategory(SupplierCategory category) async {
    try {
      await _dio.post('/api/v1/supplier-categories/', data: category.toJson());
    } catch (e) {
      throw Exception("Failed to create supplier category: $e");
    }
  }

  Future<void> updateCategory(SupplierCategory category) async {
    try {
      await _dio.put(
        '/api/v1/supplier-categories/${category.categoryId}',
        data: category.toJson(),
      );
    } catch (e) {
      throw Exception("Failed to update supplier category: $e");
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      await _dio.delete('/api/v1/supplier-categories/$id');
    } catch (e) {
      throw Exception("Failed to delete supplier category: $e");
    }
  }
}
