import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:owvds/core/network/api_client.dart';
import 'package:owvds/features/production/machine/machine/data/machine_repository.dart';
import 'package:owvds/features/production/machine/machine/domain/machine_model.dart';
import 'package:owvds/features/production/machine/machine_log/domain/machine_log_model.dart';
import 'package:owvds/l10n/app_localizations.dart';

class MachineHistoryDialog extends StatelessWidget {
  final Machine machine;
  final MachineRepository _repo;

  // [CẤU HÌNH SERVER]
  // Thay đổi IP này trùng với IP máy tính chạy Backend của bạn (kiểm tra bằng ipconfig)
  final Dio _dio = ApiClient().dio;

  MachineHistoryDialog({
    super.key,
    required this.machine,
    MachineRepository? repo,
  }) : _repo = repo ?? MachineRepository();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.history, color: Colors.blueGrey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.machineHistoryTitle(machine.machineName),
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      content: SizedBox(
        width: 500,
        height: 600,
        child: FutureBuilder<List<MachineLog>>(
          future: _repo.getMachineHistory(machine.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${l10n.errorGeneric}: ${snapshot.error}",
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final logs = snapshot.data ?? [];
            if (logs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history_toggle_off,
                      size: 50,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.noHistoryData,
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              itemCount: logs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              padding: const EdgeInsets.only(bottom: 20),
              itemBuilder: (context, index) {
                final log = logs[index];
                return _buildLogItem(context, log, l10n);
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.close),
        ),
      ],
    );
  }

  Widget _buildLogItem(
    BuildContext context,
    MachineLog log,
    AppLocalizations l10n,
  ) {
    Color statusColor = Colors.grey;
    IconData icon = Icons.info;
    String statusText = log.status;

    switch (log.status.toUpperCase()) {
      case 'RUNNING':
        statusColor = Colors.blue;
        icon = Icons.play_arrow;
        statusText = l10n.statusRunning;
        break;
      case 'STOPPED':
        statusColor = Colors.red;
        icon = Icons.stop;
        statusText = l10n.statusStopped;
        break;
      case 'MAINTENANCE':
        statusColor = Colors.orange;
        icon = Icons.build;
        statusText = l10n.statusMaintenance;
        break;
      case 'SPINNING':
        statusColor = Colors.purple;
        icon = Icons.loop;
        statusText = l10n.statusSpinning;
        break;
    }

    final durationStr = _formatDuration(log.durationMinutes, l10n);
    final timeFormat = DateFormat("dd/MM HH:mm");

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Log
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      "${timeFormat.format(log.startTime)} - ${log.endTime != null ? timeFormat.format(log.endTime!) : "Hiện tại"}",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (log.durationMinutes > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    durationStr,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
            ],
          ),

          // Lý do (nếu có)
          if (log.reason != null && log.reason!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: Text(
                "Lý do: ${log.reason}",
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
            ),
          ],

          // [QUAN TRỌNG] Hiển thị hình ảnh
          if (log.imageUrl != null && log.imageUrl!.isNotEmpty)
            _buildImageThumbnail(context, log.imageUrl!),
        ],
      ),
    );
  }

  // --- WIDGET HIỂN THỊ HÌNH ẢNH (Ô VUÔNG) ---
  Widget _buildImageThumbnail(BuildContext context, String imagePath) {
    // 1. Xử lý đường dẫn
    // Backend lưu: /static/uploads/machine_logs/abc.jpg
    // Ghép thành: http://192.168.0.175:8000/static/uploads/machine_logs/abc.jpg

    String fullUrl = imagePath;
    if (!imagePath.startsWith("http")) {
      // Đảm bảo không bị trùng dấu / hoặc thiếu dấu /
      // baseUrl: "http://...:8000" (không có / cuối)

      String cleanPath = imagePath;
      if (cleanPath.startsWith("/")) {
        cleanPath = cleanPath.substring(1); // Bỏ dấu / đầu tiên: static/...
      }

      fullUrl = "$_dio/$cleanPath";
    }

    return Padding(
      padding: const EdgeInsets.only(
        left: 36,
        top: 10,
      ), // Canh lề thẳng với text lý do
      child: InkWell(
        onTap: () {
          // Xem ảnh to
          showDialog(
            context: context,
            builder: (_) => Dialog(
              backgroundColor: Colors.transparent,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.5,
                    maxScale: 4,
                    child: Image.network(fullUrl),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        child: Container(
          width: 100, // Kích thước cố định ô vuông
          height: 100,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              fullUrl,
              fit: BoxFit.cover, // Cắt ảnh để vừa khít ô vuông
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                // In lỗi ra console để debug nếu ảnh không hiện
                debugPrint("Lỗi tải ảnh: $fullUrl - $error");
                return const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, color: Colors.grey),
                    SizedBox(height: 4),
                    Text(
                      "Lỗi ảnh",
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(double minutes, AppLocalizations l10n) {
    if (minutes < 1) return "vừa xong";
    if (minutes < 60) {
      return "${minutes.toStringAsFixed(0)}p";
    } else {
      final hours = (minutes / 60).floor();
      final mins = (minutes % 60).toInt();
      return "${hours}h ${mins}p";
    }
  }
}
