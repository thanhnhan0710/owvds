import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../domain/warehouse_model.dart';

class WarehouseRepository {
  final Dio _dio = ApiClient().dio;

  // Endpoint cơ sở dựa trên file python: /api/v1/warehouses
  static const String _endpoint = '/api/v1/warehouses/';

  // Get all warehouses (có hỗ trợ phân trang nếu cần, ở đây mặc định lấy 100)
  Future<List<Warehouse>> getWarehouses() async {
    try {
      final response = await _dio.get(
        _endpoint,
        queryParameters: {'skip': 0, 'limit': 100},
      );

      if (response.data is List) {
        return (response.data as List)
            .map((e) => Warehouse.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to load warehouses: $e");
    }
  }

  // Search warehouses
  // Backend dùng query param 'search'
  Future<List<Warehouse>> searchWarehouses(String keyword) async {
    try {
      final response = await _dio.get(
        _endpoint,
        queryParameters: {'search': keyword, 'skip': 0, 'limit': 100},
      );
      if (response.data is List) {
        return (response.data as List)
            .map((e) => Warehouse.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception("Warehouses not found: $e");
    }
  }

  // Create
  Future<void> createWarehouse(Warehouse warehouse) async {
    try {
      // Backend mong đợi: warehouse_name, location, description
      // Không gửi ID khi tạo mới
      final data = warehouse.toJson();
      data.remove('warehouse_id');

      await _dio.post(_endpoint, data: data);
    } catch (e) {
      throw Exception("Failed to create warehouse: $e");
    }
  }

  // Update
  Future<void> updateWarehouse(Warehouse warehouse) async {
    try {
      await _dio.put(
        '$_endpoint/${warehouse.warehouseId}',
        data: warehouse.toJson(),
      );
    } catch (e) {
      throw Exception("Failed to update warehouse: $e");
    }
  }

  // Delete
  Future<void> deleteWarehouse(int id) async {
    try {
      await _dio.delete('$_endpoint/$id');
    } catch (e) {
      throw Exception("Failed to delete warehouse: $e");
    }
  }
}
