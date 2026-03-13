// lib/features/production/notifications/domain/notification_model.dart

enum NotificationType {
  basketIn, // Vào rổ / Tạo phiếu dệt
  basketOut, // Ra rổ / Hoàn thành phiếu
  machine, // Đổi trạng thái máy / line
  inspection, // Kiểm tra chất lượng
  weighing, // Ghi sản lượng / cân ca
  system, // WebSocket refresh
}

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime time;
  bool isRead;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.time,
    this.isRead = false,
  });

  String get icon {
    switch (type) {
      case NotificationType.basketIn:
        return '🧺';
      case NotificationType.basketOut:
        return '✅';
      case NotificationType.machine:
        return '⚙️';
      case NotificationType.inspection:
        return '🔍';
      case NotificationType.weighing:
        return '⚖️';
      case NotificationType.system:
        return '🔔';
    }
  }

  int get colorValue {
    switch (type) {
      case NotificationType.basketIn:
        return 0xFF1565C0;
      case NotificationType.basketOut:
        return 0xFF2E7D32;
      case NotificationType.machine:
        return 0xFFE65100;
      case NotificationType.inspection:
        return 0xFF6A1B9A;
      case NotificationType.weighing:
        return 0xFF00838F;
      case NotificationType.system:
        return 0xFF546E7A;
    }
  }

  String get typeLabel {
    switch (type) {
      case NotificationType.basketIn:
        return 'Vào rổ';
      case NotificationType.basketOut:
        return 'Ra rổ';
      case NotificationType.machine:
        return 'Máy móc';
      case NotificationType.inspection:
        return 'Kiểm tra CL';
      case NotificationType.weighing:
        return 'Sản lượng';
      case NotificationType.system:
        return 'Hệ thống';
    }
  }
}
