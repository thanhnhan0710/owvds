import 'package:dio/dio.dart';
import '../../../../../core/network/api_client.dart';
import '../domain/supplier_model.dart';

class SupplierRepository {
  final Dio _dio = ApiClient().dio;

  Future<int> getSupplierCount() async {
    try {
      final response = await _dio.get('/api/v1/suppliers/count');
      return response.data as int;
    } catch (e) {
      return 0; // Trả về 0 nếu API chưa được implement ở Backend
    }
  }

  Future<List<Supplier>> getSuppliers({
    int skip = 0,
    int limit = 200,
    String? search,
    int? categoryId,
    bool? isActive,
  }) async {
    try {
      final queryParams = <String, dynamic>{'skip': skip, 'limit': limit};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (categoryId != null) queryParams['category_id'] = categoryId;
      if (isActive != null) queryParams['is_active'] = isActive;

      final response = await _dio.get(
        '/api/v1/suppliers/',
        queryParameters: queryParams,
      );
      if (response.data is List) {
        return (response.data as List)
            .map((e) => Supplier.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to load suppliers: $e");
    }
  }

  Future<void> createSupplier(Supplier supplier) async {
    try {
      await _dio.post('/api/v1/suppliers/', data: supplier.toJson());
    } catch (e) {
      throw Exception("Failed to create supplier: $e");
    }
  }

  Future<void> updateSupplier(Supplier supplier) async {
    try {
      await _dio.put(
        '/api/v1/suppliers/${supplier.supplierId}',
        data: supplier.toJson(),
      );
    } catch (e) {
      throw Exception("Failed to update supplier: $e");
    }
  }

  Future<void> deleteSupplier(int id) async {
    try {
      await _dio.delete('/api/v1/suppliers/$id');
    } catch (e) {
      throw Exception("Failed to delete supplier: $e");
    }
  }
}
