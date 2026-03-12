import 'package:flutter/material.dart';
import 'package:owvds/l10n/app_localizations.dart';

// =============================================================================
// [THÊM MỚI] BỘ NHỚ TẠM TRẠNG THÁI LINE (Dùng để khắc phục lỗi Backend đè trạng thái)
// =============================================================================
final Map<String, String> globalLineStatuses = {};

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
