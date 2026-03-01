import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:owvds/core/network/websocket_service.dart';
import 'package:owvds/core/widgets/responsive_layout.dart';
import 'package:owvds/features/area/presentation/bloc/area_cubit.dart';
import 'package:owvds/features/production/loom_state/product/presentation/bloc/product_cubit.dart';
import 'package:owvds/features/production/machine/machine/presentation/bloc/machine_cubit.dart';
import 'package:owvds/features/production/machine/machine_assignment/data/machine_assignment_repository.dart';
import 'package:owvds/features/production/machine/machine_assignment/presentation/bloc/gobal_assignment_cubit.dart';
import 'package:owvds/features/production/machine/machine_assignment/presentation/bloc/machine_assignment_cubit.dart';
import 'package:owvds/features/production/machine/machine_assignment/presentation/screens/gobal_history_screen.dart';
import 'package:owvds/features/production/machine/presentation/widgets/area_slidebar.dart';

import '../dialogs/assign_product_dialog.dart';
import '../dialogs/batch_assign_dialog.dart';
import '../dialogs/machine_history_dialog.dart';

class LoomDashboardScreen extends StatefulWidget {
  const LoomDashboardScreen({super.key});

  @override
  State<LoomDashboardScreen> createState() => _LoomDashboardScreenState();
}

class _LoomDashboardScreenState extends State<LoomDashboardScreen> {
  int? _selectedAreaId;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // [MỚI] Biến trạng thái để lưu bộ lọc hiện tại ('all', 'running', 'empty')
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    context.read<AreaCubit>().loadAreas();
    context.read<MachineCubit>().loadMachines();
    context.read<ProductCubit>().loadProducts();
    context.read<GlobalAssignmentCubit>().loadDashboardData();

