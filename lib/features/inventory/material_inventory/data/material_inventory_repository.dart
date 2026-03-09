import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../domain/material_inventory_model.dart';

class MaterialInventoryRepository {
  final Dio _dio = ApiClient().dio;

  static const String _endpoint = '/api/v1/inventories/';

  // Cập nhật hàm này bên trong file material_inventory_repository.dart
  Future<List<MaterialInventory>> getInventories({
    int skip = 0,
    int limit = 100,
    int? warehouseId,
    int? materialId,
  }) async {
    try {
      final queryParams = <String, dynamic>{'skip': skip, 'limit': limit};

      if (warehouseId != null) queryParams['warehouse_id'] = warehouseId;
      if (materialId != null) queryParams['material_id'] = materialId;

      final response = await _dio.get(_endpoint, queryParameters: queryParams);

      if (response.data is List) {
        return (response.data as List)
            .map((e) => MaterialInventory.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to load material inventories: $e");
    }
  }

  Future<List<MaterialInventory>> searchInventories(String keyword) async {
    try {
      // Backend api might filter by material_code/batch_code via search if supported
      final response = await _dio.get(
        _endpoint,
        queryParameters: {'search': keyword, 'skip': 0, 'limit': 100},
      );
      if (response.data is List) {
        return (response.data as List)
            .map((e) => MaterialInventory.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception("Material inventories not found: $e");
    }
  }

  Future<void> createInventory(MaterialInventory inventory) async {
    try {
      final data = inventory.toJson();
      data.remove('inventory_id');

      await _dio.post(_endpoint, data: data);
    } catch (e) {
      throw Exception("Failed to create material inventory: $e");
    }
  }

  Future<void> updateInventory(MaterialInventory inventory) async {
    try {
      await _dio.put('$_endpoint${inventory.id}', data: inventory.toJson());
    } catch (e) {
      throw Exception("Failed to update material inventory: $e");
    }
  }

  Future<void> deleteInventory(int id) async {
    try {
      await _dio.delete('$_endpoint$id');
    } catch (e) {
      throw Exception("Failed to delete material inventory: $e");
    }
  }
}
