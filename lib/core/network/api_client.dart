import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_endpoints.dart'; // <--- Import file cấu hình

class ApiClient {
  final Dio dio;

  ApiClient._internal() : dio = Dio() {
    // 1. Sử dụng biến từ ApiEndpoints
    // Lưu ý: Repository của bạn đang gọi '/api/v1/products', nên baseUrl ở đây chỉ để là serverDomain thôi
    dio.options.baseUrl = ApiEndpoints.serverDomain; 

    dio.options.connectTimeout = const Duration(seconds: 15);
    dio.options.receiveTimeout = const Duration(seconds: 15);
    
    // 2. Interceptor (Giữ nguyên logic của bạn)
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('access_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
}