    WebSocketService().addListener(_onWsMessage);
  }

  void _onWsMessage(String msg) {
    if (msg.contains("REFRESH_MACHINE")) {
      context.read<GlobalAssignmentCubit>().loadDashboardData();
    }
  }

  @override
  void dispose() {
    WebSocketService().removeListener(_onWsMessage);
    super.dispose();
  }

  void _onAreaSelected(int? areaId) {
    setState(() {
      _selectedAreaId = areaId;
      _filterStatus = 'all'; // Tự động reset bộ lọc về 'Tất cả' khi đổi khu vực
    });
    context.read<MachineCubit>().loadMachines(filterAreaId: areaId);

    if (ResponsiveLayout.isMobile(context) &&
        _scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.pop(context);
    }
  }

  // [MỚI] Hàm vẽ Nút Filter (Chip)
  Widget _buildFilterChip(String label, String value, {Color? color}) {
    final isSelected = _filterStatus == value;
    final activeColor = color ?? const Color(0xFF003366);

    return InkWell(
      onTap: () => setState(() => _filterStatus = value),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor
              : (color?.withOpacity(0.08) ?? Colors.grey.shade100),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? activeColor
                : (color?.withOpacity(0.3) ?? Colors.grey.shade300),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : (color ?? Colors.black87),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F7FA),
      drawer: isDesktop
          ? null
          : Drawer(
              child: AreaSidebar(
                selectedAreaId: _selectedAreaId,
                onAreaSelected: _onAreaSelected,
              ),
            ),
      appBar: AppBar(
        title: Text(
          isMobile ? "Quản lý loom dệt" : "Quản lý loom dệt",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 15 : 16,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF003366),
        elevation: 0.5,
        leading: isDesktop
            ? null
            : IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
        actions: [
          if (isMobile) ...[
            IconButton(
              icon: const Icon(
                Icons.library_add_check,
                color: Color(0xFF003366),
              ),
              tooltip: "Gán Hàng Loạt",
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const BatchAssignDialog(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.history, color: Color(0xFF003366)),
              tooltip: "Lịch sử tổng",
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GlobalHistoryScreen()),
              ),
            ),
            const SizedBox(width: 4),
          ] else ...[
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003366),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.library_add_check, size: 18),
              label: const Text("Gán Hàng Loạt"),
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const BatchAssignDialog(),
              ),
            ),
            const SizedBox(width: 12),
            TextButton.icon(
              icon: const Icon(Icons.history),
              label: const Text("Lịch sử tổng"),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GlobalHistoryScreen()),
              ),
            ),
            const SizedBox(width: 16),
          ],
        ],
        // [MỚI] Thanh Filter đếm số lượng hiển thị ngay bên dưới AppBar
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: BlocBuilder<MachineCubit, MachineState>(
            builder: (context, machineState) {
              if (machineState is! MachineLoaded) return const SizedBox();

              final weavingMachines = machineState.displayedMachines
                  .where((m) => m.polymorphicType == 'weaving_machine')
                  .toList();

              return BlocBuilder<GlobalAssignmentCubit, GlobalAssignmentState>(
                builder: (context, assignState) {
                  int runningCount = 0;
                  if (assignState is GlobalAssignmentLoaded) {
                    runningCount = weavingMachines
                        .where(
                          (m) =>
                              assignState.activeAssignments.containsKey(m.id),
                        )
                        .length;
                  }
                  int emptyCount = weavingMachines.length - runningCount;

                  return Container(
                    height: 48,
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    alignment: Alignment.centerLeft,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(
                            'Tất cả (${weavingMachines.length})',
                            'all',
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            'Đã có sản phẩm ($runningCount)',
                            'running',
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            'Trống ($emptyCount)',
                            'empty',
                            color: Colors.grey.shade700,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop)
            AreaSidebar(
              selectedAreaId: _selectedAreaId,
              onAreaSelected: _onAreaSelected,
            ),

          Expanded(
            child: BlocBuilder<MachineCubit, MachineState>(
              builder: (context, machineState) {
                if (machineState is MachineLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (machineState is MachineLoaded) {
                  final weavingMachines = machineState.displayedMachines
                      .where((m) => m.polymorphicType == 'weaving_machine')
                      .toList();

                  if (weavingMachines.isEmpty) {
                    return const Center(
                      child: Text("Không có máy dệt nào trong khu vực này."),
                    );
                  }

                  return BlocBuilder<
                    GlobalAssignmentCubit,
                    GlobalAssignmentState
                  >(
                    builder: (context, assignState) {
                      Map<int, dynamic> activeMap = {};
                      if (assignState is GlobalAssignmentLoaded) {
                        activeMap = assignState.activeAssignments;
                      }

                      // [MỚI] Tiến hành lọc danh sách máy theo trạng thái đã chọn trên AppBar
                      final filteredMachines = weavingMachines.where((m) {
                        final isRunning = activeMap.containsKey(m.id);
                        if (_filterStatus == 'running') return isRunning;
                        if (_filterStatus == 'empty') return !isRunning;
                        return true; // 'all'
                      }).toList();

                      if (filteredMachines.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Không có máy nào thỏa mãn điều kiện lọc.",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final screenWidth = MediaQuery.of(context).size.width;
                      int crossAxisCount = 4;
                      if (isMobile) {
                        crossAxisCount = 2;
                      } else if (screenWidth < 1100) {
                        crossAxisCount = 3;
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisExtent: 165,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount:
                            filteredMachines.length, // Dùng danh sách đã lọc
                        itemBuilder: (context, index) {
                          final machine =
                              filteredMachines[index]; // Dùng danh sách đã lọc
                          final currentAssignment = activeMap[machine.id];
                          final isRunning = currentAssignment != null;

                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => BlocProvider(
                                    create: (_) => MachineAssignmentCubit(
                                      repo: MachineAssignmentRepository(),
                                      machineId: machine.id,
                                    )..loadMachineData(),
                                    child: MachineHistoryDialog(
                                      machineName: machine.machineName,
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.precision_manufacturing,
                                                color: Color(0xFF003366),
                                                size: 20,
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  machine.machineName,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        PopupMenuButton<String>(
                                          tooltip: "Thao tác gán máy",
                                          padding: EdgeInsets.zero,
                                          iconSize: 20,
                                          onSelected: (val) {
                                            if (val == 'assign') {
                                              showDialog(
                                                context: context,
                                                builder: (_) =>
                                                    AssignProductDialog(
                                                      machine: machine,
                                                      isRunning: isRunning,
                                                    ),
                                              );
                                            } else if (val == 'stop') {
                                              context
                                                  .read<GlobalAssignmentCubit>()
                                                  .stopMachine(machine.id);
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(
                                              value: 'assign',
                                              child: Text('Gán mã hàng'),
                                            ),
                                            if (isRunning)
                                              const PopupMenuItem(
                                                value: 'stop',
                                                child: Text(
                                                  'Dừng sản xuất',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 12),

                                    Expanded(
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isRunning
                                              ? Colors.green.shade50
                                              : Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: isRunning
                                                ? Colors.green.shade200
                                                : Colors.grey.shade300,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            if (isRunning) ...[
                                              const Text(
                                                "ĐANG CHẠY",
                                                style: TextStyle(
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 10,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                currentAssignment
                                                        .product
                                                        ?.itemCode ??
                                                    'N/A',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: Color(0xFF003366),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ] else ...[
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.stop_circle,
                                                    color: Colors.grey.shade400,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    "MÁY TRỐNG",
                                                    style: TextStyle(
                                                      color:
                                                          Colors.grey.shade600,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
        ],
      ),
    );
  }
}
