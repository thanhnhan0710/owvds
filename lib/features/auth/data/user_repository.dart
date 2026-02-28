import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../domain/user_model.dart';

class UserRepository {
  final Dio _dio = ApiClient().dio;

  // 1. Lấy danh sách Users
  Future<List<User>> getUsers(
      {int skip = 0, int limit = 100, String? search}) async {
    try {
      final response = await _dio.get(
        '/api/v1/users/', // Lưu ý: Đảm bảo có dấu gạch chéo cuối nếu backend yêu cầu, hoặc không
        queryParameters: {
          'skip': skip,
          'limit': limit,
          // [FIX 1]: Backend của bạn dùng 'keyword', không phải 'q'
          if (search != null && search.isNotEmpty) 'keyword': search,
        },
      );

      if (response.statusCode == 200) {
        // [FIX 2 - QUAN TRỌNG]: Backend trả về { "data": [...], "total": ... }
        // Nên bạn phải chọc vào key ['data'] mới lấy được List.
        final List<dynamic> data = response.data['data'];

        return data.map((json) => User.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to load users: $e");
    }
  }

  // ... Các hàm create, update, delete giữ nguyên ...
  // (Tôi để lại code create/update bên dưới để bạn tiện copy full file nếu cần)

  // 2. Tạo User mới
  Future<User> createUser(User user, String password) async {
    try {
      final response = await _dio.post(
        '/api/v1/users/',
        data: user.toJson(password: password),
      );
      return User.fromJson(response.data);
    } on DioException catch (e) {
      // Xử lý lỗi đẹp hơn một chút để lấy message từ backend
      throw Exception(e.response?.data['detail'] ?? "Failed to create user");
    }
  }

  // 3. Cập nhật User
  Future<User> updateUser(int userId, User user, {String? password}) async {
    try {
      final response = await _dio.put(
        '/api/v1/users/$userId',
        data: user.toJson(password: password),
      );
      return User.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? "Failed to update user");
    }
  }

  // 4. Xóa User
  Future<void> deleteUser(int userId) async {
    try {
      await _dio.delete('/api/v1/users/$userId');
    } catch (e) {
      throw Exception("Failed to delete user: $e");
    }
  }
}
