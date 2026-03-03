import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:owvds/features/production/loom_state/product/domain/product_model.dart';
import 'package:owvds/features/production/machine/machine/domain/machine_model.dart';
import 'package:owvds/features/production/machine/machine_assignment/data/machine_assignment_repository.dart';
import 'package:owvds/features/production/machine/machine_assignment/presentation/bloc/machine_assignment_cubit.dart';
import 'package:owvds/features/production/machine/machine_assignment/presentation/screens/singel_machine_history_screen.dart';

class MachineControlDialog extends StatelessWidget {
  final Machine machine;
  final Product? selectedProduct;

  const MachineControlDialog({
    super.key,
    required this.machine,
    this.selectedProduct,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MachineAssignmentCubit(
        repo: MachineAssignmentRepository(),
        machineId: machine.id,
      )..loadMachineData(),
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: BlocBuilder<MachineAssignmentCubit, MachineAssignmentState>(
            builder: (context, state) {
              if (state is MachineAssignmentLoading) {
                return const SizedBox(
                  height: 300,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (state is MachineAssignmentError) {
                return Center(
                  child: Text(
                    state.message,
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              if (state is MachineAssignmentLoaded) {
                final currentRunning = state.currentRunning;
                final isRunning = currentRunning != null;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.precision_manufacturing,
                              color: Color(0xFF003366),
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Máy: ${machine.machineName}",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF003366),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(height: 32),

                    // Thông tin hiện tại
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isRunning
                            ? Colors.green.shade50
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isRunning
                              ? Colors.green.shade200
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "TRẠNG THÁI HIỆN TẠI",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (isRunning) ...[
                            Row(
                              children: [
                                const Icon(
                                  Icons.play_circle_fill,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Đang chạy: ${currentRunning.product?.itemCode ?? 'Sản phẩm ID ${currentRunning.productId}'}",
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Mã hàng: ${currentRunning.product?.itemCode ?? 'N/A'}",
                              style: const TextStyle(fontSize: 14),
                            ),
                            Text(
                              "Bắt đầu lúc: ${DateFormat('dd/MM/yyyy HH:mm').format(currentRunning.startTime)}",
                              style: const TextStyle(fontSize: 14),
                            ),
                          ] else ...[
                            Row(
                              children: [
                                const Icon(
                                  Icons.stop_circle,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Máy đang trống (Chờ lệnh)",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Hành động
                    if (selectedProduct != null) ...[
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF003366),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: const Icon(Icons.assignment_turned_in),
                        label: Text(
                          isRunning
                              ? "Dừng mã cũ & Gán mã [${selectedProduct!.itemCode}]"
                              : "Gán mã hàng [${selectedProduct!.itemCode}]",
                        ),
                        onPressed: () {
                          context.read<MachineAssignmentCubit>().assignProduct(
                            selectedProduct!.id,
                            notes: "Gán từ màn hình điều độ",
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (isRunning) ...[
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: const Icon(Icons.stop),
                        label: const Text("Dừng sản xuất mã hiện tại"),
                        onPressed: () => context
                            .read<MachineAssignmentCubit>()
                            .stopMachine(),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // [ĐÃ SỬA]: Nút xem lịch sử dùng Navigator.push
                    TextButton.icon(
                      icon: const Icon(Icons.history),
                      label: const Text("Xem toàn bộ lịch sử chạy máy"),
                      onPressed: () {
                        // Đóng form hiện tại trước khi chuyển trang
                        Navigator.pop(context);

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MachineHistoryScreen(
                              machineId: machine.id,
                              machineName: machine.machineName,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ),
    );
  }
}
