import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

// ── HR ──────────────────────────────────────────────────────────────────────
import 'package:owvds/features/hr/employee/presentation/bloc/employee_cubit.dart';
import 'package:owvds/features/hr/employee/domain/employee_model.dart';
import 'package:owvds/features/hr/department/presentation/bloc/department_cubit.dart';
import 'package:owvds/features/hr/department/domain/department_model.dart';

// ── Warehouse ────────────────────────────────────────────────────────────────
import 'package:owvds/features/inventory/material/presentation/bloc/material_cubit.dart';
import 'package:owvds/features/inventory/material/domain/material_model.dart';
import 'package:owvds/features/inventory/material_inventory/presentation/bloc/material_inventory_cubit.dart';
import 'package:owvds/features/inventory/material_inventory/domain/material_inventory_model.dart';
import 'package:owvds/features/inventory/material_receipt/presentation/bloc/material_receipt_cubit.dart';
import 'package:owvds/features/inventory/material_receipt/domain/material_receipt_model.dart';
import 'package:owvds/features/inventory/material_export/presentation/bloc/material_export_cubit.dart';
import 'package:owvds/features/inventory/material_export/domain/material_export_model.dart';

// ── QC ───────────────────────────────────────────────────────────────────────
import 'package:owvds/features/qc/bom/presentation/bloc/bom_cubit.dart';
import 'package:owvds/features/qc/bom/domain/bom_model.dart';
import 'package:owvds/features/qc/loom_state_standard/presentation/bloc/loom_state_standard_cubit.dart';
import 'package:owvds/features/qc/loom_state_standard/domain/loom_state_standard_model.dart';

// ── Production ───────────────────────────────────────────────────────────────
import 'package:owvds/features/production/weaving_opperation/presentation/bloc/machine_operation_cubit.dart';
import 'package:owvds/features/production/weaving_analytics/presentation/bloc/weaving_analytics_cubit.dart';
import 'package:owvds/features/production/weaving_analytics/data/weaving_analytics_repository.dart';
import 'package:owvds/features/production/weaving_analytics/domain/weaving_analytics_model.dart';
import 'package:owvds/features/production/weaving_opperation/presentation/screens/machine_operation_utils.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────
const _kNavy = Color(0xFF0D1B2E);
const _kCard = Colors.white;
const _kBg = Color(0xFFF0F4FA);
const _kBorder = Color(0xFFE8EDF8);
const _kMuted = Color(0xFF8B97AB);
const _kBlue = Color(0xFF2563EB);
const _kTeal = Color(0xFF0D9488);
const _kPurple = Color(0xFF7C3AED);
const _kAmber = Color(0xFFF59E0B);
const _kGreen = Color(0xFF10B981);
const _kRed = Color(0xFFEF4444);

// Line status colours
const _kRunning = Color(0xFF10B981); // xanh lá
const _kIdle = Color(0xFFCBD5E1); // xám nhạt
const _kSetup = Color(0xFFF59E0B); // cam
const _kWaste = Color(0xFFEF4444); // đỏ

// =============================================================================
// ENTRY POINT
// =============================================================================
class DashboardContent extends StatelessWidget {
  final Color primaryColor;
  const DashboardContent({super.key, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          WeavingAnalyticsCubit(WeavingAnalyticsRepository())
            ..load(period: AnalyticsPeriod.day),
      child: const _DashboardBody(),
    );
  }
}

// =============================================================================
// BODY
// =============================================================================
class _DashboardBody extends StatefulWidget {
  const _DashboardBody();

