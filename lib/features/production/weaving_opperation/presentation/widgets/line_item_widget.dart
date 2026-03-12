import 'package:flutter/material.dart';
import 'package:owvds/features/production/weaving/domain/weaving_model.dart';

// =============================================================================
// WIDGET: LINE ITEM (v2 – per-line status)
// =============================================================================

/// Hiển thị thông tin một line trong máy dệt.
/// Màu nền và màu chữ thể hiện trạng thái của line đó.
class LineItem extends StatelessWidget {
  final int lineIndex;
  final WeavingTicket? ticket;

  /// Trạng thái hiệu lực của line này (đã tính sẵn từ MachineCard).
  /// Có thể là: 'RUNNING', 'SPINNING', 'YARNOUT', 'SPLICING',
  ///             'STOPPED', 'MAINTENANCE', 'IDLE'.
  final String lineStatus;

  final VoidCallback onTap;

  const LineItem({
    super.key,
    required this.lineIndex,
    required this.ticket,
    required this.lineStatus,
    required this.onTap,
  });

  // ---------------------------------------------------------------------------
  // Status → màu nền
  // ---------------------------------------------------------------------------
  static Color bgColor(String status) {
    switch (status.toUpperCase()) {
      case 'RUNNING':
        return const Color(0xFFD6F0FF); // xanh biển nhạt
      case 'YARNOUT':
        return const Color(0xFFD6F5D6); // xanh lá nhạt
      case 'SPINNING':
        return const Color(0xFFEDE0FF); // tím nhạt
      case 'SPLICING':
        return const Color(0xFFF9E4FA); // hồng nhạt
      case 'STOPPED':
        return const Color(0xFFFFD6D6); // đỏ nhạt
      case 'MAINTENANCE':
        return const Color(0xFFFFF0D6); // cam nhạt
      default: // IDLE
        return Colors.grey.shade100;
    }
  }

  // ---------------------------------------------------------------------------
  // Status → màu chữ / icon
  // ---------------------------------------------------------------------------
  static Color textColor(String status) {
    switch (status.toUpperCase()) {
      case 'RUNNING':
        return const Color(0xFF0066CC);
      case 'YARNOUT':
        return const Color(0xFF2E7D32);
      case 'SPINNING':
        return const Color(0xFF6A1B9A);
      case 'SPLICING':
        return const Color(0xFFAD1457);
      case 'STOPPED':
        return const Color(0xFFC62828);
      case 'MAINTENANCE':
        return const Color(0xFFE65100);
      default: // IDLE
        return Colors.grey.shade500;
    }
  }

  // ---------------------------------------------------------------------------
  // Status → nhãn ngắn
  // ---------------------------------------------------------------------------
  static String shortLabel(String status) {
    switch (status.toUpperCase()) {
      case 'RUNNING':
        return 'Chạy';
      case 'YARNOUT':
        return 'Hết sợi';
      case 'SPINNING':
        return 'Lên sợi';
      case 'SPLICING':
        return 'Nối sợi';
      case 'STOPPED':
        return 'Dừng';
      case 'MAINTENANCE':
        return 'Bảo trì';
      default:
        return 'Trống';
    }
  }

  // ---------------------------------------------------------------------------
  // Status → icon
  // ---------------------------------------------------------------------------
  static IconData statusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'RUNNING':
        return Icons.play_circle_filled;
      case 'YARNOUT':
        return Icons.hourglass_empty;
      case 'SPINNING':
        return Icons.loop;
      case 'SPLICING':
        return Icons.link;
      case 'STOPPED':
        return Icons.stop_circle;
      case 'MAINTENANCE':
        return Icons.build;
      default:
        return Icons.add_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color bg = bgColor(lineStatus);
    final Color fg = textColor(lineStatus);
    final bool isIdle = lineStatus.toUpperCase() == 'IDLE';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Tiêu đề Line
            Text(
              'L$lineIndex',
              style: TextStyle(
                fontSize: 10,
                color: fg,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3),

            // Icon trạng thái
            Icon(statusIcon(lineStatus), color: fg, size: 16),
            const SizedBox(height: 2),

            // Nhãn trạng thái
            Text(
              shortLabel(lineStatus),
              style: TextStyle(
                fontSize: 9,
                color: fg,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),

            // Mã rổ (nếu đang chạy và có ticket)
            if (!isIdle && ticket != null && ticket!.basketCode != null) ...[
              const SizedBox(height: 2),
              Text(
                ticket!.basketCode!,
                style: TextStyle(
                  fontSize: 8,
                  color: fg.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
