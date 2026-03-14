// lib/features/production/dashboard/production_dashboard.dart
//
// Yêu cầu pubspec.yaml:
//   fl_chart: ^0.68.0
//   flutter_bloc: ^8.x
//   go_router: ^13.x
//   intl: ^0.19.0
//
// Phụ thuộc nội bộ:
//   - WeavingAnalyticsCubit  (analytics data + Excel export)
//   - NotificationCubit       (thông báo realtime)
//   - MachineOperationCubit   (số máy đang chạy)

import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:owvds/features/production/weaving_analytics/presentation/bloc/weaving_analytics_cubit.dart';

// Core
import '../../../../../core/widgets/responsive_layout.dart';
import 'package:owvds/core/network/websocket_service.dart';

// Machine operation
import 'package:owvds/features/production/weaving_opperation/presentation/bloc/machine_operation_cubit.dart';
import 'package:owvds/features/production/weaving_opperation/presentation/screens/machine_operation_utils.dart';

// Analytics
import 'package:owvds/features/production/weaving_analytics/data/weaving_analytics_repository.dart';
import 'package:owvds/features/production/weaving_analytics/domain/weaving_analytics_model.dart';

// Notifications
import 'package:owvds/features/production/notifications/data/notification_service.dart';
import 'package:owvds/features/production/notifications/domain/notification_model.dart';
import 'package:owvds/features/production/notifications/presentation/notification_cubit.dart';

// Weaving tickets — đếm số phiếu đang xử lý (timeOut == null)
import 'package:owvds/features/production/weaving/data/weaving_repository.dart';
import 'package:owvds/features/production/weaving/presentation/bloc/weaving_cubit.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Bảng màu toàn cục trong file
// ─────────────────────────────────────────────────────────────────────────────
const Color _kPrimary = Color(0xFF003366);
const Color _kWaste = Color(0xFFE53935);
const Color _kSetup = Color(0xFFFF8F00);
const Color _kSuccess = Color(0xFF2E7D32);

const List<Color> _kChartColors = [
  Color(0xFF1565C0),
  Color(0xFF00897B),
  Color(0xFF7B1FA2),
  Color(0xFFF57C00),
  Color(0xFF558B2F),
  Color(0xFFC62828),
  Color(0xFF00838F),
  Color(0xFF4527A0),
];

