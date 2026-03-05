import 'package:dio/dio.dart';
import '../../../../../core/network/api_client.dart';
import '../domain/material_type_model.dart';

class MaterialTypeRepository {
  final Dio _dio = ApiClient().dio;

  Future<int> getTypeCount() async {
    try {
      final response = await _dio.get('/api/v1/material-types/count');
      return response.data as int;
    } catch (e) {
      return 0;
    }
  }

  Future<List<MaterialType>> getTypes({
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
        '/api/v1/material-types/',
        queryParameters: queryParams,
      );
      if (response.data is List) {
        return (response.data as List)
            .map((e) => MaterialType.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception("Lỗi khi tải danh sách Loại NVL: $e");
    }
  }

  Future<void> createType(MaterialType type) async {
    try {
      await _dio.post('/api/v1/material-types/', data: type.toJson());
    } catch (e) {
      throw Exception("Lỗi khi tạo Loại NVL: $e");
    }
  }

  Future<void> updateType(MaterialType type) async {
    try {
      await _dio.put(
        '/api/v1/material-types/${type.typeId}',
        data: type.toJson(),
      );
    } catch (e) {
      throw Exception("Lỗi khi cập nhật Loại NVL: $e");
    }
  }

  Future<void> deleteType(int id) async {
    try {
      await _dio.delete('/api/v1/material-types/$id');
    } catch (e) {
      throw Exception("Lỗi khi xóa Loại NVL: $e");
    }
  }
}
