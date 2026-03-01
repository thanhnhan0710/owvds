import 'package:dio/dio.dart';
import 'package:owvds/core/network/api_client.dart';
import '../domain/machine_assignment_model.dart';

class MachineAssignmentRepository {
  final Dio _dio = ApiClient().dio;

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

  Future<void> stopProduct(int machineId) async {
    await _dio.post('/api/v1/machine-assignments/$machineId/stop');
  }

  Future<MachineProductHistory?> getCurrentProduct(int machineId) async {
    try {
      final response = await _dio.get(
        '/api/v1/machine-assignments/$machineId/current',
      );
      return MachineProductHistory.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<List<MachineProductHistory>> getHistory(
    int machineId, {
    int skip = 0,
    int limit = 50,
  }) async {
    final response = await _dio.get(
      '/api/v1/machine-assignments/$machineId/history',
      queryParameters: {'skip': skip, 'limit': limit},
    );
    return (response.data as List)
        .map((e) => MachineProductHistory.fromJson(e))
        .toList();
  }

  // [MỚI] Lấy tất cả máy đang chạy để hiện lên Card
  Future<List<MachineProductHistory>> getAllActiveAssignments() async {
    final res = await _dio.get('/api/v1/machine-assignments/status/active-all');
    return (res.data as List)
        .map((e) => MachineProductHistory.fromJson(e))
        .toList();
  }

  // [MỚI] Lấy lịch sử toàn cục
  Future<List<MachineProductHistory>> getGlobalHistory({
    String? keyword,
    int skip = 0,
    int limit = 100,
  }) async {
    final res = await _dio.get(
      '/api/v1/machine-assignments/history/all/global',
      queryParameters: {'keyword': keyword, 'skip': skip, 'limit': limit},
    );
    return (res.data as List)
        .map((e) => MachineProductHistory.fromJson(e))
        .toList();
  }

  // ==========================================
  // [MỚI] TÌM KIẾM, SỬA, XÓA LỊCH SỬ
  // ==========================================
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

  Future<void> updateHistory(
    int historyId,
    Map<String, dynamic> updateData,
  ) async {
    await _dio.put(
      '/api/v1/machine-assignments/history/$historyId',
      data: updateData,
    );
  }

  Future<void> deleteHistory(int historyId) async {
    await _dio.delete('/api/v1/machine-assignments/history/$historyId');
  }
}
