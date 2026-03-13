// lib/features/production/notifications/data/notification_service.dart
//
// SINGLETON – gọi từ bất kỳ dialog/screen nào:
//   NotificationService.instance.notifyBasketIn(...)
//   NotificationService.instance.notifyMachineStatus(...)
//   ...
//
// Dashboard lắng nghe qua NotificationCubit subscribe stream này.

import 'dart:async';
import '../domain/notification_model.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _controller = StreamController<AppNotification>.broadcast();
  Stream<AppNotification> get stream => _controller.stream;

  // ─── Public push ────────────────────────────────────────────────────────────

  void push(AppNotification n) => _controller.add(n);

  // Tạo phiếu dệt / vào rổ
  void notifyBasketIn({
    required String machineName,
    required String lineCode,
    required String basketCode,
    required String ticketCode,
  }) {
    push(
      AppNotification(
        id: _id(),
        type: NotificationType.basketIn,
        title: 'Vào rổ – $machineName L$lineCode',
        message: 'Rổ $basketCode | Phiếu $ticketCode đã tạo và bắt đầu chạy.',
        time: DateTime.now(),
      ),
    );
  }

  // Ra rổ / hoàn thành phiếu
  void notifyBasketOut({
    required String machineName,
    required String lineCode,
    required String ticketCode,
    required double grossWeight,
    required double netWeight,
  }) {
    push(
      AppNotification(
        id: _id(),
        type: NotificationType.basketOut,
        title: 'Ra rổ – $machineName L$lineCode',
        message:
            'Phiếu $ticketCode hoàn thành. Gross: ${grossWeight.toStringAsFixed(1)} kg | Net: ${netWeight.toStringAsFixed(1)} kg.',
        time: DateTime.now(),
      ),
    );
  }

  // Đổi trạng thái máy/line
  void notifyMachineStatus({
    required String machineName,
    required List<int> lines,
    required String newStatus,
    String? reason,
  }) {
    final lineStr = lines.map((l) => 'L$l').join(', ');
    final statusVi = _statusVi(newStatus);
    push(
      AppNotification(
        id: _id(),
        type: NotificationType.machine,
        title: 'Đổi trạng thái – $machineName ($lineStr)',
        message:
            'Chuyển sang: $statusVi${reason != null && reason.isNotEmpty ? ' | Lý do: $reason' : ''}.',
        time: DateTime.now(),
      ),
    );
  }

  // Kiểm tra chất lượng
  void notifyInspection({
    required String machineName,
    required String lineCode,
    required String ticketCode,
    required String stageName,
  }) {
    push(
      AppNotification(
        id: _id(),
        type: NotificationType.inspection,
        title: 'Kiểm tra CL – $machineName L$lineCode',
        message: 'Phiếu $ticketCode | Giai đoạn: $stageName đã được ghi nhận.',
        time: DateTime.now(),
      ),
    );
  }

  // Ghi sản lượng / cân ca
  void notifyWeighing({
    required String machineName,
    required int line,
    required String basketCode,
    required double netWeight,
    required double runWaste,
    required double setupWaste,
  }) {
    final totalWaste = runWaste + setupWaste;
    push(
      AppNotification(
        id: _id(),
        type: NotificationType.weighing,
        title: 'Ghi sản lượng – $machineName L$line',
        message:
            'Rổ $basketCode | Net: ${netWeight.toStringAsFixed(1)} kg | Phế: ${totalWaste.toStringAsFixed(1)} kg.',
        time: DateTime.now(),
      ),
    );
  }

  // WebSocket system events
  void handleWebSocketMessage(String message) {
    AppNotification? n;
    switch (message) {
      case 'REFRESH_MACHINES':
        n = AppNotification(
          id: _id(),
          type: NotificationType.system,
          title: 'Cập nhật máy dệt',
          message: 'Dữ liệu trạng thái máy vừa được đồng bộ.',
          time: DateTime.now(),
        );
        break;
      case 'REFRESH_MACHINE_BATCHES':
        n = AppNotification(
          id: _id(),
          type: NotificationType.system,
          title: 'Cập nhật phiếu / rổ',
          message: 'Thông tin rổ chứa và phiếu dệt vừa thay đổi.',
          time: DateTime.now(),
        );
        break;
      case 'REFRESH_BASKETS':
        n = AppNotification(
          id: _id(),
          type: NotificationType.system,
          title: 'Cập nhật rổ chứa',
          message: 'Danh sách rổ chứa vừa được làm mới.',
          time: DateTime.now(),
        );
        break;
    }
    if (n != null) _controller.add(n);
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────
  String _id() => DateTime.now().microsecondsSinceEpoch.toRadixString(36);

  String _statusVi(String s) {
    switch (s.toUpperCase()) {
      case 'RUNNING':
        return 'Đang chạy';
      case 'STOPPED':
        return 'Dừng';
      case 'MAINTENANCE':
        return 'Bảo trì';
      case 'SPINNING':
        return 'Lên sợi';
      case 'YARNOUT':
        return 'Hết sợi';
      case 'SPLICING':
        return 'Nối sợi';
      default:
        return s;
    }
  }

  void dispose() => _controller.close();
}
