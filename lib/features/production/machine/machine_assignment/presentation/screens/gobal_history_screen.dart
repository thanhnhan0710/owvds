import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:owvds/features/production/machine/machine/presentation/bloc/machine_cubit.dart';
import 'package:owvds/features/production/machine/machine_assignment/presentation/bloc/gobal_assignment_cubit.dart';

class GlobalHistoryScreen extends StatelessWidget {
  const GlobalHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          "Lịch sử chạy máy (Toàn xưởng)",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF003366),
        elevation: 0.5,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Thanh tìm kiếm
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Tìm kiếm theo Tên Máy, Mã hàng, Tên sản phẩm...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (val) => context
                    .read<GlobalAssignmentCubit>()
                    .loadDashboardData(historyKeyword: val),
              ),
            ),
            const SizedBox(height: 24),

            // Bảng dữ liệu
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: BlocBuilder<GlobalAssignmentCubit, GlobalAssignmentState>(
                  builder: (context, state) {
                    if (state is GlobalAssignmentLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is GlobalAssignmentLoaded) {
                      if (state.globalHistory.isEmpty) {
                        return const Center(
                          child: Text("Không có dữ liệu lịch sử."),
                        );
                      }

                      // [MỚI] Bọc thêm MachineCubit để móc chéo lấy Tên Máy 100% chính xác
                      return BlocBuilder<MachineCubit, MachineState>(
                        builder: (context, machineState) {
                          return ListView.separated(
                            itemCount: state.globalHistory.length,
                            separatorBuilder: (_, __) =>
                                Divider(color: Colors.grey.shade200, height: 1),
                            itemBuilder: (context, index) {
                              final record = state.globalHistory[index];
                              final isRunning = record.endTime == null;
                              final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

                              // [THUẬT TOÁN TÌM TÊN MÁY BẢO ĐẢM]
                              String finalMachineName =
                                  record.machine?.machineName ??
                                  'ID ${record.machineId}';
                              if (machineState is MachineLoaded) {
                                try {
                                  final m = machineState.allMachines.firstWhere(
                                    (x) => x.id == record.machineId,
                                  );
                                  finalMachineName =
                                      m.machineName; // Lấy tên thật đè lên
                                } catch (_) {}
                              }

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 8,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: const Color(
                                    0xFF003366,
                                  ).withOpacity(0.1),
                                  child: const Icon(
                                    Icons.precision_manufacturing,
                                    color: Color(0xFF003366),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Text(
                                      "Máy: $finalMachineName",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isRunning
                                            ? Colors.green.shade100
                                            : Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        isRunning ? "ĐANG CHẠY" : "ĐÃ KẾT THÚC",
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isRunning
                                              ? Colors.green.shade700
                                              : Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      "Mã hàng: ${record.product?.itemCode ?? 'N/A'}",
                                      style: const TextStyle(
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Từ: ${dateFormat.format(record.startTime)}  →  Đến: ${isRunning ? 'Hiện tại' : dateFormat.format(record.endTime!)}",
                                      style: TextStyle(
                                        color: Colors.blue.shade800,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => context
                                      .read<GlobalAssignmentCubit>()
                                      .deleteHistory(record.id),
                                ),
                              );
                            },
                          );
                        },
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
