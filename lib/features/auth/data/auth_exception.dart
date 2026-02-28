/// Mã lỗi chuẩn hóa cho các tác vụ liên quan đến Auth.
enum AuthErrorCode {
  // Lỗi xảy ra khi username/password sai
  loginFailed, 
  // Lỗi xảy ra khi Server không trả về Token
  tokenMissing,
  // Lỗi xảy ra khi không lấy được thông tin User (token không hợp lệ)
  userFetchFailed,
  // Lỗi mạng hoặc không kết nối được với Server
  networkError,
  // Lỗi không xác định hoặc lỗi từ phía Server
  systemError,
}

/// Custom Exception để chứa mã lỗi chuẩn hóa.
class AuthException implements Exception {
  final AuthErrorCode code;
  // Detail là thông tin chi tiết từ Server (vd: "User not found")
  final String? detail; 

  AuthException(this.code, {this.detail});

  @override
  String toString() => 'AuthException(code: $code, detail: $detail)';
}