  @override
  State<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<_DashboardBody> {
  final _numFmt = NumberFormat('#,##0.##', 'en_US');

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  void _loadAll() {
    context.read<EmployeeCubit>().loadPage(1);
    context.read<DepartmentCubit>().loadDepartments();
    context.read<MaterialCubit>().loadMaterials();
    context.read<MaterialInventoryCubit>().loadInventories();
    context.read<MaterialReceiptCubit>().loadInitial();
    context.read<MaterialExportCubit>().loadExports(isRefresh: true);
    context.read<StandardCubit>().loadStandards();
    context.read<BOMCubit>().loadBOMHeaders();
    syncActiveLineStatuses().then((_) {
      if (mounted) context.read<MachineOperationCubit>().loadDashboard();
    });
  }

  String _fmtKg(double kg) => kg >= 1000
      ? '${(kg / 1000).toStringAsFixed(2)} t'
      : '${kg.toStringAsFixed(1)} kg';

  String _relTime(DateTime? dt) {
    if (dt == null) return '—';
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'vừa xong';
    if (d.inMinutes < 60) return '${d.inMinutes}ph trước';
    if (d.inHours < 24) return '${d.inHours}h trước';
    return DateFormat('dd/MM').format(dt);
  }

  // Tính trạng thái từng dây chuyền
  String _lineStatus(MachineOpLoaded state, dynamic machine, int line) {
    final key = '${machine.id}_$line';
    final hasTicket = state.activeTickets[key] != null;
    final localStatus = globalLineStatuses[key]?.toUpperCase();
    if (localStatus != null && localStatus != 'NORMAL') return localStatus;
    return hasTicket ? 'RUNNING' : 'IDLE';
  }

  @override
  Widget build(BuildContext context) {
    // ── States ──────────────────────────────────────────────────────────────
    final empState = context.watch<EmployeeCubit>().state;
    final deptState = context.watch<DepartmentCubit>().state;
    final matState = context.watch<MaterialCubit>().state;
    final invState = context.watch<MaterialInventoryCubit>().state;
    final receiptState = context.watch<MaterialReceiptCubit>().state;
    final exportState = context.watch<MaterialExportCubit>().state;
    final standardState = context.watch<StandardCubit>().state;
    final bomState = context.watch<BOMCubit>().state;
    final machineState = context.watch<MachineOperationCubit>().state;
    final analyticsState = context.watch<WeavingAnalyticsCubit>().state;

    // ── Extract data ─────────────────────────────────────────────────────────
    final int totalEmp = empState is EmployeeLoaded ? empState.totalCount : 0;
    final List<Employee> employees = empState is EmployeeLoaded
        ? empState.employees
        : [];
    final List<Department> depts = deptState is DepartmentLoaded
        ? deptState.departments
        : [];

    final List<MaterialItem> materials = matState is MaterialLoaded
        ? matState.materials
        : [];
    final List<MaterialInventory> inventories =
        invState is MaterialInventoryLoaded ? invState.inventories : [];
    final List<MaterialReceipt> receipts = receiptState is MaterialReceiptLoaded
        ? receiptState.receipts
        : [];
    final List<MaterialExport> exports = exportState is MaterialExportLoaded
        ? exportState.exports
        : [];

    final List<Standard> standards = standardState is StandardLoaded
        ? standardState.displayedStandards
        : [];
    final List<BOMHeader> boms = bomState is BOMListLoaded ? bomState.boms : [];

    // Low stock
    final lowStock = inventories.where((inv) {
      final mat = materials.cast<MaterialItem?>().firstWhere(
        (m) => m?.materialId == inv.materialId,
        orElse: () => null,
      );
      return mat != null &&
          mat.minStockLevel > 0 &&
          inv.quantityKg < mat.minStockLevel;
    }).toList();

    // Production KPI
    ProductionKPI? kpi;
    if (analyticsState is WeavingAnalyticsLoaded) kpi = analyticsState.kpi;
    if (analyticsState is WeavingAnalyticsExporting)
      kpi = analyticsState.previousState.kpi;

    // Machine counts
    int runningM = 0, totalM = 0;
    if (machineState is MachineOpLoaded) {
      totalM = machineState.machines.length;
      for (final m in machineState.machines) {
        final lines = (m.totalLines ?? 0) > 0 ? m.totalLines! : 2;
        bool any = false;
        for (int l = 1; l <= lines; l++) {
          if (_lineStatus(machineState, m, l) == 'RUNNING') any = true;
        }
        if (any) runningM++;
      }
    }

    // Total kg in/out
    final totalKgIn = receipts.fold<double>(
      0,
      (s, r) =>
          s + r.details.fold<double>(0, (ss, d) => ss + d.receivedQuantityKg),
    );
    final totalKgOut = exports.fold<double>(
      0,
      (s, e) => s + e.details.fold<double>(0, (ss, d) => ss + d.quantityKg),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ────────────────────────────────────────────────────────────
        _Header(),
        const SizedBox(height: 20),

        // ── KPI Strip: 5 số nhanh ────────────────────────────────────────────
        _KpiStrip(
          runningM: runningM,
          totalM: totalM,
          kpiWeight: kpi != null ? _fmtKg(kpi.totalWeight) : null,
          wasteRate: kpi?.wasteRatePct,
          lowStockCnt: lowStock.length,
          totalEmp: totalEmp,
        ),
        const SizedBox(height: 20),

        // ── Hàng 1: Máy dệt + Kho NVL ────────────────────────────────────────
        _Row2(
          left: _MachinePanel(
            machineState: machineState,
            lineStatusFn: _lineStatus,
          ),
          right: _WarehousePanel(
            materials: materials,
            lowStock: lowStock,
            numFmt: _numFmt,
            totalKgIn: totalKgIn,
            totalKgOut: totalKgOut,
            receipts: receipts,
            exports: exports,
            relTime: _relTime,
          ),
          leftFlex: 3,
          rightFlex: 2,
        ),
        const SizedBox(height: 16),

        // ── Hàng 2: HR + QC ───────────────────────────────────────────────────
        _Row2(
          left: _HRPanel(
            depts: depts,
            employees: employees,
            totalEmp: totalEmp,
          ),
          right: _QCPanel(boms: boms, standards: standards, relTime: _relTime),
          leftFlex: 2,
          rightFlex: 2,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// =============================================================================
// RESPONSIVE ROW
// =============================================================================
class _Row2 extends StatelessWidget {
  final Widget left, right;
  final int leftFlex, rightFlex;
  const _Row2({
    required this.left,
    required this.right,
    required this.leftFlex,
    required this.rightFlex,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, c) => c.maxWidth > 820
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: leftFlex, child: left),
              const SizedBox(width: 16),
              Expanded(flex: rightFlex, child: right),
            ],
          )
        : Column(children: [left, const SizedBox(height: 16), right]),
  );
}

// =============================================================================
// HEADER
// =============================================================================
class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final h = DateTime.now().hour;
    final greeting = h < 12
        ? '🌤 Chào buổi sáng'
        : h < 18
        ? '☀️ Chào buổi chiều'
        : '🌙 Chào buổi tối';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bảng điều khiển',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: _kNavy,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                greeting,
                style: const TextStyle(fontSize: 13.5, color: _kMuted),
              ),
            ],
          ),
        ),
        _DateChip(),
      ],
    );
  }
}

