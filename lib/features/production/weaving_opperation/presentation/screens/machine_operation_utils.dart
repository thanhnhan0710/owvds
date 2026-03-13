import 'package:flutter/material.dart';
import 'package:owvds/l10n/app_localizations.dart';
import 'package:owvds/features/production/machine/machine/data/machine_repository.dart';

// =============================================================================
// BIẾN LƯU TRẠNG THÁI LINE TOÀN CỤC (Đã được đồng bộ Realtime từ Backend)
// =============================================================================

/// Trạng thái hiện tại của từng Line: key = '${machineId}_${lineCode}'
final Map<String, String> globalLineStatuses = {};

/// Lý do / ghi chú kèm theo trạng thái của từng Line.
/// Được ghi vào khi người dùng đổi trạng thái, xoá khi line trở về bình thường.
/// key = '${machineId}_${lineCode}'
final Map<String, String> globalLineReasons = {};

/// Hàm gọi API để lấy danh sách trạng thái của các Line đang bị lỗi/bảo trì.
/// Sau khi sync, tự động dọn dẹp các lý do của những Line đã trở về bình thường.
Future<void> syncActiveLineStatuses() async {
  try {
    final repo = MachineRepository();
    final Map<String, String> statuses = await repo.getActiveLineStatuses();
    globalLineStatuses.clear();
    globalLineStatuses.addAll(statuses);

    // Xoá lý do của các Line không còn trong danh sách trạng thái đặc biệt
    // (tức là đã được đặt lại về NORMAL từ backend)
    globalLineReasons.removeWhere(
      (key, _) => !globalLineStatuses.containsKey(key),
    );
  } catch (e) {
    debugPrint("Lỗi đồng bộ trạng thái các Line từ Backend: $e");
  }
}

/// Cập nhật lý do/ghi chú cho một nhóm Line sau khi đổi trạng thái thành công.
/// Gọi hàm này ngay sau [syncActiveLineStatuses] trong [showMultiLineStatusDialog].
void updateLocalLineReasons({
  required int machineId,
  required String newStatus,
  required Map<int, String> reasonPerLine,
}) {
  final bool isClearStatus = newStatus == 'RUNNING' || newStatus == 'NORMAL';
  for (final entry in reasonPerLine.entries) {
    final key = '${machineId}_${entry.key}';
    if (isClearStatus) {
      globalLineReasons.remove(key);
    } else {
      final reason = entry.value.trim();
      if (reason.isNotEmpty) {
        globalLineReasons[key] = reason;
      } else {
        globalLineReasons.remove(key);
      }
    }
  }
}

/// Màu chủ đạo của màn hình vận hành máy.
const Color kMachineOpPrimaryColor = Color(0xFF003366);

/// Tính tên ca hiện tại dựa vào giờ hệ thống.
String calculateCurrentShiftName() {
  final hour = DateTime.now().hour;
  if (hour >= 6 && hour < 14) return 'Ca A';
  if (hour >= 14 && hour < 22) return 'Ca B';
  return 'Ca C';
}

/// Trả về màu tương ứng với trạng thái máy.
Color getMachineStatusColor(String status) {
  switch (status.toUpperCase()) {
    case 'RUNNING':
      return Colors.blue;
    case 'MAINTENANCE':
      return Colors.orange.shade200;
    case 'STOPPED':
      return Colors.red;
    case 'SPINNING':
      return Colors.purple.shade200;
    case 'YARNOUT':
      return Colors.green.shade200;
    case 'SPLICING':
      return Colors.pink.shade200;
    default:
      return Colors.blueGrey;
  }
}

/// Trả về chuỗi trạng thái đã dịch sang ngôn ngữ hiện tại.
String getLocalizedStatus(String status, AppLocalizations l10n) {
  switch (status.toUpperCase()) {
    case 'RUNNING':
      return l10n.statusRunning;
    case 'MAINTENANCE':
      return l10n.statusMaintenance;
    case 'STOPPED':
      return l10n.statusStopped;
    case 'SPINNING':
      return 'Lên sợi';
    case 'YARNOUT':
      return 'Hết sợi';
    case 'SPLICING':
      return 'Nối sợi';
    default:
      return status;
  }
}
