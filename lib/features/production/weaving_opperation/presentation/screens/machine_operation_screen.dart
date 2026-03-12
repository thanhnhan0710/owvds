import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:owvds/core/network/websocket_service.dart';
import 'package:owvds/features/hr/employee/presentation/bloc/employee_cubit.dart';
import 'package:owvds/features/hr/work_schedule/presentation/bloc/work_schedule_cubit.dart';
import 'package:owvds/features/hr/work_schedule/shift/presentation/bloc/shift_cubit.dart';
import 'package:owvds/features/inventory/material_batch/presentation/bloc/material_batch_cubit.dart';
import 'package:owvds/features/production/basket/presentation/bloc/baket_cubit.dart';
import 'package:owvds/features/production/loom_state/product/presentation/bloc/product_cubit.dart';
import 'package:owvds/features/production/machine/machine/domain/machine_model.dart';
import 'package:owvds/features/production/machine/machine_assignment/domain/machine_assignment_model.dart';
import 'package:owvds/features/production/machine/machine_assignment/presentation/bloc/gobal_assignment_cubit.dart';
import 'package:owvds/features/production/weaving_opperation/presentation/bloc/machine_operation_cubit.dart';
import 'package:owvds/features/production/weaving_opperation/presentation/dialogs/machine_history_dialog.dart';
import 'package:owvds/features/qc/bom/presentation/bloc/bom_cubit.dart';
import 'package:owvds/features/qc/loom_state_standard/presentation/bloc/loom_state_standard_cubit.dart';
import 'package:owvds/l10n/app_localizations.dart';

import 'machine_operation_dialogs.dart';
import '../widgets/machine_card_widget.dart';

// =============================================================================
// MÀN HÌNH CHÍNH: Vận hành máy
// =============================================================================

class MachineOperationScreen extends StatefulWidget {
  const MachineOperationScreen({super.key});

  @override
  State<MachineOperationScreen> createState() => _MachineOperationScreenState();
}