class _DateChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.today_rounded, size: 13, color: _kMuted),
          const SizedBox(width: 6),
          Text(
            DateFormat('EEEE, dd/MM/yyyy', 'vi').format(DateTime.now()),
            style: const TextStyle(
              fontSize: 12,
              color: _kMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// KPI STRIP — 5 số nhanh ở đầu trang
// =============================================================================
class _KpiStrip extends StatelessWidget {
  final int runningM, totalM, lowStockCnt, totalEmp;
  final String? kpiWeight;
  final double? wasteRate;

  const _KpiStrip({
    required this.runningM,
    required this.totalM,
    required this.kpiWeight,
    required this.wasteRate,
    required this.lowStockCnt,
    required this.totalEmp,
  });

  @override
  Widget build(BuildContext context) {
    final wasteOk = wasteRate == null || wasteRate! <= 5;

    return LayoutBuilder(
      builder: (_, c) {
        final cols = c.maxWidth >= 1000
            ? 5
            : c.maxWidth >= 640
            ? 3
            : 2;
        return GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: c.maxWidth >= 1000 ? 2.6 : 2.2,
          children: [
            _KpiTile(
              label: 'Máy đang chạy',
              value: totalM > 0 ? '$runningM / $totalM' : '—',
              icon: Icons.precision_manufacturing_rounded,
              color: _kGreen,
              loading: totalM == 0,
              onTap: () => context.go('/machine-operations'),
            ),
            _KpiTile(
              label: 'Sản lượng hôm nay',
              value: kpiWeight ?? '—',
              icon: Icons.scale_rounded,
              color: _kBlue,
              loading: kpiWeight == null,
              onTap: () => context.go('/production-dashboard'),
            ),
            _KpiTile(
              label: 'Tỷ lệ phế',
              value: wasteRate != null
                  ? '${wasteRate!.toStringAsFixed(1)}%'
                  : '—',
              icon: Icons.warning_amber_rounded,
              color: wasteOk ? _kGreen : _kRed,
              loading: wasteRate == null,
              badge: !wasteOk ? '!' : null,
              onTap: () => context.go('/production-dashboard'),
            ),
            _KpiTile(
              label: 'Cảnh báo tồn kho',
              value: lowStockCnt > 0 ? '$lowStockCnt mục' : 'Đủ kho ✓',
              icon: lowStockCnt > 0
                  ? Icons.warning_rounded
                  : Icons.inventory_2_rounded,
              color: lowStockCnt > 0 ? _kRed : _kTeal,
              onTap: () => context.go('/warehouse-dashboard'),
            ),
            _KpiTile(
              label: 'Nhân viên',
              value: totalEmp > 0 ? '$totalEmp' : '—',
              icon: Icons.people_alt_rounded,
              color: _kPurple,
              loading: totalEmp == 0,
              onTap: () => context.go('/hr-dashboard'),
            ),
          ],
        );
      },
    );
  }
}

class _KpiTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final bool loading;
  final String? badge;
  final VoidCallback onTap;

  const _KpiTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
    this.loading = false,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kCard,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 11,
                        color: _kMuted,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    loading
                        ? SizedBox(
                            height: 14,
                            width: 50,
                            child: LinearProgressIndicator(
                              backgroundColor: _kBorder,
                              color: color.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          )
                        : Row(
                            children: [
                              Flexible(
                                child: Text(
                                  value,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: _kNavy,
                                    letterSpacing: -0.3,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (badge != null) ...[
                                const SizedBox(width: 4),
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: _kRed,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Text(
                                      '!',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// MACHINE PANEL — trạng thái từng máy + dây chuyền, quick-link vận hành
// =============================================================================
class _MachinePanel extends StatelessWidget {
  final MachineOpState machineState;
  final String Function(MachineOpLoaded, dynamic, int) lineStatusFn;

  const _MachinePanel({required this.machineState, required this.lineStatusFn});

  Color _statusColor(String status) => switch (status) {
    'RUNNING' => _kRunning,
    'SETUP' => _kSetup,
    'WASTE' => _kWaste,
    _ => _kIdle,
  };

  String _statusLabel(String status) => switch (status) {
    'RUNNING' => 'Đang chạy',
    'SETUP' => 'Setup',
    'WASTE' => 'Phế',
    'IDLE' => 'Chờ',
    _ => status,
  };

  @override
  Widget build(BuildContext context) {
    return _Card(
      headerIcon: Icons.precision_manufacturing_rounded,
      headerIconColor: _kBlue,
      title: 'Vận hành máy dệt',
      subtitle: 'Trạng thái dây chuyền realtime',
      actions: [
        _HeaderBtn(
          label: 'Dashboard Loom',
          icon: Icons.dashboard_customize_rounded,
          onTap: () => context.go('/loom-dashboard'),
        ),
        const SizedBox(width: 8),
        _HeaderBtn(
          label: 'Máy & Rổ dệt',
          icon: Icons.waves_rounded,
          onTap: () => context.go('/machine-operations'),
        ),
      ],
      child: machineState is! MachineOpLoaded
          ? const _LoadingPlaceholder(rows: 4)
          : Builder(
              builder: (context) {
                final s = machineState as MachineOpLoaded;
                if (s.machines.isEmpty) {
                  return const _EmptySlot(
                    icon: Icons.precision_manufacturing_outlined,
                    text: 'Chưa có dữ liệu máy',
                  );
                }
                return Column(
                  children: s.machines.map((machine) {
                    final totalLines = (machine.totalLines ?? 0) > 0
                        ? machine.totalLines!
                        : 2;
                    final lineStatuses = List.generate(
                      totalLines,
                      (i) => lineStatusFn(s, machine, i + 1),
                    );
                    final runningLines = lineStatuses
                        .where((st) => st == 'RUNNING')
                        .length;
                    final hasIssue = lineStatuses.any((st) => st == 'WASTE');

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: const Color(0xFFF8FAFD),
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          onTap: () => context.go('/machine-operations'),
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                // Tên máy
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: runningLines > 0
                                        ? _kBlue.withOpacity(0.1)
                                        : const Color(0xFFEEF0F5),
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: Icon(
                                    Icons.precision_manufacturing_rounded,
                                    size: 16,
                                    color: runningLines > 0 ? _kBlue : _kMuted,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              machine.machineName ??
                                                  'Máy ${machine.id}',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: _kNavy,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (hasIssue)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: _kRed.withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: const Text(
                                                'Phế',
                                                style: TextStyle(
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: _kRed,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      // Dây chuyền dots
                                      Wrap(
                                        spacing: 5,
                                        children: List.generate(totalLines, (
                                          i,
                                        ) {
                                          final status = lineStatuses[i];
                                          final color = _statusColor(status);
                                          return Tooltip(
                                            message:
                                                'Line ${i + 1}: ${_statusLabel(status)}',
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                    color: color,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(width: 3),
                                                Text(
                                                  'L${i + 1}',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: color,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                              ],
                                            ),
                                          );
                                        }),
                                      ),
                                    ],
                                  ),
                                ),
                                // Badge: x/y chạy
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: runningLines > 0
                                        ? _kGreen.withOpacity(0.1)
                                        : const Color(0xFFEEF0F5),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '$runningLines/$totalLines chạy',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: runningLines > 0
                                          ? _kGreen
                                          : _kMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
    );
  }
}

// =============================================================================
// WAREHOUSE PANEL — cảnh báo tồn + nhập/xuất gần đây
// =============================================================================
class _WarehousePanel extends StatelessWidget {
  final List<MaterialItem> materials;
  final List<MaterialInventory> lowStock;
  final NumberFormat numFmt;
  final double totalKgIn, totalKgOut;
  final List<MaterialReceipt> receipts;
  final List<MaterialExport> exports;
  final String Function(DateTime?) relTime;

  const _WarehousePanel({
    required this.materials,
    required this.lowStock,
    required this.numFmt,
    required this.totalKgIn,
    required this.totalKgOut,
    required this.receipts,
    required this.exports,
    required this.relTime,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      headerIcon: Icons.inventory_2_rounded,
      headerIconColor: _kTeal,
      title: 'Kho nguyên vật liệu',
      subtitle:
          '↓ ${numFmt.format(totalKgIn)} kg nhập  ·  ↑ ${numFmt.format(totalKgOut)} kg xuất',
      actions: [
        _HeaderBtn(
          label: 'Quản lý kho',
          icon: Icons.open_in_new_rounded,
          onTap: () => context.go('/warehouse-dashboard'),
        ),
      ],
      child: materials.isEmpty
          ? const _LoadingPlaceholder(rows: 3)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Cảnh báo tồn thấp ──
                if (lowStock.isNotEmpty) ...[
                  _SectionLabel('CẢNH BÁO TỒN THẤP', _kRed),
                  const SizedBox(height: 8),
                  ...lowStock.take(4).map((inv) {
                    final mat = materials.cast<MaterialItem?>().firstWhere(
                      (m) => m?.materialId == inv.materialId,
                      orElse: () => null,
                    );
                    final pct = (mat != null && mat.minStockLevel > 0)
                        ? (inv.quantityKg / mat.minStockLevel).clamp(0.0, 1.0)
                        : 0.0;
                    final urgent = pct < 0.3;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  mat?.materialCode ?? 'ID ${inv.materialId}',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: _kNavy,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${numFmt.format(inv.quantityKg)} kg',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: urgent ? _kRed : _kAmber,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: pct,
                              backgroundColor: Colors.grey.shade100,
                              color: urgent ? _kRed : _kAmber,
                              minHeight: 4,
                            ),
                          ),
                          if (mat != null)
                            Text(
                              'Tối thiểu ${numFmt.format(mat.minStockLevel)} kg — còn ${(pct * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 10,
                                color: _kMuted,
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                  if (lowStock.length > 4) ...[
                    GestureDetector(
                      onTap: () => context.go('/warehouse-dashboard'),
                      child: Text(
                        '+ ${lowStock.length - 4} mục khác →',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: _kTeal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Divider(height: 20, color: Colors.grey.shade100),
                ],

                // ── Hoạt động nhập/xuất gần đây ──
                _SectionLabel('NHẬP / XUẤT GẦN ĐÂY', _kTeal),
                const SizedBox(height: 8),
                ...(() {
                  // Gộp + sort theo thời gian
                  final entries =
                      <_MvEntry>[
                        ...receipts.take(5).map((r) {
                          final kg = r.details.fold<double>(
                            0,
                            (s, d) => s + d.receivedQuantityKg,
                          );
                          final date = (r.receiptDate?.isNotEmpty ?? false)
                              ? DateTime.tryParse(r.receiptDate!)?.toLocal()
                              : null;
                          return _MvEntry(
                            isIn: true,
                            code: r.receiptNumber ?? '—',
                            kg: kg,
                            date: date,
                          );
                        }),
                        ...exports.take(5).map((e) {
                          final kg = e.details.fold<double>(
                            0,
                            (s, d) => s + d.quantityKg,
                          );
                          return _MvEntry(
                            isIn: false,
                            code: e.exportCode,
                            kg: kg,
                            date: e.createdAt,
                          );
                        }),
                      ]..sort(
                        (a, b) => (b.date ?? DateTime(2000)).compareTo(
                          a.date ?? DateTime(2000),
                        ),
                      );

                  if (entries.isEmpty) {
                    return [
                      const _EmptySlot(
                        icon: Icons.swap_horiz_rounded,
                        text: 'Chưa có phiếu nhập/xuất',
                      ),
                    ];
                  }

                  return entries
                      .take(5)
                      .map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: (e.isIn ? _kTeal : _kAmber)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  e.isIn
                                      ? Icons.arrow_downward_rounded
                                      : Icons.arrow_upward_rounded,
                                  size: 13,
                                  color: e.isIn ? _kTeal : _kAmber,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  e.code,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: _kNavy,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${e.isIn ? "+" : "-"}${numFmt.format(e.kg)} kg',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: e.isIn ? _kTeal : _kAmber,
                                    ),
                                  ),
                                  Text(
                                    relTime(e.date),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: _kMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList();
                })(),
              ],
            ),
    );
  }
}

class _MvEntry {
  final bool isIn;
  final String code;
  final double kg;
  final DateTime? date;
  const _MvEntry({
    required this.isIn,
    required this.code,
    required this.kg,
    required this.date,
  });
}

// =============================================================================
// HR PANEL
// =============================================================================
class _HRPanel extends StatelessWidget {
  final List<Department> depts;
  final List<Employee> employees;
  final int totalEmp;

  const _HRPanel({
    required this.depts,
    required this.employees,
    required this.totalEmp,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      headerIcon: Icons.people_alt_rounded,
      headerIconColor: _kPurple,
      title: 'Nhân sự',
      subtitle: '$totalEmp nhân viên · ${depts.length} phòng ban',
      actions: [
        _HeaderBtn(
          label: 'Quản lý HR',
          icon: Icons.open_in_new_rounded,
          onTap: () => context.go('/hr-dashboard'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (depts.isNotEmpty) ...[
            _SectionLabel('PHÒNG BAN', _kPurple),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: depts
                  .take(8)
                  .map(
                    (d) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _kPurple.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _kPurple.withOpacity(0.15)),
                      ),
                      child: Text(
                        d.name,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: _kPurple,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 14),
            Divider(height: 1, color: Colors.grey.shade100),
            const SizedBox(height: 12),
          ],
          _SectionLabel('NHÂN VIÊN GẦN ĐÂY', _kPurple),
          const SizedBox(height: 8),
          if (employees.isEmpty)
            const _LoadingPlaceholder(rows: 3)
          else
            ...employees
                .take(5)
                .map(
                  (emp) => Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 15,
                          backgroundColor: _kPurple.withOpacity(0.1),
                          child: Text(
                            emp.fullName.isNotEmpty
                                ? emp.fullName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _kPurple,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                emp.fullName,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: _kNavy,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                emp.position.isNotEmpty
                                    ? emp.position
                                    : 'Nhân viên',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: _kMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

// =============================================================================
// QC PANEL
// =============================================================================
class _QCPanel extends StatelessWidget {
  final List<BOMHeader> boms;
  final List<Standard> standards;
  final String Function(DateTime?) relTime;

  const _QCPanel({
    required this.boms,
    required this.standards,
    required this.relTime,
  });

  @override
  Widget build(BuildContext context) {
    final activities =
        <_QCItem>[
          ...boms.map(
            (b) => _QCItem(
              label: 'Định mức BOM',
              desc: 'Mã SP: ${b.productId}  —  Năm ${b.applicableYear}',
              time: b.updatedAt,
              icon: Icons.scale_rounded,
              color: _kAmber,
            ),
          ),
          ...standards.map(
            (s) => _QCItem(
              label: 'Tiêu chuẩn BTP',
              desc: 'Mã: ${s.product?.itemCode ?? s.productId}',
              time: null,
              icon: Icons.precision_manufacturing_rounded,
              color: _kBlue,
            ),
          ),
        ]..sort(
          (a, b) =>
              (b.time ?? DateTime(2000)).compareTo(a.time ?? DateTime(2000)),
        );

    return _Card(
      headerIcon: Icons.verified_rounded,
      headerIconColor: _kAmber,
      title: 'Chất lượng (QC)',
      subtitle: '${standards.length} tiêu chuẩn · ${boms.length} định mức BOM',
      actions: [
        _HeaderBtn(
          label: 'Quản lý QC',
          icon: Icons.open_in_new_rounded,
          onTap: () => context.go('/qc-dashboard'),
        ),
      ],
      child: activities.isEmpty
          ? const _LoadingPlaceholder(rows: 4)
          : Column(
              children: activities
                  .take(8)
                  .map(
                    (act) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: act.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Icon(act.icon, color: act.color, size: 13),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  act.label,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _kNavy,
                                  ),
                                ),
                                Text(
                                  act.desc,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: _kMuted,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            relTime(act.time),
                            style: const TextStyle(
                              fontSize: 10,
                              color: _kMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _QCItem {
  final String label, desc;
  final DateTime? time;
  final IconData icon;
  final Color color;
  const _QCItem({
    required this.label,
    required this.desc,
    required this.time,
    required this.icon,
    required this.color,
  });
}

// =============================================================================
// SHARED WIDGETS
// =============================================================================

// ── Card container ────────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final IconData headerIcon;
  final Color headerIconColor;
  final String title, subtitle;
  final List<Widget> actions;
  final Widget child;

  const _Card({
    required this.headerIcon,
    required this.headerIconColor,
    required this.title,
    required this.subtitle,
    required this.actions,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Accent bar ───────────────────────────────────────────────────
          Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [headerIconColor, headerIconColor.withOpacity(0.3)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header row ───────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: headerIconColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(headerIcon, color: headerIconColor, size: 15),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _kNavy,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 11,
                              color: _kMuted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (actions.isNotEmpty)
                      Row(mainAxisSize: MainAxisSize.min, children: actions),
                  ],
                ),
                Divider(height: 20, color: Colors.grey.shade100),

                // ── Content ──────────────────────────────────────────────
                child,
                const SizedBox(height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header Button ─────────────────────────────────────────────────────────────
class _HeaderBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderBtn({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4FA),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: _kBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: _kBlue),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: _kBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _SectionLabel(this.text, this.color);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: 9.5,
      fontWeight: FontWeight.w800,
      color: color.withOpacity(0.7),
      letterSpacing: 1.3,
    ),
  );
}

// ── Loading placeholder ───────────────────────────────────────────────────────
class _LoadingPlaceholder extends StatelessWidget {
  final int rows;
  const _LoadingPlaceholder({this.rows = 3});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: List.generate(
      rows,
      (i) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          height: 12,
          width: i % 2 == 0 ? double.infinity : 180,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FA),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    ),
  );
}

// ── Empty slot ────────────────────────────────────────────────────────────────
class _EmptySlot extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptySlot({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 36, color: const Color(0xFFCBD5E1)),
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(fontSize: 13, color: _kMuted)),
        ],
      ),
    ),
  );
}
