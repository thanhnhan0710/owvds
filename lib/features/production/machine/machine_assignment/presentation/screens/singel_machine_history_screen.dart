import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:owvds/features/production/machine/machine_assignment/data/machine_assignment_repository.dart';
import '../bloc/history_cubit.dart';

class MachineHistoryScreen extends StatelessWidget {
  final int machineId;
  final String machineName;

  const MachineHistoryScreen({
    super.key,
    required this.machineId,
    required this.machineName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HistoryCubit(
        MachineAssignmentRepository(),
        specificMachineId: machineId,
      )..loadPage(1),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: Text(
            "Lịch sử Máy: $machineName",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF003366),
          elevation: 0.5,
          actions: [
            Builder(
              builder: (ctx) => ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.download, size: 18),
                label: const Text("Xuất Excel"),
                onPressed: () {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Đang tạo file Excel...')),
                  );
                  ctx.read<HistoryCubit>().exportExcel();
                },
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: Builder(
          builder: (context) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: BlocBuilder<HistoryCubit, HistoryState>(
                  builder: (context, state) {
                    if (state is HistoryLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is HistoryLoaded) {
                      if (state.records.isEmpty) {
                        return const Center(
                          child: Text("Máy này chưa chạy sản phẩm nào."),
                        );
                      }

                      return Column(
                        children: [
                          Expanded(
                            child: ListView.separated(
                              itemCount: state.records.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final r = state.records[index];
                                final dateFormat = DateFormat(
                                  'dd/MM/yyyy HH:mm',
                                );
                                return ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: Colors.indigo,
                                    child: Icon(
                                      Icons.inventory_2,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    "Mã hàng: ${r.product?.itemCode ?? 'N/A'}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "Từ: ${dateFormat.format(r.startTime)}  →  Đến: ${r.endTime == null ? 'ĐANG CHẠY' : dateFormat.format(r.endTime!)}",
                                    style: TextStyle(
                                      color: r.endTime == null
                                          ? Colors.green
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          // --- PHÂN TRANG ---
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Colors.grey.shade200),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_left),
                                  onPressed: state.currentPage > 1
                                      ? () => context
                                            .read<HistoryCubit>()
                                            .loadPage(state.currentPage - 1)
                                      : null,
                                ),
                                Text(
                                  "Trang ${state.currentPage}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right),
                                  onPressed: state.hasMore
                                      ? () => context
                                            .read<HistoryCubit>()
                                            .loadPage(state.currentPage + 1)
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
