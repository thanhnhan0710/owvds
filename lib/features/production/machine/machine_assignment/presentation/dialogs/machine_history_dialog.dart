import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:owvds/features/production/machine/machine_assignment/domain/machine_assignment_model.dart';
import 'package:owvds/features/production/machine/machine_assignment/presentation/bloc/machine_assignment_cubit.dart';

class MachineHistoryDialog extends StatelessWidget {
  final String machineName;
  const MachineHistoryDialog({super.key, required this.machineName});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Lịch sử máy: $machineName",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF003366),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextField(
              decoration: InputDecoration(
                hintText: 'Tìm theo mã hàng, tên sản phẩm hoặc ghi chú...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (val) =>
                  context.read<MachineAssignmentCubit>().searchHistory(val),
            ),
            const SizedBox(height: 16),

            Expanded(
              child:
                  BlocBuilder<MachineAssignmentCubit, MachineAssignmentState>(
                    builder: (context, state) {
                      if (state is MachineAssignmentLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (state is MachineAssignmentLoaded) {
                        if (state.history.isEmpty) {
                          return const Center(
                            child: Text("Không có lịch sử chạy máy."),
                          );
                        }

                        return ListView.separated(
                          itemCount: state.history.length,
                          separatorBuilder: (_, __) =>
                              Divider(color: Colors.grey.shade300),
                          itemBuilder: (context, index) {
                            final record = state.history[index];
                            return _buildHistoryRow(context, record);
                          },
                        );
                      }
                      return const SizedBox();
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryRow(BuildContext context, MachineProductHistory record) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final isRunning = record.endTime == null;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isRunning
            ? Colors.green.shade100
            : Colors.grey.shade200,
        child: Icon(
          isRunning ? Icons.play_arrow : Icons.stop,
          color: isRunning ? Colors.green : Colors.grey,
        ),
      ),
      title: Text(
        record.product?.itemCode ?? 'Sản phẩm bị xóa',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Từ: ${dateFormat.format(record.startTime)} - Đến: ${isRunning ? 'Nay' : dateFormat.format(record.endTime!)}",
            style: TextStyle(color: Colors.blue.shade800, fontSize: 13),
          ),
          if (record.notes != null && record.notes!.isNotEmpty)
            Text(
              "Ghi chú: ${record.notes}",
              style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            tooltip: "Sửa lịch sử",
            onPressed: () => showDialog(
              context: context,
              builder: (_) => BlocProvider.value(
                value: context.read<MachineAssignmentCubit>(),
                child: _EditHistoryDialog(record: record),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            tooltip: "Xóa bản ghi",
            onPressed: () {
              // Yêu cầu xác nhận
              context.read<MachineAssignmentCubit>().deleteHistoryRecord(
                record.id,
              );
            },
          ),
        ],
      ),
    );
  }
}

// ==========================================
// FORM SỬA CHỮA LỊCH SỬ BỊ SAI
// ==========================================
class _EditHistoryDialog extends StatefulWidget {
  final MachineProductHistory record;
  const _EditHistoryDialog({required this.record});

  @override
  State<_EditHistoryDialog> createState() => _EditHistoryDialogState();
}

class _EditHistoryDialogState extends State<_EditHistoryDialog> {
  final _notesController = TextEditingController();
  DateTime? _startTime;
  DateTime? _endTime;

  @override
  void initState() {
    super.initState();
    _notesController.text = widget.record.notes ?? '';
    _startTime = widget.record.startTime;
    _endTime = widget.record.endTime;
  }

  Future<void> _pickDateTime(BuildContext context, bool isStart) async {
    final initialDate = (isStart ? _startTime : _endTime) ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return;

    if (!context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (time == null) return;

    setState(() {
      final finalDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      if (isStart) {
        _startTime = finalDateTime;
      } else {
        _endTime = finalDateTime;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return AlertDialog(
      title: const Text(
        'Sửa bản ghi sản xuất',
        style: TextStyle(color: Color(0xFF003366), fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Lưu ý: Bạn có thể chỉnh sửa thời gian nếu công nhân quên bấm dừng máy trên hệ thống.",
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),

            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("Thời gian bắt đầu"),
              subtitle: Text(
                dateFormat.format(_startTime!),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_month),
                onPressed: () => _pickDateTime(context, true),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("Thời gian kết thúc"),
              subtitle: Text(
                _endTime == null
                    ? "Đang chạy..."
                    : dateFormat.format(_endTime!),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_endTime != null)
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.red),
                      onPressed: () => setState(() => _endTime = null),
                      tooltip: "Xóa giờ kết thúc (Chuyển thành Đang chạy)",
                    ),
                  IconButton(
                    icon: const Icon(Icons.calendar_month),
                    onPressed: () => _pickDateTime(context, false),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Ghi chú thêm',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF003366),
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            // Xây dựng JSON payload
            final payload = {
              'start_time': _startTime!.toIso8601String(),
              'end_time': _endTime?.toIso8601String(),
              'notes': _notesController.text.trim(),
            };

            context.read<MachineAssignmentCubit>().updateHistoryRecord(
              widget.record.id,
              payload,
            );
            Navigator.pop(context);
          },
          child: const Text('Lưu thay đổi'),
        ),
      ],
    );
  }
}
