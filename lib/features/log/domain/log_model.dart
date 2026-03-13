class LogModel {
  final int id;
  final int? userId;
  final String action; // CREATE, UPDATE, DELETE
  final String targetType; // Product, Order...
  final int? targetId;
  final String? description;
  final Map<String, dynamic>? changes; // {"old": {...}, "new": {...}}
  final String? ipAddress;
  final DateTime timestamp;
  final String? userEmail; // Tên/Email người làm (Backend join bảng User)

  LogModel({
    required this.id,
    this.userId,
    required this.action,
    required this.targetType,
    this.targetId,
    this.description,
    this.changes,
    this.ipAddress,
    required this.timestamp,
    this.userEmail,
  });

  factory LogModel.fromJson(Map<String, dynamic> json) {
    return LogModel(
      id: json['id'] ?? 0,
      userId: json['user_id'],
      action: json['action'] ?? '',
      targetType: json['target_type'] ?? '',
      targetId: json['target_id'],
      description: json['description'],
      // Parse JSON changes an toàn
      changes: json['changes'] != null ? Map<String, dynamic>.from(json['changes']) : null,
      ipAddress: json['ip_address'],
      timestamp: DateTime.parse(json['timestamp']),
      userEmail: json['user_email'] ?? 'Unknown',
    );
  }
}