import 'package:dio/dio.dart';
import 'package:owvds/core/network/api_client.dart';
import 'dart:typed_data';
import '../domain/machine_assignment_model.dart';

class MachineAssignmentRepository {
  final Dio _dio = ApiClient().dio;

  // 1. Gán sản phẩm mới cho máy
  Future<MachineProductHistory> assignProduct(
    int machineId,
    int productId, {
    String? notes,
  }) async {
    final response = await _dio.post(
      '/api/v1/machine-assignments/$machineId/assign',
      data: {'product_id': productId, 'notes': notes},
    );
    return MachineProductHistory.fromJson(response.data);
  }

  // 2. Dừng sản phẩm hiện tại
  Future<void> stopProduct(int machineId) async {
    await _dio.post('/api/v1/machine-assignments/$machineId/stop');
  }

  // 3. Lấy sản phẩm đang chạy hiện tại
  Future<MachineProductHistory?> getCurrentProduct(int machineId) async {
    try {
      final response = await _dio.get(
        '/api/v1/machine-assignments/$machineId/current',
      );
      return MachineProductHistory.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null; // Máy đang trống
      }
      rethrow;
    }
  }

  // 4. Lấy tất cả máy đang chạy để hiện lên Card
  Future<List<MachineProductHistory>> getAllActiveAssignments() async {
    final response = await _dio.get(
      '/api/v1/machine-assignments/status/active-all',
    );
    return (response.data as List)
        .map((e) => MachineProductHistory.fromJson(e))
        .toList();
  }

  // 5. Lấy lịch sử chạy máy của 1 máy (Đã thêm lọc ngày)
  Future<List<MachineProductHistory>> getHistory(
    int machineId, {
    int skip = 0,
    int limit = 50,
    String? startDate,
    String? endDate,
  }) async {
    final response = await _dio.get(
      '/api/v1/machine-assignments/$machineId/history',
      queryParameters: {
        'skip': skip,
        'limit': limit,
        'start_date': ?startDate,
        'end_date': ?endDate,
      },
    );
    return (response.data as List)
        .map((e) => MachineProductHistory.fromJson(e))
        .toList();
  }

  // 6. Lấy lịch sử toàn cục (Đã thêm lọc ngày và keyword)
  Future<List<MachineProductHistory>> getGlobalHistory({
    String? keyword,
    int skip = 0,
    int limit = 50,
    String? startDate,
    String? endDate,
  }) async {
    final response = await _dio.get(
      '/api/v1/machine-assignments/history/all/global',
      queryParameters: {
        'keyword': keyword,
        'skip': skip,
        'limit': limit,
        'start_date': ?startDate,
        'end_date': ?endDate,
      },
    );
    return (response.data as List)
        .map((e) => MachineProductHistory.fromJson(e))
        .toList();
  }

  // 7. Tìm kiếm lịch sử của 1 máy
  Future<List<MachineProductHistory>> searchHistory(
    int machineId,
    String keyword,
  ) async {
    final response = await _dio.get(
      '/api/v1/machine-assignments/$machineId/history/search',
      queryParameters: {'keyword': keyword},
    );
    return (response.data as List)
        .map((e) => MachineProductHistory.fromJson(e))
        .toList();
  }

  // 8. Cập nhật lịch sử
  Future<void> updateHistory(
    int historyId,
    Map<String, dynamic> updateData,
  ) async {
    await _dio.put(
      '/api/v1/machine-assignments/history/$historyId',
      data: updateData,
    );
  }

  // 9. Xóa lịch sử
  Future<void> deleteHistory(int historyId) async {
    await _dio.delete('/api/v1/machine-assignments/history/$historyId');
  }

  // 10. Xuất Excel toàn cục
  Future<Uint8List> exportGlobalHistory({
    String? keyword,
    String? startDate,
    String? endDate,
  }) async {
    final response = await _dio.get(
      '/api/v1/machine-assignments/export/global',
      queryParameters: {
        'keyword': keyword,
        'start_date': ?startDate,
        'end_date': ?endDate,
      },
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data;
  }

  // 11. Xuất Excel 1 máy
  Future<Uint8List> exportSingleMachineHistory(
    int machineId, {
    String? startDate,
    String? endDate,
  }) async {
    final response = await _dio.get(
      '/api/v1/machine-assignments/export/$machineId',
      queryParameters: {'start_date': ?startDate, 'end_date': ?endDate},
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data;
  }
}