class _MachineOperationScreenState extends State<MachineOperationScreen>
    with TickerProviderStateMixin {
  static const Color _primaryColor = Color(0xFF003366);

  final TextEditingController _machineSearchCtrl = TextEditingController();
  String _searchKeyword = '';
  Timer? _debounce;

  TabController? _tabController;
  String? _selectedArea;
  List<String> _currentAreas = [];

  @override
  void initState() {
    super.initState();
    context.read<MachineOperationCubit>().loadDashboard();
    context.read<ProductCubit>().loadProducts();
    context.read<StandardCubit>().loadStandards();
    context.read<MaterialBatchCubit>().loadBatches();
    context.read<EmployeeCubit>().loadEmployees();
    context.read<ShiftCubit>().loadShifts();
    context.read<WorkScheduleCubit>().loadSchedules();
    context.read<BasketCubit>().loadBaskets();
    context.read<BOMCubit>().loadBOMHeaders();
    context.read<GlobalAssignmentCubit>().loadDashboardData();

    WebSocketService().connect();
    WebSocketService().addListener(_onWebSocketMessage);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _machineSearchCtrl.dispose();
    _tabController?.dispose();
    WebSocketService().removeListener(_onWebSocketMessage);
    super.dispose();
  }

  void _onWebSocketMessage(String message) {
    if (message == 'REFRESH_MACHINES' || message == 'REFRESH_MACHINE_BATCHES') {
      debugPrint('WebSocket: Cập nhật lại danh sách Máy Móc tự động.');
      context.read<MachineOperationCubit>().loadDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      appBar: AppBar(
        title: Text(
          l10n.machineOperation,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: _primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 22),
            tooltip: l10n.refreshData,
            onPressed: () {
              context.read<MachineOperationCubit>().loadDashboard();
              context.read<GlobalAssignmentCubit>().loadDashboardData();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(l10n),
          Expanded(child: _buildMachineList(l10n)),
        ],
      ),
    );
  }

  Widget _buildSearchBar(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: Colors.white,
      child: SizedBox(
        height: 36,
        child: TextField(
          controller: _machineSearchCtrl,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: l10n.searchMachine,
            prefixIcon: const Icon(Icons.search, size: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            filled: true,
            fillColor: Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 0,
              horizontal: 8,
            ),
            isDense: true,
          ),
          onChanged: (val) {
            if (_debounce?.isActive ?? false) _debounce!.cancel();
            _debounce = Timer(const Duration(milliseconds: 300), () {
              setState(() => _searchKeyword = val.toLowerCase());
            });
          },
        ),
      ),
    );
  }

  Widget _buildMachineList(AppLocalizations l10n) {
    return BlocConsumer<MachineOperationCubit, MachineOpState>(
      listener: (context, state) {
        if (state is MachineOpError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        if (state is MachineOpLoading)
          return const Center(child: CircularProgressIndicator());
        if (state is MachineOpLoaded)
          return _buildLoadedContent(context, state, l10n);
        return const SizedBox();
      },
    );
  }

  Widget _buildLoadedContent(
    BuildContext context,
    MachineOpLoaded state,
    AppLocalizations l10n,
  ) {
    final loomState = context.watch<GlobalAssignmentCubit>().state;

    final filteredMachines = state.machines
        .where(
          (m) =>
              m.machineName.toLowerCase().contains(_searchKeyword) ||
              (m.status?.statusName ?? '').toLowerCase().contains(
                _searchKeyword,
              ),
        )
        .toList();

    if (filteredMachines.isEmpty) {
      return Center(
        child: Text(l10n.noMachineFound, style: const TextStyle(fontSize: 14)),
      );
    }

    final Map<String, List<Machine>> groupedMachines = {};
    for (final machine in filteredMachines) {
      final areaName =
          (machine.area?.areaName != null && machine.area!.areaName.isNotEmpty)
          ? machine.area!.areaName
          : l10n.unassignedArea;
      groupedMachines.putIfAbsent(areaName, () => []).add(machine);
    }
    final sortedAreas = groupedMachines.keys.toList()..sort();
    final bool areasChanged = _currentAreas.join(',') != sortedAreas.join(',');

    if (_tabController == null || areasChanged) {
      int initIndex = 0;
      if (_selectedArea != null && sortedAreas.contains(_selectedArea)) {
        initIndex = sortedAreas.indexOf(_selectedArea!);
      } else if (sortedAreas.isNotEmpty) {
        _selectedArea = sortedAreas[0];
      }

      _tabController?.dispose();
      _tabController = TabController(
        length: sortedAreas.length,
        vsync: this,
        initialIndex: initIndex,
      );
      _currentAreas = sortedAreas;

      _tabController!.addListener(() {
        if (!_tabController!.indexIsChanging)
          _selectedArea = _currentAreas[_tabController!.index];
      });
    }

    return Column(
      children: [
        Container(
          color: Colors.white,
          height: 36,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: _primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: _primaryColor,
            indicatorWeight: 2,
            labelPadding: const EdgeInsets.symmetric(horizontal: 16),
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            tabs: sortedAreas
                .map((area) => Tab(text: area.toUpperCase()))
                .toList(),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: sortedAreas.map((area) {
              final machinesInArea = groupedMachines[area]!;
              return LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount;
                  if (constraints.maxWidth < 600)
                    crossAxisCount = 3;
                  else
                    crossAxisCount = (constraints.maxWidth / 140).floor().clamp(
                      3,
                      100,
                    );

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(4),
                    child: StaggeredGrid.count(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                      children: machinesInArea.map((machine) {
                        final int totalLines = (machine.totalLines ?? 0) > 0
                            ? machine.totalLines!
                            : 2;
                        final int crossAxisCellCount =
                            (totalLines > 2 && crossAxisCount >= 2) ? 2 : 1;

                        MachineProductHistory? activeLoom;
                        if (loomState is GlobalAssignmentLoaded) {
                          activeLoom = loomState
                              .activeAssignments[machine.id]
                              ?.firstOrNull;
                        }

                        return StaggeredGridTile.fit(
                          crossAxisCellCount: crossAxisCellCount,
                          child: MachineCard(
                            machine: machine,
                            state: state,
                            l10n: l10n,
                            activeLoom: activeLoom,
                            // Gọi hàm hiển thị Checkbox nhiều Line khi chọn xong trạng thái
                            onStatusSelected: (newStatus) =>
                                showMultiLineStatusDialog(
                                  context,
                                  machine,
                                  newStatus,
                                  totalLines,
                                  l10n,
                                ),
                            // Mở hộp thoại xem lịch sử
                            onHistory: () => showDialog(
                              context: context,
                              builder: (ctx) =>
                                  MachineHistoryDialog(machine: machine),
                            ),
                            // Mở BottomSheet của LINE (Chỉ xử lý rổ)
                            onLineTap: (lineCode, ticket, activeLoom) =>
                                handleLineTap(
                                  context,
                                  machine,
                                  lineCode,
                                  ticket,
                                  state.readyBaskets,
                                  l10n,
                                  activeLoom,
                                ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
