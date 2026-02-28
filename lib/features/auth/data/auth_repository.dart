import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../domain/user_model.dart';

class AuthRepository {
  final Dio _dio = ApiClient().dio;

  Future<User> login(String username, String password) async {
    try {
      // ---------------------------------------------------------
      // BƯỚC 1: LẤY TOKEN
      // ---------------------------------------------------------
      final response = await _dio.post(
        '/api/v1/login/access-token',
        data: {
          'username': username,
          'password': password,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType, 
          validateStatus: (status) => status! < 500, 
        ),
      );

      if (response.statusCode != 200) {
        throw Exception(response.data['detail'] ?? 'Đăng nhập thất bại (${response.statusCode})');
      }

      // ---------------------------------------------------------
      // BƯỚC 2: LƯU TOKEN
      // ---------------------------------------------------------
      final token = response.data['access_token'];
      if (token == null) {
        throw Exception("Server không trả về Token hợp lệ");
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', token);
      
      // ---------------------------------------------------------
      // BƯỚC 3: LẤY THÔNG TIN USER (PROFILE)
      // Dùng Header thủ công để đảm bảo Token được gửi NGAY LẬP TỨC
      // ---------------------------------------------------------
      final userResponse = await _dio.get(
        '/api/v1/users/me',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token', // Gửi Token thủ công
          },
        ),
      );
      
      // >>> CÁC LỆNH DEBUG QUAN TRỌNG <<<
      print("--- START DEBUG /users/me ---");
      print("DEBUG ME RESPONSE STATUS: ${userResponse.statusCode}");
      print("DEBUG ME RESPONSE DATA TYPE: ${userResponse.data.runtimeType}");
      print("DEBUG ME RESPONSE DATA: ${userResponse.data}");
      print("--- END DEBUG /users/me ---");
      
      if (userResponse.statusCode != 200) {
        // Nếu Server vẫn trả về 401/403, lỗi là do Token không hợp lệ
        throw Exception("Không thể lấy thông tin User. Status: ${userResponse.statusCode}");
      }

      // Nếu API trả về HTML hoặc String, nó sẽ crash ở đây.
      return User.fromJson(userResponse.data);

    } on DioException catch (e) {
      print("Dio Error: ${e.message}");
      if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.unknown) {
        throw Exception('Không thể kết nối đến Server. Hãy kiểm tra Docker và CORS.');
      }
      throw Exception(e.response?.data['detail'] ?? 'Lỗi hệ thống: ${e.message}');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }
}