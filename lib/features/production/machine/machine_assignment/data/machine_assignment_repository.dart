import 'package:dio/dio.dart';
import 'package:owvds/core/network/api_client.dart';
import 'dart:typed_data';
import '../domain/machine_assignment_model.dart';

class MachineAssignmentRepository {
  final Dio _dio = ApiClient().dio;

  // 1. Gán sản phẩm mới cho máy
  Future<MachineProductHistory> assignProduct(
    int machineId,
    int productId,
    int lineNumber, {
    String? notes,
  }) async {
    final response = await _dio.post(
      '/api/v1/machine-assignments/$machineId/assign',
      data: {
        'product_id': productId,
        'line_number': lineNumber,
        'notes': notes,
      },
    );
    return MachineProductHistory.fromJson(response.data);
  }

  // 2. Dừng sản phẩm hiện tại
  Future<void> stopProduct(int machineId, int lineNumber) async {
    await _dio.post(
      '/api/v1/machine-assignments/$machineId/stop',
      queryParameters: {'line_number': lineNumber},
    );
  }

  // 3. Lấy sản phẩm đang chạy hiện tại
  Future<List<MachineProductHistory>> getCurrentProductLines(
    int machineId,
  ) async {
    try {
      final response = await _dio.get(
        '/api/v1/machine-assignments/$machineId/current',
      );
      return (response.data as List)
          .map((e) => MachineProductHistory.fromJson(e))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return [];
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

  // 5. Lấy lịch sử chạy máy của 1 máy (ĐÃ FIX LỖI 422: Loại bỏ tham số null)
  Future<List<MachineProductHistory>> getHistory(
    int machineId, {
    int skip = 0,
    int limit = 50,
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, dynamic>{'skip': skip, 'limit': limit};

    if (startDate != null && startDate.isNotEmpty) {
      queryParams['start_date'] = startDate;
    }
    if (endDate != null && endDate.isNotEmpty) {
      queryParams['end_date'] = endDate;
    }

    final response = await _dio.get(
      '/api/v1/machine-assignments/$machineId/history',
      queryParameters: queryParams,
    );
    return (response.data as List)
        .map((e) => MachineProductHistory.fromJson(e))
        .toList();
  }

  // 6. Lấy lịch sử toàn cục (ĐÃ FIX LỖI 422)
  Future<List<MachineProductHistory>> getGlobalHistory({
    String? keyword,
    int skip = 0,
    int limit = 50,
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, dynamic>{'skip': skip, 'limit': limit};

    if (keyword != null && keyword.isNotEmpty) queryParams['keyword'] = keyword;
    if (startDate != null && startDate.isNotEmpty) {
      queryParams['start_date'] = startDate;
    }
    if (endDate != null && endDate.isNotEmpty) {
      queryParams['end_date'] = endDate;
    }

    final response = await _dio.get(
      '/api/v1/machine-assignments/history/all/global',
      queryParameters: queryParams,
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

  // 10. Xuất Excel toàn cục (ĐÃ FIX LỖI 422)
  Future<Uint8List> exportGlobalHistory({
    String? keyword,
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, dynamic>{};

    if (keyword != null && keyword.isNotEmpty) queryParams['keyword'] = keyword;
    if (startDate != null && startDate.isNotEmpty) {
      queryParams['start_date'] = startDate;
    }
    if (endDate != null && endDate.isNotEmpty) {
      queryParams['end_date'] = endDate;
    }

    final response = await _dio.get(
      '/api/v1/machine-assignments/export/global',
      queryParameters: queryParams,
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data;
  }

  // 11. Xuất Excel 1 máy (ĐÃ FIX LỖI 422)
  Future<Uint8List> exportSingleMachineHistory(
    int machineId, {
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, dynamic>{};

    if (startDate != null && startDate.isNotEmpty) {
      queryParams['start_date'] = startDate;
    }
    if (endDate != null && endDate.isNotEmpty) {
      queryParams['end_date'] = endDate;
    }

    final response = await _dio.get(
      '/api/v1/machine-assignments/export/$machineId',
      queryParameters: queryParams,
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data;
  }
}
