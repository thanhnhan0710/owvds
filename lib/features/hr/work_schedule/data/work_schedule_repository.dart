import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../domain/work_schedule_model.dart';

class WorkScheduleRepository {
  final Dio _dio = ApiClient().dio;

  Future<List<WorkSchedule>> getSchedules() async {
    try {
      final response = await _dio.get('/api/v1/work-schedules/');
      if (response.data is List) {
        return (response.data as List)
            .map((e) => WorkSchedule.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to load schedules: $e");
    }
  }

  Future<List<WorkSchedule>> searchSchedules(String keyword) async {
    try {
      final response = await _dio.get(
        '/api/v1/work-schedules/search/',
        queryParameters: {'keyword': keyword, 'skip': 0, 'limit': 100},
      );
      if (response.data is List) {
        return (response.data as List)
            .map((e) => WorkSchedule.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to search schedules: $e");
    }
  }

  // [QUAN TRỌNG] Hàm xử lý lỗi chung cho Create/Update
  String _handleDioError(Object e) {
    if (e is DioException) {
      // Bắt mã 409 Conflict
      if (e.response?.statusCode == 409) {
        return "DUPLICATE_SCHEDULE"; // Trả về mã lỗi đặc biệt để UI nhận biết
      }
      return "Lỗi máy chủ: ${e.response?.statusCode} - ${e.message}";
    }
    return "Lỗi hệ thống: $e";
  }

  Future<void> createSchedule(WorkSchedule item) async {
    try {
      await _dio.post('/api/v1/work-schedules/', data: item.toJson());
    } catch (e) {
      // Ném ra exception với nội dung đã xử lý
      throw Exception(_handleDioError(e));
    }
  }

  Future<void> updateSchedule(WorkSchedule item) async {
    try {
      await _dio.put('/api/v1/work-schedules/${item.id}', data: item.toJson());
    } catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  Future<void> deleteSchedule(int id) async {
    try {
      await _dio.delete('/api/v1/work-schedules/$id');
    } catch (e) {
      throw Exception("Failed to delete schedule: $e");
    }
  }
}