// ─────────────────────────────────────────────────────────────────────────────
// ROOT WIDGET — bọc BlocProviders
// ─────────────────────────────────────────────────────────────────────────────
class ProductionDashboard extends StatelessWidget {
  const ProductionDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              WeavingAnalyticsCubit(WeavingAnalyticsRepository())
                ..load(period: AnalyticsPeriod.day),
        ),
        BlocProvider(create: (_) => NotificationCubit(), lazy: false),
        BlocProvider(
          create: (_) => WeavingCubit(WeavingRepository())..loadTickets(),
        ),
      ],
      child: const _ProductionDashboardBody(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BODY — toàn bộ logic giữ nguyên từ bản gốc, chỉ mở rộng
// ─────────────────────────────────────────────────────────────────────────────
class _ProductionDashboardBody extends StatefulWidget {
  const _ProductionDashboardBody();

  @override
  State<_ProductionDashboardBody> createState() => _ProductionDashboardState();
}

class _ProductionDashboardState extends State<_ProductionDashboardBody> {
  final Color _primaryColor = _kPrimary;

  // Bộ lọc cho biểu đồ (giữ nguyên tên biến gốc)
  String _selectedTimeframe = 'Ngày';
  final List<String> _timeframes = ['Ca', 'Ngày', 'Tuần', 'Tháng', 'Năm'];

  // Analytics period
  AnalyticsPeriod _analyticsPeriod = AnalyticsPeriod.day;
  DateTimeRange? _customDateRange;

  // Panel thông báo
  bool _notifPanelOpen = false;

  @override
  void initState() {
    super.initState();
    syncActiveLineStatuses().then((_) {
      if (mounted) context.read<MachineOperationCubit>().loadDashboard();
    });

    // Kết nối WebSocket và lắng nghe events
    WebSocketService().connect();
    WebSocketService().addListener(_onWebSocketMessage);
  }

  @override
  void dispose() {
    WebSocketService().removeListener(_onWebSocketMessage);
    super.dispose();
  }

  void _onWebSocketMessage(String message) {
    // Chuyển WS message → thông báo hiển thị
    NotificationService.instance.handleWebSocketMessage(message);

    // Reload nếu cần
    if (message == 'REFRESH_MACHINES' || message == 'REFRESH_MACHINE_BATCHES') {
      syncActiveLineStatuses().then((_) {
        if (mounted) context.read<MachineOperationCubit>().loadDashboard();
      });
    }
    // Reload analytics KPI hôm nay
    if (message == 'REFRESH_MACHINE_BATCHES' || message == 'REFRESH_BASKETS') {
      if (mounted) {
        context.read<WeavingAnalyticsCubit>().changePeriod(
          _analyticsPeriod,
          startDate: _customDateRange?.start,
          endDate: _customDateRange?.end,
        );
      }
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Period helpers
  // ──────────────────────────────────────────────────────────────────────────
  AnalyticsPeriod _periodFromLabel(String label) => AnalyticsPeriod.values
      .firstWhere((p) => p.label == label, orElse: () => AnalyticsPeriod.day);

  void _onPeriodChanged(String label) {
    final period = _periodFromLabel(label);
    setState(() {
      _analyticsPeriod = period;
      _selectedTimeframe = label;
      _customDateRange = null;
    });
    context.read<WeavingAnalyticsCubit>().changePeriod(period);
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange:
          _customDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 6)),
            end: DateTime.now(),
          ),
      builder: (ctx, child) => Theme(
        data: Theme.of(
          ctx,
        ).copyWith(colorScheme: const ColorScheme.light(primary: _kPrimary)),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _customDateRange = picked);
      context.read<WeavingAnalyticsCubit>().changePeriod(
        _analyticsPeriod,
        startDate: picked.start,
        endDate: picked.end,
      );
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Excel export
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> _exportExcel(String exportType) async {
    context.read<WeavingAnalyticsCubit>().exportExcel(
      exportType: exportType,
      onSuccess: (bytes, filename) {
        // ── Trigger browser download (Flutter Web) ──
        try {
          final blob = html.Blob(
            [bytes],
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          );
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement(href: url)
            ..setAttribute('download', filename)
            ..style.display = 'none';
          html.document.body!.append(anchor);
          anchor.click();
          anchor.remove();
          html.Url.revokeObjectUrl(url);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Đang tải xuống: $filename'),
                backgroundColor: Colors.green.shade700,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Lỗi tải file: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      onError: (err) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err), backgroundColor: Colors.red),
          );
        }
      },
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Stack(
      children: [
        // ── Nội dung chính ──
        SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            isDesktop ? 0 : 0,
            0,
            isDesktop ? 0 : 0,
            40,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── TIÊU ĐỀ + NÚT THÔNG BÁO ──
              _buildHeader(isDesktop),
              const SizedBox(height: 24),

              // ── 1. KPI CARDS ──
              _buildKpiSection(isDesktop),
              const SizedBox(height: 24),

              // ── 2. BIỂU ĐỒ SẢN LƯỢNG DỆT ──
              _buildChartSection(),
              const SizedBox(height: 32),

              // ── 3. MENU TRUY CẬP NHANH ──
              _buildSectionTitle('DANH MỤC HỆ THỐNG', Icons.folder_special),
              _buildGridMenu([
                {
                  'title': 'Bán thành phẩm',
                  'icon': Icons.category,
                  'color': Colors.indigo,
                  'route': '/semi-finished',
                },
                {
                  'title': 'Thành phẩm',
                  'icon': Icons.check_circle,
                  'color': Colors.deepPurple,
                  'route': '#',
                },
                {
                  'title': 'Máy móc',
                  'icon': Icons.settings_input_component,
                  'color': Colors.blueGrey,
                  'route': '/machine-managements',
                },
                {
                  'title': 'Rổ chứa',
                  'icon': Icons.shopping_basket,
                  'color': Colors.brown,
                  'route': '/baskets',
                },
                {
                  'title': 'Phụ tùng',
                  'icon': Icons.build,
                  'color': Colors.grey.shade700,
                  'route': '#',
                },
              ]),
              const SizedBox(height: 24),

              _buildSectionTitle('VẬN HÀNH QUY TRÌNH', Icons.play_circle_fill),
              _buildGridMenu([
                {
                  'title': 'Quản lý loom dệt',
                  'icon': Icons.dashboard_customize,
                  'color': Colors.blue.shade800,
                  'route': '/loom-dashboard',
                },
                {
                  'title': 'Thông tin Máy & Rổ dệt',
                  'icon': Icons.waves,
                  'color': Colors.blue,
                  'route': '/machine-operations',
                },
                {
                  'title': 'Quy trình Nhuộm',
                  'icon': Icons.format_color_fill,
                  'color': Colors.purple,
                  'route': '#',
                },
                {
                  'title': 'Quy trình Cắt',
                  'icon': Icons.content_cut,
                  'color': Colors.redAccent,
                  'route': '#',
                },
                {
                  'title': 'Quy trình Cuộn',
                  'icon': Icons.toll,
                  'color': Colors.teal,
                  'route': '#',
                },
                {
                  'title': 'Đóng gói',
                  'icon': Icons.inventory_2,
                  'color': Colors.orange,
                  'route': '#',
                },
              ]),
              const SizedBox(height: 24),

              _buildSectionTitle('QUẢN LÝ PHIẾU (TICKETS)', Icons.receipt_long),
              _buildGridMenu([
                {
                  'title': 'Phiếu Rổ Dệt',
                  'icon': Icons.receipt,
                  'color': Colors.blue.shade700,
                  'route': '/weaving-tickets',
                },
                {
                  'title': 'Phiếu Rổ Nhuộm',
                  'icon': Icons.receipt,
                  'color': Colors.purple.shade700,
                  'route': '#',
                },
                {
                  'title': 'Phiếu Cuộn',
                  'icon': Icons.receipt,
                  'color': Colors.teal.shade700,
                  'route': '#',
                },
                {
                  'title': 'Phiếu Cắt',
                  'icon': Icons.receipt,
                  'color': Colors.redAccent.shade700,
                  'route': '#',
                },
                {
                  'title': 'Phiếu In',
                  'icon': Icons.print,
                  'color': Colors.cyan.shade700,
                  'route': '#',
                },
                {
                  'title': 'Phiếu Đóng gói',
                  'icon': Icons.local_shipping,
                  'color': Colors.orange.shade700,
                  'route': '#',
                },
              ]),
              const SizedBox(height: 40),
            ],
          ),
        ),

        // ── Panel thông báo trượt từ phải ──
        _buildNotificationPanel(),
      ],
    );
  }

  // ============================================================================
  // HEADER
  // ============================================================================
  Widget _buildHeader(bool isDesktop) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'QUẢN LÝ SẢN XUẤT',
          style: TextStyle(
            fontSize: isDesktop ? 26 : 22,
            fontWeight: FontWeight.bold,
            color: _primaryColor,
          ),
        ),
        // Nút chuông thông báo
        BlocBuilder<NotificationCubit, NotificationState>(
          builder: (ctx, state) {
            return IconButton(
              tooltip: 'Thông báo',
              icon: Badge(
                label: state.unreadCount > 0
                    ? Text(
                        '${state.unreadCount > 99 ? '99+' : state.unreadCount}',
                      )
                    : null,
                isLabelVisible: state.unreadCount > 0,
                backgroundColor: Colors.redAccent,
                child: Icon(
                  _notifPanelOpen
                      ? Icons.notifications_active
                      : Icons.notifications_outlined,
                  color: _notifPanelOpen ? _primaryColor : Colors.grey.shade600,
                  size: 28,
                ),
              ),
              onPressed: () {
                setState(() => _notifPanelOpen = !_notifPanelOpen);
                if (_notifPanelOpen) {
                  context.read<NotificationCubit>().markAllRead();
                }
              },
            );
          },
        ),
      ],
    );
  }

  // ============================================================================
  // KPI SECTION — Sản lượng dệt hôm nay (kg THẬT) + máy đang chạy
  // ============================================================================
  Widget _buildKpiSection(bool isDesktop) {
    return BlocBuilder<MachineOperationCubit, MachineOpState>(
      builder: (context, machineState) {
        // ── Tính số máy đang chạy (logic giữ nguyên từ bản gốc) ──
        String runningMachineText = '...';
        if (machineState is MachineOpLoaded) {
          int runningMachinesCount = 0;
          int totalMachinesCount = machineState.machines.length;

          for (var machine in machineState.machines) {
            int totalLines = (machine.totalLines ?? 0) > 0
                ? machine.totalLines!
                : 2;
            int runningLineCount = 0;
            int otherStatusCount = 0;

            for (int line = 1; line <= totalLines; line++) {
              final lineCode = line.toString();
              final hasTicket =
                  machineState.activeTickets['${machine.id}_$lineCode'] != null;
              final localStatus = globalLineStatuses['${machine.id}_$lineCode']
                  ?.toUpperCase();

              String currentLineStatus;
              if (localStatus != null && localStatus != 'NORMAL') {
                currentLineStatus = localStatus;
              } else {
                currentLineStatus = hasTicket ? 'RUNNING' : 'IDLE';
              }

              if (currentLineStatus == 'RUNNING') {
                runningLineCount++;
              } else if (currentLineStatus != 'IDLE') {
                otherStatusCount++;
              }
            }

            if (runningLineCount > 0 && otherStatusCount == 0) {
              runningMachinesCount++;
            }
          }
          runningMachineText = '$runningMachinesCount/$totalMachinesCount';
        }

        // ── Lấy KPI sản lượng hôm nay từ WeavingAnalyticsCubit ──
        return BlocBuilder<WeavingAnalyticsCubit, WeavingAnalyticsState>(
          builder: (ctx, analyticsState) {
            String todayWeightText = '...';
            String todayWasteRateText = '...';

            ProductionKPI? kpi;
            if (analyticsState is WeavingAnalyticsLoaded) {
              kpi = analyticsState.kpi;
            } else if (analyticsState is WeavingAnalyticsExporting) {
              kpi = analyticsState.previousState.kpi;
            }

            if (kpi != null) {
              todayWeightText = _fmtKg(kpi.totalWeight);
              todayWasteRateText = '${kpi.wasteRatePct.toStringAsFixed(1)}%';
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = constraints.maxWidth < 600
                    ? 2
                    : (constraints.maxWidth < 1200 ? 2 : 4);
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: isDesktop ? 2.5 : 2.0,
                  children: [
                    // ── Sản lượng dệt hôm nay (KG THẬT) ──
                    _buildKPICard(
                      'Sản lượng Dệt hôm nay',
                      '$todayWeightText kg',
                      Icons.scale_rounded,
                      Colors.blue,
                      subtitle: _analyticsPeriod == AnalyticsPeriod.day
                          ? 'Hôm nay'
                          : _selectedTimeframe,
                    ),
                    // ── Tỷ lệ phế ──
                    _buildKPICard(
                      'Tỷ lệ phế',
                      todayWasteRateText,
                      Icons.warning_amber_rounded,
                      kpi != null && kpi.wasteRatePct > 5
                          ? Colors.red
                          : Colors.green,
                      subtitle: 'Run + Setup',
                    ),
                    // ── Máy đang chạy (dữ liệu thật) ──
                    _buildKPICard(
                      'Máy đang chạy',
                      runningMachineText,
                      Icons.precision_manufacturing,
                      Colors.green,
                    ),
                    // ── Phiếu đang xử lý (dữ liệu thật) ──
                    BlocBuilder<WeavingCubit, WeavingState>(
                      builder: (ctx, weavingState) {
                        final String countText;
                        if (weavingState is WeavingLoading) {
                          countText = '...';
                        } else if (weavingState is WeavingLoaded) {
                          final count = weavingState.tickets
                              .where((t) => t.timeOut == null)
                              .length;
                          countText = '$count';
                        } else {
                          countText = '—';
                        }
                        return _buildKPICard(
                          'Phiếu đang xử lý',
                          countText,
                          Icons.assignment_late,
                          Colors.orange,
                        );
                      },
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  // ============================================================================
  // BIỂU ĐỒ SẢN LƯỢNG DỆT — 3 tabs + bộ lọc + xuất Excel
  // ============================================================================
  Widget _buildChartSection() {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Tiêu đề section ──
        _buildSectionTitle('SẢN LƯỢNG DỆT', Icons.bar_chart_rounded),

        // ── Container biểu đồ ──
        DefaultTabController(
          length: 3,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header: Tabs + Bộ lọc ──
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.black12)),
                  ),
                  child: isMobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildChartTabs(),
                            const SizedBox(height: 10),
                            _buildChartFilters(),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: _buildChartTabs()),
                            _buildChartFilters(),
                          ],
                        ),
                ),

                // ── KPI banner ──
                _buildAnalyticsKpiBanner(),

                // ── Nội dung biểu đồ ──
                SizedBox(
                  height: 360,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                    child: TabBarView(
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildMachineWeightChartTab(),
                        _buildMachineWasteChartTab(),
                        _buildProductChartTab(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChartTabs() {
    return TabBar(
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      labelColor: _primaryColor,
      unselectedLabelColor: Colors.grey,
      indicatorColor: _primaryColor,
      indicatorWeight: 3,
      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      dividerColor: Colors.transparent,
      tabs: const [
        Tab(
          icon: Icon(Icons.factory_outlined, size: 17),
          text: 'SẢN LƯỢNG THEO MÁY',
        ),
        Tab(
          icon: Icon(Icons.warning_amber_rounded, size: 17),
          text: 'PHẾ THEO MÁY',
        ),
        Tab(
          icon: Icon(Icons.inventory_2_outlined, size: 17),
          text: 'SẢN LƯỢNG THEO MÃ SP',
        ),
      ],
    );
  }

  Widget _buildChartFilters() {
    return BlocBuilder<WeavingAnalyticsCubit, WeavingAnalyticsState>(
      builder: (ctx, state) {
        final isExporting = state is WeavingAnalyticsExporting;
        return Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (_customDateRange != null)
              Chip(
                label: Text(
                  '${_fmtD(_customDateRange!.start)}–${_fmtD(_customDateRange!.end)}',
                  style: TextStyle(fontSize: 11, color: _primaryColor),
                ),
                deleteIcon: const Icon(Icons.close, size: 14),
                onDeleted: () {
                  setState(() => _customDateRange = null);
                  context.read<WeavingAnalyticsCubit>().changePeriod(
                    _analyticsPeriod,
                  );
                },
                backgroundColor: _primaryColor.withOpacity(0.08),
                side: BorderSide.none,
              ),
            InkWell(
              onTap: _pickDateRange,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                height: 33,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: _primaryColor.withOpacity(0.35)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.date_range, size: 15, color: _primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      'Khoảng ngày',
                      style: TextStyle(
                        fontSize: 12,
                        color: _primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              height: 33,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: DropdownButton<String>(
                value: _selectedTimeframe,
                underline: const SizedBox(),
                icon: Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: _primaryColor,
                ),
                isDense: true,
                style: TextStyle(
                  fontSize: 12,
                  color: _primaryColor,
                  fontWeight: FontWeight.bold,
                ),
                items: _timeframes
                    .map(
                      (e) => DropdownMenuItem(value: e, child: Text('Theo $e')),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) _onPeriodChanged(val);
                },
              ),
            ),
            ElevatedButton.icon(
              onPressed: isExporting ? null : () => _exportExcel('all'),
              icon: isExporting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.file_download, size: 16),
              label: Text(
                isExporting ? 'Đang xuất...' : 'Xuất Excel',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(0, 33),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── KPI banner tổng nhanh trên chart ──
  Widget _buildAnalyticsKpiBanner() {
    return BlocBuilder<WeavingAnalyticsCubit, WeavingAnalyticsState>(
      builder: (ctx, state) {
        ProductionKPI? kpi;
        if (state is WeavingAnalyticsLoaded) kpi = state.kpi;
        if (state is WeavingAnalyticsExporting) kpi = state.previousState.kpi;
        if (kpi == null) return const SizedBox.shrink();

        final wasteColor = kpi.wasteRatePct > 5
            ? Colors.red.shade700
            : _kSuccess;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: _primaryColor.withOpacity(0.03),
            border: const Border(bottom: BorderSide(color: Colors.black12)),
          ),
          child: Wrap(
            spacing: 24,
            runSpacing: 6,
            children: [
              _kpiBannerItem(
                'Sản lượng kỳ',
                '${_fmtKg(kpi.totalWeight)} kg',
                Colors.blue.shade700,
              ),
              _kpiBannerItem(
                'Phế Run',
                '${_fmtKg(kpi.totalRunWaste)} kg',
                Colors.red.shade600,
              ),
              _kpiBannerItem(
                'Phế Setup',
                '${_fmtKg(kpi.totalSetupWaste)} kg',
                Colors.orange.shade700,
              ),
              _kpiBannerItem(
                'Tỷ lệ phế',
                '${kpi.wasteRatePct.toStringAsFixed(1)}%',
                wasteColor,
              ),
              _kpiBannerItem(
                'Bản ghi',
                '${kpi.recordCount}',
                Colors.grey.shade600,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _kpiBannerItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  // ── 3 tabs nội dung biểu đồ ──
  Widget _buildMachineWeightChartTab() =>
      BlocBuilder<WeavingAnalyticsCubit, WeavingAnalyticsState>(
        builder: (ctx, state) {
          if (state is WeavingAnalyticsLoading) return _chartLoading();
          if (state is WeavingAnalyticsError) return _chartError(state.message);
          final data = _getMachineData(state);
          if (data == null || data.items.isEmpty) return _chartEmpty();
          return _MachineGroupedBarChart(
            data: data,
            valueKey: 'weight',
            primaryColor: _primaryColor,
          );
        },
      );

  Widget _buildMachineWasteChartTab() =>
      BlocBuilder<WeavingAnalyticsCubit, WeavingAnalyticsState>(
        builder: (ctx, state) {
          if (state is WeavingAnalyticsLoading) return _chartLoading();
          if (state is WeavingAnalyticsError) return _chartError(state.message);
          final data = _getMachineData(state);
          if (data == null || data.items.isEmpty) return _chartEmpty();
          return _MachineGroupedBarChart(
            data: data,
            valueKey: 'waste',
            primaryColor: Colors.red.shade700,
          );
        },
      );

  Widget _buildProductChartTab() =>
      BlocBuilder<WeavingAnalyticsCubit, WeavingAnalyticsState>(
        builder: (ctx, state) {
          if (state is WeavingAnalyticsLoading) return _chartLoading();
          if (state is WeavingAnalyticsError) return _chartError(state.message);
          final data = _getProductData(state);
          if (data == null || data.items.isEmpty) return _chartEmpty();
          return _ProductBarChart(data: data, primaryColor: _primaryColor);
        },
      );

  ProductionByMachineResponse? _getMachineData(WeavingAnalyticsState s) {
    if (s is WeavingAnalyticsLoaded) return s.byMachine;
    if (s is WeavingAnalyticsExporting) return s.previousState.byMachine;
    return null;
  }

  ProductionByProductResponse? _getProductData(WeavingAnalyticsState s) {
    if (s is WeavingAnalyticsLoaded) return s.byProduct;
    if (s is WeavingAnalyticsExporting) return s.previousState.byProduct;
    return null;
  }

  Widget _chartLoading() => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(strokeWidth: 2),
        SizedBox(height: 8),
        Text('Đang tải...', style: TextStyle(color: Colors.grey)),
      ],
    ),
  );

  Widget _chartError(String msg) => Center(
    child: Text(
      msg,
      style: const TextStyle(color: Colors.redAccent, fontSize: 12),
      textAlign: TextAlign.center,
    ),
  );

  Widget _chartEmpty() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.bar_chart_rounded, color: Colors.grey.shade300, size: 52),
        const SizedBox(height: 8),
        Text(
          'Không có dữ liệu trong kỳ này',
          style: TextStyle(color: Colors.grey.shade400),
        ),
      ],
    ),
  );

  // ============================================================================
  // NOTIFICATION PANEL — trượt từ phải vào
  // ============================================================================
  Widget _buildNotificationPanel() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
      right: _notifPanelOpen ? 0 : -340,
      top: 0,
      bottom: 0,
      width: 320,
      child: Material(
        elevation: 16,
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
        color: Colors.white,
        child: Column(
          children: [
            // Header panel
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              decoration: BoxDecoration(
                color: _primaryColor,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.notifications_active,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'THÔNG BÁO',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  BlocBuilder<NotificationCubit, NotificationState>(
                    builder: (ctx, state) => TextButton(
                      onPressed: state.notifications.isEmpty
                          ? null
                          : () => ctx.read<NotificationCubit>().clearAll(),
                      child: const Text(
                        'Xoá tất cả',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _notifPanelOpen = false),
                  ),
                ],
              ),
            ),

            // Danh sách thông báo
            Expanded(
              child: BlocBuilder<NotificationCubit, NotificationState>(
                builder: (ctx, state) {
                  if (state.notifications.isEmpty) {
                    return _buildEmptyNotif();
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: state.notifications.length,
                    separatorBuilder: (_, __) =>
                        Divider(color: Colors.grey.shade100, height: 1),
                    itemBuilder: (ctx, i) =>
                        _buildNotifItem(ctx, state.notifications[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyNotif() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'Chưa có thông báo nào',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Thông báo xuất hiện khi\ncó hoạt động sản xuất',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotifItem(BuildContext ctx, AppNotification notif) {
    final color = Color(notif.colorValue);
    final timeStr = _fmtTime(notif.time);

    return InkWell(
      onTap: () => ctx.read<NotificationCubit>().markRead(notif.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        color: notif.isRead ? Colors.transparent : color.withOpacity(0.05),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(notif.icon, style: const TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(width: 10),
            // Nội dung
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          notif.title,
                          style: TextStyle(
                            fontWeight: notif.isRead
                                ? FontWeight.w500
                                : FontWeight.bold,
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notif.message,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Badge loại
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      notif.typeLabel,
                      style: TextStyle(
                        fontSize: 9,
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Nút xoá
            GestureDetector(
              onTap: () => ctx.read<NotificationCubit>().remove(notif.id),
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(Icons.close, size: 14, color: Colors.grey.shade400),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // GIỮ NGUYÊN: _buildKPICard, _buildSectionTitle, _buildGridMenu
  // ============================================================================
  Widget _buildKPICard(
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: _primaryColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(icon, color: _primaryColor, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: Divider(color: Colors.grey.shade300)),
        ],
      ),
    );
  }

  Widget _buildGridMenu(List<Map<String, dynamic>> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 2;
        if (constraints.maxWidth >= 600 && constraints.maxWidth < 1000) {
          crossAxisCount = 4;
        }
        if (constraints.maxWidth >= 1000) crossAxisCount = 6;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return InkWell(
              onTap: () {
                if (item['route'] != '#') {
                  context.go(item['route']);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Tính năng ${item['title']} đang phát triển!',
                      ),
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item['icon'], size: 32, color: item['color']),
                    const SizedBox(height: 12),
                    Text(
                      item['title'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Format helpers ──
  String _fmtKg(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(2)}t';
    return v.toStringAsFixed(1);
  }

  String _fmtD(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  String _fmtTime(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inSeconds < 60) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes}p trước';
    if (diff.inHours < 24) return '${diff.inHours}h trước';
    return DateFormat('dd/MM HH:mm').format(d);
  }
}

// =============================================================================
// CHART WIDGET: Biểu đồ cột nhóm theo Máy
// =============================================================================
class _MachineGroupedBarChart extends StatefulWidget {
  final ProductionByMachineResponse data;
  final String valueKey;
  final Color primaryColor;

  const _MachineGroupedBarChart({
    required this.data,
    required this.valueKey,
    required this.primaryColor,
  });

  @override
  State<_MachineGroupedBarChart> createState() =>
      _MachineGroupedBarChartState();
}

class _MachineGroupedBarChartState extends State<_MachineGroupedBarChart> {
  int? _touchedGroupIndex;

  @override
  Widget build(BuildContext context) {
    final labels = widget.data.periodLabels;
    final machines = widget.data.machineLabels;
    if (labels.isEmpty || machines.isEmpty) return const SizedBox();

    double maxY = 0;
    for (final item in widget.data.items) {
      final v = widget.valueKey == 'weight'
          ? item.totalWeight
          : item.totalWaste;
      if (v > maxY) maxY = v;
    }
    if (maxY == 0) maxY = 10;

    final groups = <BarChartGroupData>[];
    for (int gi = 0; gi < labels.length; gi++) {
      final label = labels[gi];
      final rods = <BarChartRodData>[];

      for (int mi = 0; mi < machines.length; mi++) {
        final mLabel = machines[mi];
        final match = widget.data.items
            .where((it) => it.periodLabel == label && it.machineLabel == mLabel)
            .toList();

        double val = 0, runVal = 0, setupVal = 0;
        if (match.isNotEmpty) {
          if (widget.valueKey == 'weight') {
            val = match.first.totalWeight;
          } else {
            runVal = match.first.runWaste;
            setupVal = match.first.setupWaste;
            val = runVal + setupVal;
          }
        }

        final color = _kChartColors[mi % _kChartColors.length];
        rods.add(
          BarChartRodData(
            toY: val,
            color: color.withOpacity(_touchedGroupIndex == gi ? 1.0 : 0.82),
            width: machines.length > 5 ? 9 : 13,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
            rodStackItems: widget.valueKey == 'waste' && val > 0
                ? [
                    BarChartRodStackItem(0, runVal, color),
                    BarChartRodStackItem(
                      runVal,
                      val,
                      Colors.orange.shade300.withOpacity(0.9),
                    ),
                  ]
                : [],
          ),
        );
      }

      groups.add(BarChartGroupData(x: gi, barRods: rods, barsSpace: 3));
    }

    return Column(
      children: [
        // Legend
        Wrap(
          spacing: 14,
          runSpacing: 4,
          children: List.generate(machines.length, (i) {
            final color = _kChartColors[i % _kChartColors.length];
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  machines[i],
                  style: const TextStyle(fontSize: 10, color: Colors.black54),
                ),
              ],
            );
          }),
        ),
        if (widget.valueKey == 'waste') ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _dot(Colors.blue.shade600, 'Phế Run'),
              const SizedBox(width: 16),
              _dot(Colors.orange.shade300, 'Phế Setup'),
            ],
          ),
        ],
        const SizedBox(height: 6),
        Expanded(
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY * 1.18,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, gi, rod, ri) {
                    if (ri >= machines.length) return null;
                    final unit = widget.valueKey == 'weight'
                        ? 'kg SL'
                        : 'kg phế';
                    return BarTooltipItem(
                      '${machines[ri]}\n${rod.toY.toStringAsFixed(1)} $unit',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    );
                  },
                ),
                touchCallback: (event, response) => setState(() {
                  _touchedGroupIndex = response?.spot?.touchedBarGroupIndex;
                }),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (val, meta) {
                      final idx = val.toInt();
                      if (idx < 0 || idx >= labels.length) {
                        return const SizedBox();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          labels[idx],
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    getTitlesWidget: (val, meta) => Text(
                      val >= 1000
                          ? '${(val / 1000).toStringAsFixed(1)}t'
                          : val.toStringAsFixed(0),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black38,
                      ),
                    ),
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (v) =>
                    FlLine(color: Colors.grey.shade100, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              barGroups: groups,
            ),
          ),
        ),
      ],
    );
  }

  Widget _dot(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.black45)),
    ],
  );
}

// =============================================================================
// CHART WIDGET: Biểu đồ sản lượng theo Mã sản phẩm
// =============================================================================
class _ProductBarChart extends StatefulWidget {
  final ProductionByProductResponse data;
  final Color primaryColor;

  const _ProductBarChart({required this.data, required this.primaryColor});

  @override
  State<_ProductBarChart> createState() => _ProductBarChartState();
}

class _ProductBarChartState extends State<_ProductBarChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final totals = <String, double>{};
    for (final item in widget.data.items) {
      totals[item.itemCode] = (totals[item.itemCode] ?? 0) + item.totalWeight;
    }

    final sorted = totals.keys.toList()
      ..sort((a, b) => (totals[b] ?? 0).compareTo(totals[a] ?? 0));
    final top = sorted.take(12).toList();

    final maxY = top
        .map((c) => totals[c] ?? 0.0)
        .fold(0.0, (a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY * 1.18,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, gi, rod, ri) {
              final code = top[gi];
              return BarTooltipItem(
                '$code\n${rod.toY.toStringAsFixed(1)} kg',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              );
            },
          ),
          touchCallback: (event, response) => setState(() {
            _touchedIndex = response?.spot?.touchedBarGroupIndex;
          }),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              getTitlesWidget: (val, meta) {
                final idx = val.toInt();
                if (idx < 0 || idx >= top.length) return const SizedBox();
                final code = top[idx];
                return Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: RotatedBox(
                    quarterTurns: 1,
                    child: Text(
                      code.length > 10 ? '${code.substring(0, 9)}…' : code,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (val, meta) => Text(
                val >= 1000
                    ? '${(val / 1000).toStringAsFixed(1)}t'
                    : val.toStringAsFixed(0),
                style: const TextStyle(fontSize: 10, color: Colors.black38),
              ),
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) =>
              FlLine(color: Colors.grey.shade100, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(top.length, (i) {
          final code = top[i];
          final val = totals[code] ?? 0;
          final isTouched = _touchedIndex == i;
          final color = _kChartColors[i % _kChartColors.length];
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: val,
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(isTouched ? 1.0 : 0.88),
                    color.withOpacity(isTouched ? 0.65 : 0.50),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                width: top.length > 8 ? 18 : 26,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
