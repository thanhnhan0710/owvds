import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../../../core/network/api_client.dart';
import '../domain/material_model.dart';

class MaterialRepository {
  final Dio _dio = ApiClient().dio;

  Future<int> getMaterialCount() async {
    try {
      final response = await _dio.get('/api/v1/materials/count');
      return response.data as int;
    } catch (e) {
      return 0;
    }
  }

  Future<List<MaterialItem>> getMaterials({
    int skip = 0,
    int limit = 200,
    String? search,
    int? typeId,
    int? supplierId,
  }) async {
    try {
      final queryParams = <String, dynamic>{'skip': skip, 'limit': limit};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (typeId != null) queryParams['type_id'] = typeId;
      if (supplierId != null) queryParams['supplier_id'] = supplierId;

      final response = await _dio.get(
        '/api/v1/materials/',
        queryParameters: queryParams,
      );
      if (response.data is List) {
        return (response.data as List)
            .map((e) => MaterialItem.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception("Lỗi khi tải danh sách NVL: $e");
    }
  }

  Future<void> createMaterial(MaterialItem material) async {
    try {
      await _dio.post('/api/v1/materials/', data: material.toJson());
    } catch (e) {
      throw Exception("Lỗi khi tạo NVL: $e");
    }
  }

  Future<void> updateMaterial(MaterialItem material) async {
    try {
      await _dio.put(
        '/api/v1/materials/${material.materialId}',
        data: material.toJson(),
      );
    } catch (e) {
      throw Exception("Lỗi khi cập nhật NVL: $e");
    }
  }

  Future<void> deleteMaterial(int id) async {
    try {
      await _dio.delete('/api/v1/materials/$id');
    } catch (e) {
      throw Exception("Lỗi khi xóa NVL: $e");
    }
  }

  // Hàm xuất Excel trả về dữ liệu Byte
  Future<Uint8List> exportExcel({int? typeId, int? supplierId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (typeId != null) queryParams['type_id'] = typeId;
      if (supplierId != null) queryParams['supplier_id'] = supplierId;

      final response = await _dio.get<List<int>>(
        '/api/v1/materials/export/excel',
        queryParameters: queryParams,
        options: Options(
          responseType: ResponseType.bytes,
        ), // Ép kiểu nhận về là bytes
      );

      return Uint8List.fromList(response.data!);
    } catch (e) {
      throw Exception("Lỗi khi xuất file Excel: $e");
    }
  }
}
