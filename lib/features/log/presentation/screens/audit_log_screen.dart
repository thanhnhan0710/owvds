import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:owvds/core/network/websocket_service.dart';
import 'package:owvds/features/log/domain/log_model.dart';
import 'package:owvds/features/log/presentation/bloc/log_cubit.dart';

// [MỚI] Import WebSocket

class AuditLogScreen extends StatefulWidget {
  // Các tham số filter tùy chọn (Dùng khi nhúng vào màn hình chi tiết đối tượng)
  final String? filterTargetType;
  final int? filterTargetId;

  const AuditLogScreen({super.key, this.filterTargetType, this.filterTargetId});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  // Biến lưu trữ khoảng ngày đã chọn để lọc
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _loadData();

    // [MỚI] Lắng nghe WebSocket
    WebSocketService().connect();
    WebSocketService().addListener(_onWebSocketMessage);
  }

  @override
  void dispose() {
    // [MỚI] Hủy lắng nghe WebSocket
    WebSocketService().removeListener(_onWebSocketMessage);
    super.dispose();
  }

  // [MỚI] Xử lý sự kiện WebSocket
  void _onWebSocketMessage(String message) {
    if (message == "REFRESH_LOGS") {
      debugPrint("WebSocket: Cập nhật lại danh sách Logs.");
      if (mounted) _loadData();
    }
  }

  // Hàm gọi Cubit để tải dữ liệu kèm bộ lọc
  void _loadData() {
    context.read<LogCubit>().loadLogs(
      targetType: widget.filterTargetType,
      targetId: widget.filterTargetId,
      // Truyền tham số ngày tháng xuống Cubit (Cần đảm bảo Cubit đã hỗ trợ)
      fromDate: _selectedDateRange?.start,
      toDate: _selectedDateRange?.end,
    );
  }

  // Hàm hiển thị DatePicker
  Future<void> _pickDateRange() async {
    final DateTime now = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024), // Ngày bắt đầu hệ thống
      lastDate: now,
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: const Color(0xFF003366),
            colorScheme: const ColorScheme.light(primary: Color(0xFF003366)),
            buttonTheme: const ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
      _loadData(); // Tải lại dữ liệu sau khi chọn
    }
  }

  // Hàm xóa bộ lọc ngày
  void _clearFilter() {
    setState(() {
      _selectedDateRange = null;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          "Nhật ký hoạt động",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF003366),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Tải lại",
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // --- 1. THANH CÔNG CỤ BỘ LỌC ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                const Icon(Icons.filter_list, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedDateRange == null
                        ? "Toàn bộ thời gian"
                        : "${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end)}",
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: _selectedDateRange == null
                          ? Colors.grey.shade600
                          : Colors.black87,
                    ),
                  ),
                ),
                // Nút xóa bộ lọc
                if (_selectedDateRange != null)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    tooltip: "Xóa bộ lọc",
                    onPressed: _clearFilter,
                  ),
                // Nút chọn ngày
                ElevatedButton.icon(
                  onPressed: _pickDateRange,
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: const Text("Chọn ngày"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade50,
                    foregroundColor: Colors.blue.shade800,
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // --- 2. DANH SÁCH LOG ---
          Expanded(
            child: BlocConsumer<LogCubit, LogState>(
              listener: (context, state) {
                // Hiển thị thông báo sau khi hoàn tác
                if (state is LogRevertSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is LogLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is LogError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Lỗi: ${state.message}",
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text("Thử lại"),
                        ),
                      ],
                    ),
                  );
                }

                if (state is LogLoaded) {
                  if (state.logs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history_toggle_off,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Không tìm thấy nhật ký nào",
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: state.logs.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 70),
                    itemBuilder: (context, index) {
                      final log = state.logs[index];
                      return _buildLogItem(log);
                    },
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }

  // Widget hiển thị từng dòng Log
  Widget _buildLogItem(LogModel log) {
    Color actionColor = Colors.grey;
    if (log.action == "CREATE") actionColor = Colors.green;
    if (log.action == "UPDATE") actionColor = Colors.orange;
    if (log.action == "DELETE") actionColor = Colors.red;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: actionColor.withOpacity(0.1),
        child: Icon(_getActionIcon(log.action), color: actionColor, size: 20),
      ),
      title: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          children: [
            TextSpan(
              text: "${log.userEmail ?? 'Unknown'} ",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF003366),
              ),
            ),
            TextSpan(text: "đã ${log.description ?? log.action}"),
          ],
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          DateFormat('dd/MM/yyyy HH:mm').format(log.timestamp),
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      onTap: () => _showDetailDialog(log),
    );
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'CREATE':
        return Icons.add;
      case 'UPDATE':
        return Icons.edit;
      case 'DELETE':
        return Icons.delete;
      default:
        return Icons.info;
    }
  }

  // --- DIALOG CHI TIẾT & HOÀN TÁC ---
  void _showDetailDialog(LogModel log) {
    bool canRevert =
        (log.action == "UPDATE" || log.action == "DELETE") &&
        log.changes != null &&
        log.changes!['old'] != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(_getActionIcon(log.action), color: Colors.blueGrey),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Chi tiết ${log.action}",
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInfoRow(
                  "Thời gian:",
                  DateFormat('dd/MM/yyyy HH:mm:ss').format(log.timestamp),
                ),
                _buildInfoRow("Người thực hiện:", log.userEmail ?? "N/A"),
                _buildInfoRow(
                  "Đối tượng:",
                  "${log.targetType} #${log.targetId}",
                ),
                _buildInfoRow("IP:", log.ipAddress ?? "N/A"),
                const Divider(height: 24),
                const Text(
                  "Chi tiết thay đổi:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 8),
                if (log.changes != null && log.changes!.isNotEmpty)
                  _buildChangesTable(log.changes!)
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "Không có dữ liệu thay đổi chi tiết",
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Đóng"),
          ),
          if (canRevert)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: log.action == "DELETE"
                    ? Colors.green.shade600
                    : Colors.orange.shade700,
                foregroundColor: Colors.white,
              ),
              icon: Icon(
                log.action == "DELETE"
                    ? Icons.restore_from_trash
                    : Icons.history,
                size: 18,
              ),
              label: Text(log.action == "DELETE" ? "Khôi phục" : "Hoàn tác"),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (confirmCtx) => AlertDialog(
                    title: Text(
                      log.action == "DELETE"
                          ? "Khôi phục dữ liệu"
                          : "Xác nhận hoàn tác",
                    ),
                    content: Text(
                      log.action == "DELETE"
                          ? "Bạn có muốn khôi phục lại dữ liệu đã xóa này không?\nLưu ý: ID cũ sẽ được giữ nguyên."
                          : "Hệ thống sẽ quay lại giá trị cũ.\nHành động này sẽ tạo ra một bản ghi nhật ký mới.",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(confirmCtx, false),
                        child: const Text("Hủy"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(confirmCtx, true),
                        child: const Text("Đồng ý"),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  Navigator.pop(ctx);

                  // ignore: use_build_context_synchronously
                  context.read<LogCubit>().revertLogItem(log.id);

                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Đang xử lý yêu cầu...")),
                  );
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangesTable(Map<String, dynamic> changes) {
    final oldData = changes['old'] as Map<String, dynamic>? ?? {};
    final newData = changes['new'] as Map<String, dynamic>? ?? {};

    final keys = {...oldData.keys, ...newData.keys}.toList();

    if (keys.isEmpty) return const SizedBox();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.all(8),
            child: const Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Text(
                    "Trường",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    "Cũ",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    "Mới",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...keys.map((key) {
            final oldVal = oldData[key]?.toString() ?? '-';
            final newVal = newData[key]?.toString() ?? '-';
            return Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: Text(
                      key,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      oldVal,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      newVal,
                      style: const TextStyle(color: Colors.green),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
