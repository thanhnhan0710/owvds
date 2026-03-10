import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:owvds/features/production/loom_state/product/domain/product_model.dart';
import 'package:owvds/features/production/machine/machine/domain/machine_model.dart';
import 'package:owvds/features/production/machine/machine_assignment/data/machine_assignment_repository.dart';
import 'package:owvds/features/production/machine/machine_assignment/presentation/bloc/machine_assignment_cubit.dart';
import 'package:owvds/features/production/machine/machine_assignment/presentation/screens/singel_machine_history_screen.dart';

import 'assign_product_dialog.dart';

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
    // Lấy số line cấu hình từ DB, mặc định 1
    final int totalLines = machine.totalLines ?? 1;

    return BlocProvider(
      create: (_) => MachineAssignmentCubit(
        repo: MachineAssignmentRepository(),
        machineId: machine.id,
      )..loadMachineData(),
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 700,
          height: 600,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- HEADER ---
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

              // --- BODY: DANH SÁCH LINE CHẠY ĐỘC LẬP ---
              Expanded(
                child: BlocBuilder<MachineAssignmentCubit, MachineAssignmentState>(
                  builder: (context, state) {
                    if (state is MachineAssignmentLoading) {
                      return const Center(child: CircularProgressIndicator());
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
                      final currentRunningLines = state.currentRunningLines;

                      return ListView.separated(
                        itemCount: totalLines,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final lineNumber = index + 1;

                          // Lọc xem Line hiện tại có đang chạy mã nào không
                          final matches = currentRunningLines.where(
                            (e) => e.lineNumber == lineNumber,
                          );
                          final assignmentForLine = matches.isNotEmpty
                              ? matches.first
                              : null;
                          final isThisLineRunning = assignmentForLine != null;

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isThisLineRunning
                                  ? Colors.green.shade50
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isThisLineRunning
                                    ? Colors.green.shade200
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Badge Số Line
                                Container(
                                  width: 50,
                                  height: 50,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isThisLineRunning
                                        ? Colors.green
                                        : Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "L$lineNumber",
                                    style: TextStyle(
                                      color: isThisLineRunning
                                          ? Colors.white
                                          : Colors.black54,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // Trạng thái của riêng Line này
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isThisLineRunning
                                            ? "ĐANG CHẠY"
                                            : "MÁY TRỐNG",
                                        style: TextStyle(
                                          color: isThisLineRunning
                                              ? Colors.green.shade700
                                              : Colors.grey,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      if (isThisLineRunning) ...[
                                        Text(
                                          assignmentForLine.product?.itemCode ??
                                              'Sản phẩm ID: ${assignmentForLine.productId}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          "Từ: ${DateFormat('dd/MM/yyyy HH:mm').format(assignmentForLine.startTime)}",
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ] else
                                        Text(
                                          "Chưa có mã hàng được gán",
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                // Thao tác cho Line này
                                Row(
                                  children: [
                                    if (isThisLineRunning)
                                      IconButton(
                                        tooltip: "Dừng Line $lineNumber",
                                        icon: const Icon(
                                          Icons.stop_circle,
                                          color: Colors.red,
                                          size: 28,
                                        ),
                                        onPressed: () {
                                          context
                                              .read<MachineAssignmentCubit>()
                                              .stopMachine(lineNumber);
                                        },
                                      ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isThisLineRunning
                                            ? Colors.blueGrey
                                            : const Color(0xFF003366),
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () {
                                        if (selectedProduct != null) {
                                          context
                                              .read<MachineAssignmentCubit>()
                                              .assignProduct(
                                                selectedProduct!.id,
                                                lineNumber, // Truyền đúng Line Number
                                                notes: "Gán từ Dashboard",
                                              );
                                        } else {
                                          showDialog(
                                            context: context,
                                            // [QUAN TRỌNG]: Phải truyền sẵn Cubit cho Dialog mở ra để nó gọi hàm được
                                            builder: (_) => BlocProvider.value(
                                              value: context
                                                  .read<
                                                    MachineAssignmentCubit
                                                  >(),
                                              child: AssignProductDialog(
                                                machine: machine,
                                                lineNumber: lineNumber,
                                                isRunning: isThisLineRunning,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      child: Text(
                                        isThisLineRunning
                                            ? "Đổi Mã"
                                            : "Gán Mã Hàng",
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),

              const Divider(height: 32),

              // --- FOOTER ---
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.history),
                  label: const Text("Xem toàn bộ lịch sử chạy máy"),
                  onPressed: () {
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
