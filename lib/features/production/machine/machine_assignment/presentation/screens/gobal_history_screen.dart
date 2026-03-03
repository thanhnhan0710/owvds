import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:owvds/features/production/machine/machine_assignment/data/machine_assignment_repository.dart';
import '../bloc/history_cubit.dart';

class GlobalHistoryScreen extends StatefulWidget {
  const GlobalHistoryScreen({super.key});

  @override
  State<GlobalHistoryScreen> createState() => _GlobalHistoryScreenState();
}

class _GlobalHistoryScreenState extends State<GlobalHistoryScreen> {
  String _selectedFilter = 'Tất cả';

  void _applyDateFilter(BuildContext context, String filter) {
    setState(() => _selectedFilter = filter);
    final now = DateTime.now();
    DateTime? start, end;

    if (filter == 'Hôm nay') {
      start = DateTime(now.year, now.month, now.day);
      end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    } else if (filter == 'Tuần này') {
      start = now.subtract(Duration(days: now.weekday - 1));
      start = DateTime(start.year, start.month, start.day);
      end = now;
    } else if (filter == 'Tháng này') {
      start = DateTime(now.year, now.month, 1);
      end = now;
    } else if (filter == 'Năm nay') {
      start = DateTime(now.year, 1, 1);
      end = now;
    }

    context.read<HistoryCubit>().setDateFilter(start, end);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HistoryCubit(MachineAssignmentRepository())..loadPage(1),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: const Text(
            "Lịch sử Điều độ (Toàn xưởng)",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
              child: Column(
                children: [
                  // --- CÔNG CỤ LỌC ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText: 'Tìm kiếm tên máy, mã hàng...',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onSubmitted: (val) =>
                                context.read<HistoryCubit>().setKeyword(val),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            value: _selectedFilter,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              isDense: true,
                              labelText: "Thời gian",
                            ),
                            items:
                                [
                                      'Tất cả',
                                      'Hôm nay',
                                      'Tuần này',
                                      'Tháng này',
                                      'Năm nay',
                                    ]
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(e),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (val) => _applyDateFilter(context, val!),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- BẢNG DỮ LIỆU ---
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: BlocConsumer<HistoryCubit, HistoryState>(
                        listener: (context, state) {
                          if (state is HistoryError) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(state.message),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        builder: (context, state) {
                          if (state is HistoryLoading) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (state is HistoryLoaded) {
                            if (state.records.isEmpty) {
                              return const Center(
                                child: Text("Không có dữ liệu lịch sử."),
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
                                          backgroundColor: Color(0xFF003366),
                                          child: Icon(
                                            Icons.precision_manufacturing,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                        title: Text(
                                          "Máy: ${r.machine?.machineName ?? 'N/A'}  |  Mã hàng: ${r.product?.itemCode ?? 'N/A'}",
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
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      top: BorderSide(
                                        color: Colors.grey.shade200,
                                      ),
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
                                                  .loadPage(
                                                    state.currentPage - 1,
                                                  )
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
                                                  .loadPage(
                                                    state.currentPage + 1,
                                                  )
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
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
