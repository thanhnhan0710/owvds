class User {
  final int id;
  final String email;
  final String fullName;
  final String phoneNumber;
  final String role;
  final bool isActive;
  final bool isSuperuser;
  
  final int? employeeId;
  final String? employeeName; // Tên nhân viên để hiển thị
  final String? lastLogin;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    this.phoneNumber = '',
    required this.role,
    this.isActive = true,
    this.isSuperuser = false,
    this.employeeId,
    this.employeeName,
    this.lastLogin,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Logic lấy tên nhân viên dựa trên class Employee bạn cung cấp:
    // Kiểm tra xem backend có trả về object 'employee' không
    String? empName;
    if (json['employee'] != null && json['employee'] is Map) {
      // Lấy 'full_name' đúng theo key trong Employee.toJson()
      empName = json['employee']['full_name']; 
    }

    return User(
      id: json['user_id'] ?? json['id'] ?? 0,
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      role: json['role'] ?? 'staff',
      isActive: json['is_active'] ?? true,
      isSuperuser: json['is_superuser'] ?? false,
      employeeId: json['employee_id'],
      employeeName: empName, // Gán tên nhân viên lấy được
      lastLogin: json['last_login'],
    );
  }

  // ... (Phần toJson giữ nguyên)
  Map<String, dynamic> toJson({String? password}) {
    final Map<String, dynamic> data = {
      'email': email,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'role': role,
      'is_active': isActive,
      'is_superuser': isSuperuser,
      'employee_id': employeeId,
    };
    if (password != null && password.isNotEmpty) {
      data['password'] = password;
    }
    return data;
  }
}