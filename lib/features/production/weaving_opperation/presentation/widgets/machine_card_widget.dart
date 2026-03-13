import 'package:flutter/material.dart';
import 'package:owvds/features/production/machine/machine/domain/machine_model.dart';
import 'package:owvds/features/production/machine/machine_assignment/domain/machine_assignment_model.dart';
import 'package:owvds/features/production/weaving/domain/weaving_model.dart';
import 'package:owvds/features/production/weaving_opperation/presentation/bloc/machine_operation_cubit.dart';
import 'package:owvds/features/production/weaving_opperation/presentation/screens/machine_operation_utils.dart';
import 'package:owvds/l10n/app_localizations.dart';

import 'line_item_widget.dart';

class MachineCard extends StatelessWidget {
  final Machine machine;
  final MachineOpLoaded state;
  final AppLocalizations l10n;
  final MachineProductHistory? activeLoom;

  final Function(String newStatus) onStatusSelected;
  final VoidCallback onHistory;
  final Function(
    String lineCode,
    WeavingTicket? ticket,
    MachineProductHistory? activeLoom,
  )
  onLineTap;

  const MachineCard({
    super.key,
    required this.machine,
    required this.state,
    required this.l10n,
    required this.onStatusSelected,
    required this.onHistory,
    required this.onLineTap,
    this.activeLoom,
  });

  static const Color _cardBorderColor = Color(0xFFBDBDBD);
  static const Color _headerBgColor = Color(0xFFEEEEEE);
  static const Color _headerTextColor = Color(0xFF424242);

  // [ĐÃ SỬA LOGIC]: Tách bạch hoàn toàn Trạng thái Máy và Trạng thái Line
  String _effectiveLineStatus(String lineCode, WeavingTicket? ticket) {
    // ƯU TIÊN 1: Trạng thái sự cố / thao tác của RIÊNG TỪNG LINE (Đọc từ DB Backend)
    final localStatus = globalLineStatuses['${machine.id}_$lineCode'];

    if (localStatus != null && localStatus != 'NORMAL') {
      // Đã xoá logic ép về IDLE nếu ticket == null.
      // Bây giờ user chọn trạng thái nào (RUNNING, STOPPED, MAINTENANCE...), UI sẽ hiện đúng trạng thái đó.
      return localStatus;
    }

    // ƯU TIÊN 2: Trạng thái bình thường (Tự động theo việc có Phiếu dệt/Rổ hay không)
    if (ticket != null) {
      return 'RUNNING'; // Có rổ -> Đang chạy
    }
    return 'IDLE'; // Không có rổ -> Trống
  }

  PopupMenuItem<String> _buildMenuItem(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int totalLines = (machine.totalLines ?? 0) > 0
        ? machine.totalLines!
        : 2;

    return Card(
      color: Colors.white,
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: _cardBorderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 26,
            decoration: const BoxDecoration(
              color: _headerBgColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Text(
                    machine.machineName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _headerTextColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                Positioned(
                  right: 0,
                  child: PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert,
                      size: 20,
                      color: _headerTextColor,
                    ),
                    padding: EdgeInsets.zero,
                    tooltip: 'Tùy chọn thao tác',
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 4,
                    onSelected: (value) {
                      if (value == 'HISTORY') {
                        onHistory();
                      } else {
                        onStatusSelected(value);
                      }
                    },
                    itemBuilder: (ctx) => [
                      _buildMenuItem(
                        'RUNNING',
                        'Chạy',
                        Icons.play_arrow,
                        Colors.blue,
                      ),
                      _buildMenuItem(
                        'SPINNING',
                        'Lên sợi',
                        Icons.arrow_circle_up,
                        Colors.purple,
                      ),
                      _buildMenuItem(
                        'YARNOUT',
                        'Hết sợi',
                        Icons.error_outline,
                        Colors.green,
                      ),
                      _buildMenuItem(
                        'SPLICING',
                        'Nối sợi',
                        Icons.link,
                        Colors.pink,
                      ),
                      _buildMenuItem('STOPPED', 'Dừng', Icons.stop, Colors.red),
                      _buildMenuItem(
                        'MAINTENANCE',
                        'Bảo trì',
                        Icons.build,
                        Colors.orange,
                      ),
                      const PopupMenuDivider(),
                      _buildMenuItem(
                        'HISTORY',
                        'Lịch sử thao tác',
                        Icons.history,
                        Colors.grey.shade700,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 76,
            padding: const EdgeInsets.all(3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(totalLines, (index) {
                final String lineCode = '${index + 1}';
                final WeavingTicket? ticket =
                    state.activeTickets['${machine.id}_$lineCode'];

                final String lineStatus = _effectiveLineStatus(
                  lineCode,
                  ticket,
                );

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: index == 0 ? 0 : 2),
                    child: LineItem(
                      lineIndex: index + 1,
                      ticket: ticket,
                      lineStatus: lineStatus,
                      onTap: () => onLineTap(lineCode, ticket, activeLoom),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
