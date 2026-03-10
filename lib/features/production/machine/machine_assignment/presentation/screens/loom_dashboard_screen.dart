import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math'; // Import để dùng hàm max, min
import 'package:owvds/core/network/websocket_service.dart';
import 'package:owvds/core/widgets/responsive_layout.dart';
import 'package:owvds/features/area/presentation/bloc/area_cubit.dart';
import 'package:owvds/features/production/loom_state/product/presentation/bloc/product_cubit.dart';
import 'package:owvds/features/production/machine/machine/domain/machine_model.dart';
import 'package:owvds/features/production/machine/machine/presentation/bloc/machine_cubit.dart';
import 'package:owvds/features/production/machine/machine_assignment/presentation/bloc/gobal_assignment_cubit.dart';
import 'package:owvds/features/production/machine/machine_assignment/presentation/screens/gobal_history_screen.dart';
import 'package:owvds/features/production/machine/presentation/widgets/area_slidebar.dart';
import 'package:owvds/features/production/machine/machine_assignment/domain/machine_assignment_model.dart';

import '../dialogs/batch_assign_dialog.dart';
import '../dialogs/machine_control_dialog.dart';

class LoomDashboardScreen extends StatefulWidget {
  const LoomDashboardScreen({super.key});

  @override
  State<LoomDashboardScreen> createState() => _LoomDashboardScreenState();
}

class _LoomDashboardScreenState extends State<LoomDashboardScreen> {
  int? _selectedAreaId;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
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
      _filterStatus = 'all';
    });
    context.read<MachineCubit>().loadMachines(filterAreaId: areaId);

    if (ResponsiveLayout.isMobile(context) &&
        _scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.pop(context);
    }
  }

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

  // =========================================================================
  // Giao diện Card Máy (Đã loại bỏ tham số width cố định từ GridView)
  // =========================================================================
  Widget _buildMachineCard(
    BuildContext context,
    Machine machine,
    List<MachineProductHistory> runningAssignments,
    double width,
    double height,
  ) {
    final int totalLines = machine.totalLines ?? 1;

    const Color cardBorderColor = Color(0xFFBDBDBD);
    const Color headerBgColor = Color(0xFFEEEEEE);
    const Color headerTextColor = Color(0xFF424242);

    return SizedBox(
      width: width,
      height: height,
      child: Card(
        color: Colors.white,
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: cardBorderColor, width: 1.5),
        ),
        child: InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => MachineControlDialog(machine: machine),
            );
          },
          borderRadius: BorderRadius.circular(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- HEADER MÁY ---
              Container(
                height: 26,
                decoration: const BoxDecoration(
                  color: headerBgColor,
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
                          color: headerTextColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const Positioned(
                      right: 4,
                      child: Icon(
                        Icons.settings,
                        size: 14,
                        color: headerTextColor,
                      ),
                    ),
                  ],
                ),
              ),

              // --- BODY (CÁC LINE NẰM NGANG NHAU) ---
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: List.generate(totalLines, (index) {
                      final int lineNum = index + 1;
                      final int assignIdx = runningAssignments.indexWhere(
                        (e) => e.lineNumber == lineNum,
                      );

                      final bool isLineRunning = assignIdx != -1;
                      final assignment = isLineRunning
                          ? runningAssignments[assignIdx]
                          : null;
                      final String itemCode = isLineRunning
                          ? (assignment?.product?.itemCode ?? 'N/A')
                          : 'Trống';

                      // Lấy màu nền và màu chữ
                      final Color bg = isLineRunning
                          ? const Color(0xFFD6F0FF)
                          : Colors.grey.shade100;
                      final Color fg = isLineRunning
                          ? const Color(0xFF0066CC)
                          : Colors.grey.shade500;

                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(left: index == 0 ? 0 : 2),
                          child: Container(
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 2,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Bảng tên Line nhỏ gọn
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isLineRunning
                                        ? fg.withOpacity(0.15)
                                        : Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'L$lineNum',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isLineRunning
                                          ? fg
                                          : Colors.grey.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),

                                // Mã Sản Phẩm TO RÕ, ưu tiên không gian
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      itemCode,
                                      style: TextStyle(
                                        fontSize: 12, // Kích thước chữ to
                                        color: fg,
                                        fontWeight: FontWeight.w900,
                                        height: 1.1,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

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
          "Điều độ Sản xuất",
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
                    runningCount = weavingMachines.where((m) {
                      final tLines = m.totalLines ?? 1;
                      final assigns = assignState.activeAssignments[m.id] ?? [];
                      return assigns.any(
                        (a) => a.lineNumber > 0 && a.lineNumber <= tLines,
                      );
                    }).length;
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
                            'Có Line chạy ($runningCount)',
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
                      Map<int, List<MachineProductHistory>> activeMap = {};
                      if (assignState is GlobalAssignmentLoaded) {
                        activeMap = assignState.activeAssignments;
                      }

                      final filteredMachines = weavingMachines.where((m) {
                        final tLines = m.totalLines ?? 1;
                        final assigns = activeMap[m.id] ?? [];
                        final isRunning = assigns.any(
                          (a) => a.lineNumber > 0 && a.lineNumber <= tLines,
                        );

                        if (_filterStatus == 'running') return isRunning;
                        if (_filterStatus == 'empty') return !isRunning;
                        return true;
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

                      // [CẬP NHẬT QUAN TRỌNG]: TÍNH TOÁN CHIỀU NGANG THEO SỐ LINE
                      // Khai báo kích thước chuẩn của máy có 2 Line.
                      final double standardWidthFor2Lines = isMobile
                          ? 180.0
                          : 260.0;
                      // Chiều cao cố định không đổi dù máy có mấy Line
                      final double fixedHeight = isMobile ? 85.0 : 100.0;
                      final double wrapSpacing = isMobile ? 8.0 : 16.0;

                      return SingleChildScrollView(
                        padding: EdgeInsets.all(isMobile ? 8.0 : 16.0),
                        child: Wrap(
                          spacing: wrapSpacing,
                          runSpacing: wrapSpacing,
                          children: filteredMachines.map((machine) {
                            final int totalLines = machine.totalLines ?? 1;

                            // Lọc bản ghi
                            final List<MachineProductHistory> rawAssignments =
                                activeMap[machine.id] ?? [];
                            final List<MachineProductHistory> validAssignments =
                                rawAssignments
                                    .where(
                                      (a) =>
                                          a.lineNumber > 0 &&
                                          a.lineNumber <= totalLines,
                                    )
                                    .toList();

                            // TÍNH TOÁN WIDTH THEO TỶ LỆ (Chuẩn là 2 line)
                            // 2 line = 1x chuẩn. 4 line = 2x chuẩn. 3 line = 1.5x chuẩn.
                            double cardWidth =
                                (totalLines / 2.0) * standardWidthFor2Lines;

                            // Tránh trường hợp máy 1 line bị quá nhỏ, không thấy được tên máy
                            double minWidth = isMobile ? 120.0 : 160.0;
                            cardWidth = max(cardWidth, minWidth);

                            // Tránh trường hợp máy quá nhiều line (ví dụ 8 line) bị tràn màn hình
                            double maxWidth =
                                screenWidth - (isMobile ? 16 : 32);
                            if (isDesktop)
                              maxWidth -= 250; // Trừ hao thanh sidebar bên trái
                            cardWidth = min(cardWidth, maxWidth);

                            return _buildMachineCard(
                              context,
                              machine,
                              validAssignments,
                              cardWidth,
                              fixedHeight,
                            );
                          }).toList(),
                        ),
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
