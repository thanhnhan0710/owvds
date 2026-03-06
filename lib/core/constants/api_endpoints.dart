class ApiEndpoints {
  // [CẤU HÌNH GỐC] Chỉ cần sửa duy nhất dòng này khi đổi Server/IP
  static const String serverDomain = 'http://192.168.1.100:8002';

  // Base URL cho API (tự động nối thêm /api/v1)
  static const String baseUrl = '$serverDomain/api/v1';

  static const String authLogin = '$baseUrl/login/access-token/';
  static const String usersMe = '$baseUrl/users/me/';

  // [MỚI] Hàm Helper xử lý ảnh: Tự động nối Domain nếu là đường dẫn tương đối
  static String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';

    // Nếu ảnh đã là link online (http...) thì giữ nguyên
    if (path.contains('http')) return path;

    // Xử lý nối chuỗi an toàn (tránh trường hợp thiếu hoặc thừa dấu /)
    if (path.startsWith('/')) {
      return '$serverDomain$path';
    }
    return '$serverDomain/$path';
  }
}
