import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart'; // Đường dẫn tới file cấu hình Dio của bạn
import '../domain/log_model.dart';

class LogRepository {
  final Dio _dio = ApiClient().dio;

  // Lấy danh sách log có phân trang & lọc
  Future<List<LogModel>> getLogs({
    int skip = 0,
    int limit = 50,
    String? targetType,
    int? targetId,
    int? userId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final response = await _dio.get(
        '/api/v1/logs/', // Endpoint backend bạn đã viết
        queryParameters: {
          'skip': skip,
          'limit': limit,
          if (targetType != null) 'target_type': targetType,
          if (targetId != null) 'target_id': targetId,
          if (userId != null) 'user_id': userId,
          if (fromDate != null) 'from_date': fromDate.toIso8601String(),
          if (toDate != null) 'to_date': toDate.toIso8601String(),
        },
      );

      if (response.data is List) {
        return (response.data as List)
            .map((e) => LogModel.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception("Lỗi tải nhật ký: $e");
    }
  }

  Future<String> revertLog(int logId) async {
    try {
      final response = await _dio.post('/api/v1/logs/$logId/revert');
      // Trả về câu thông báo thành công từ backend
      return response.data['message'] ?? 'Hoàn tác thành công';
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? "Lỗi không xác định");
    } catch (e) {
      throw Exception("Đã xảy ra lỗi khi hoàn tác: $e");
    }
  }
}
