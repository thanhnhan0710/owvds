import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:owvds/features/hr/work_schedule/presentation/dialogs/schedule_dialog_helper.dart';
import 'package:owvds/features/hr/work_schedule/shift/domain/shift_model.dart';
import 'package:owvds/features/hr/work_schedule/shift/presentation/bloc/shift_cubit.dart';

import '../../../../../core/widgets/responsive_layout.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/network/websocket_service.dart';
import '../../../work_schedule/domain/work_schedule_model.dart';
import '../../../work_schedule/presentation/bloc/work_schedule_cubit.dart';

import '../../../employee/presentation/bloc/employee_cubit.dart';

class WorkScheduleScreen extends StatefulWidget {
  const WorkScheduleScreen({super.key});

  @override
  State<WorkScheduleScreen> createState() => _WorkScheduleScreenState();
}

class _WorkScheduleScreenState extends State<WorkScheduleScreen>
    with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  final Color _primaryColor = const Color(0xFF003366);
  Timer? _debounce;
  DateTime _currentDate = DateTime.now();
  late TabController _dayTabController;

  int? _selectedShiftId;

  @override
  void initState() {
    super.initState();
    _dayTabController = TabController(
      length: 7,
      vsync: this,
      initialIndex: DateTime.now().weekday - 1,
    );

    // Tải tất cả dữ liệu nền
    context.read<WorkScheduleCubit>().loadSchedules();
    context.read<EmployeeCubit>().loadPage(1);
    context.read<ShiftCubit>().loadShifts();

    WebSocketService().addListener(_onWebSocketMessage);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _dayTabController.dispose();
    WebSocketService().removeListener(_onWebSocketMessage);
    super.dispose();
  }

  void _onWebSocketMessage(String message) {
    if (message == "REFRESH_WORK_SCHEDULES" && mounted) {
      context.read<WorkScheduleCubit>().loadSchedules();
    }
  }

  // --- LOGIC TÍNH TOÁN NGÀY & TUẦN ---
  DateTime _startOfWeek(DateTime date) =>
      date.subtract(Duration(days: date.weekday - 1));
  DateTime _endOfWeek(DateTime date) =>
      date.add(Duration(days: DateTime.daysPerWeek - date.weekday));

  void _changeWeek(int offset) {
    setState(() {
      _currentDate = _currentDate.add(Duration(days: offset * 7));
    });
  }

  List<DateTime> _getDaysInWeek() {
    DateTime start = _startOfWeek(_currentDate);
    return List.generate(7, (index) => start.add(Duration(days: index)));
  }

  int _getWeekNumber(DateTime date) {
    int dayOfYear = int.parse(DateFormat("D").format(date));
    int woy = ((dayOfYear - date.weekday + 10) / 7).floor();
    if (woy < 1) {
      woy = _getWeekNumber(DateTime(date.year - 1, 12, 31));
    } else if (woy == 53) {
      DateTime dec31 = DateTime(date.year, 12, 31);
      if (dec31.weekday != DateTime.thursday &&
          (dec31.weekday != DateTime.friday || dec31.year % 4 != 0))
        woy = 1;
    }
    return woy;
  }

  List<WorkSchedule> _filterByWeek(List<WorkSchedule> allSchedules) {
    final startRange = DateTime(
      _startOfWeek(_currentDate).year,
      _startOfWeek(_currentDate).month,
      _startOfWeek(_currentDate).day,
    );
    final endRange = DateTime(
      _endOfWeek(_currentDate).year,
      _endOfWeek(_currentDate).month,
      _endOfWeek(_currentDate).day,
      23,
      59,
      59,
    );

    var filtered = allSchedules.where((s) {
      try {
        final date = DateFormat('yyyy-MM-dd').parse(s.workDate);
        return date.isAfter(startRange.subtract(const Duration(seconds: 1))) &&
            date.isBefore(endRange.add(const Duration(seconds: 1)));
      } catch (_) {
        return false;
      }
    }).toList();

    if (_selectedShiftId != null) {
      filtered = filtered.where((s) => s.shiftId == _selectedShiftId).toList();
    }
    return filtered;
  }

  List<WorkSchedule> _filterByDate(
    List<WorkSchedule> weekSchedules,
    DateTime date,
  ) {
    String dateStr = DateFormat('yyyy-MM-dd').format(date);
    return weekSchedules.where((s) => s.workDate == dateStr).toList();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().isEmpty) {
        context.read<WorkScheduleCubit>().loadSchedules();
      } else {
        context.read<WorkScheduleCubit>().searchSchedules(query);
      }
    });
  }

  Color _getShiftColor(String shiftName) {
    String lowerName = shiftName.toLowerCase();
    if (lowerName.contains('sáng') || lowerName.contains('a'))
      return Colors.orange.shade600;
    if (lowerName.contains('chiều') || lowerName.contains('b'))
      return Colors.blue.shade600;
    if (lowerName.contains('đêm') || lowerName.contains('c'))
      return Colors.indigo.shade600;
    if (lowerName.contains('hành chính')) return Colors.teal.shade600;
    return Colors.blueGrey;
  }

  IconData _getShiftIcon(String shiftName) {
    String lowerName = shiftName.toLowerCase();
    if (lowerName.contains('sáng') || lowerName.contains('a'))
      return Icons.wb_sunny;
    if (lowerName.contains('chiều') || lowerName.contains('b'))
      return Icons.wb_cloudy;
    if (lowerName.contains('đêm') || lowerName.contains('c'))
      return Icons.nights_stay;
    if (lowerName.contains('hành chính')) return Icons.business_center;
    return Icons.access_time_filled;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final weekDays = _getDaysInWeek();
    final weekNumber = _getWeekNumber(_currentDate);

    return BlocListener<WorkScheduleCubit, WorkScheduleState>(
      listener: (context, state) {
        if (state is WorkScheduleError) {
          String msg = state.message.contains("DUPLICATE_SCHEDULE")
              ? l10n.errorDuplicateSchedule
              : state.message.replaceAll("Exception: ", "");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: Colors.red),
          );
          context.read<WorkScheduleCubit>().loadSchedules();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: isDesktop
            ? null
            : AppBar(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                title: const Text(
                  "Lịch Làm Việc",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
        floatingActionButton: !isDesktop
            ? FloatingActionButton(
                backgroundColor: const Color(0xFF1976D2),
                onPressed: () => ScheduleDialogHelper.showQuickScheduleDialog(
                  context,
                  l10n,
                  _currentDate,
                ),
                child: const Icon(Icons.add, color: Colors.white),
              )
            : null,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SIDEBAR QUẢN LÝ CA ---
            if (isDesktop) _buildShiftSidebar(l10n),

            // --- NỘI DUNG CHÍNH (BẢNG LỊCH TUẦN) ---
            Expanded(
              child: BlocBuilder<WorkScheduleCubit, WorkScheduleState>(
                builder: (context, state) {
                  List<WorkSchedule> weeklySchedules =
                      (state is WorkScheduleLoaded)
                      ? _filterByWeek(state.schedules)
                      : [];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // HEADER: TUẦN & TÌM KIẾM
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.calendar_month,
                                color: Colors.blue.shade800,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Lịch Phân Công",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                  Text(
                                    "Tuần $weekNumber • Năm ${_currentDate.year}",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isDesktop) ...[
                              _buildDateNavigator(isFullWidth: false),
                              const SizedBox(width: 12),
                              Container(
                                width: 220,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F7FA),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: _onSearchChanged,
                                  decoration: const InputDecoration(
                                    hintText: "Tìm nhân viên...",
                                    prefixIcon: Icon(Icons.search, size: 18),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: () =>
                                    ScheduleDialogHelper.showQuickScheduleDialog(
                                      context,
                                      l10n,
                                      _currentDate,
                                    ),
                                icon: const Icon(Icons.add_task, size: 16),
                                label: const Text("XẾP LỊCH"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (!isDesktop) ...[
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: _buildDateNavigator(isFullWidth: true),
                        ),
                        Container(height: 1, color: Colors.grey.shade200),
                      ],

                      // THANH TAB CÁC NGÀY TRONG TUẦN
                      Container(
                        color: Colors.white,
                        child: TabBar(
                          controller: _dayTabController,
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          labelColor: _primaryColor,
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: _primaryColor,
                          indicatorWeight: 3,
                          labelPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          tabs: weekDays.map((day) {
                            int count = _filterByDate(
                              weeklySchedules,
                              day,
                            ).length;
                            String shortDay = DateFormat('EEEE', 'vi')
                                .format(day)
                                .replaceFirst("Thứ ", "T")
                                .replaceFirst("Chủ Nhật", "CN");
                            return Tab(
                              height: 56,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    shortDay,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        DateFormat('dd/MM').format(day),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: count > 0
                                              ? Colors.blue.shade100
                                              : Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          "$count",
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: count > 0
                                                ? Colors.blue.shade900
                                                : Colors.grey,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      Container(height: 1, color: Colors.grey.shade300),

                      // NỘI DUNG LỊCH THEO NGÀY (GOM THEO CA LÀM VIỆC)
                      Expanded(
                        child: (state is WorkScheduleLoading)
                            ? Center(
                                child: CircularProgressIndicator(
                                  color: _primaryColor,
                                ),
                              )
                            : TabBarView(
                                controller: _dayTabController,
                                children: weekDays.map((day) {
                                  List<WorkSchedule> dailyList = _filterByDate(
                                    weeklySchedules,
                                    day,
                                  );

                                  if (dailyList.isEmpty)
                                    return _buildEmptyDay(day, l10n);

                                  return _buildDailyShiftView(
                                    context,
                                    dailyList,
                                    l10n,
                                  );
                                }).toList(),
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- SIDEBAR QUẢN LÝ CA LÀM VIỆC ---
  Widget _buildShiftSidebar(AppLocalizations l10n) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Các Ca Làm Việc",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF003366),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: Colors.blue,
                  ),
                  tooltip: "Thêm Ca mới",
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => ScheduleDialogHelper.showShiftEditDialog(
                    context,
                    null,
                    l10n,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: Colors.grey.shade200),
          Expanded(
            child: BlocBuilder<ShiftCubit, ShiftState>(
              builder: (context, state) {
                if (state is ShiftLoading)
                  return const Center(child: CircularProgressIndicator());
                if (state is ShiftLoaded) {
                  List<Shift> allShifts = List.from(state.shifts);
                  allShifts.sort((a, b) => a.id.compareTo(b.id));

                  return ListView(
                    children: [
                      _buildSidebarItem(
                        title: "Tất cả các ca",
                        icon: Icons.all_inclusive,
                        color: Colors.blueGrey,
                        isSelected: _selectedShiftId == null,
                        onTap: () => setState(() => _selectedShiftId = null),
                      ),
                      const Divider(height: 1),
                      ...allShifts.map((shift) {
                        final isSelected = _selectedShiftId == shift.id;
                        final color = _getShiftColor(shift.name);
                        final icon = _getShiftIcon(shift.name);
                        final timeRange = shift.note.isNotEmpty
                            ? shift.note
                            : "Chưa có ghi chú";

                        return _buildSidebarItem(
                          title: shift.name,
                          subtitle: timeRange,
                          icon: icon,
                          color: color,
                          isSelected: isSelected,
                          onTap: () =>
                              setState(() => _selectedShiftId = shift.id),
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert,
                              size: 18,
                              color: Colors.grey,
                            ),
                            padding: EdgeInsets.zero,
                            onSelected: (val) {
                              if (val == 'edit')
                                ScheduleDialogHelper.showShiftEditDialog(
                                  context,
                                  shift,
                                  l10n,
                                );
                              if (val == 'delete')
                                ScheduleDialogHelper.confirmDeleteShift(
                                  context,
                                  shift,
                                  l10n,
                                );
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text("Sửa thông tin ca"),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text(
                                  "Xóa ca này",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
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

  Widget _buildSidebarItem({
    required String title,
    String? subtitle,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? color : Colors.transparent,
              width: 4,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected ? color : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }

  // --- GIAO DIỆN NHÓM THEO CA ---
  Widget _buildDailyShiftView(
    BuildContext context,
    List<WorkSchedule> dailySchedules,
    AppLocalizations l10n,
  ) {
    return BlocBuilder<ShiftCubit, ShiftState>(
      builder: (context, shiftState) {
        if (shiftState is! ShiftLoaded)
          return const Center(child: CircularProgressIndicator());

        List<Shift> allShifts = List.from(shiftState.shifts);
        allShifts.sort((a, b) => a.id.compareTo(b.id));

        Map<int, List<WorkSchedule>> groupedSchedules = {};
        for (var s in dailySchedules) {
          groupedSchedules.putIfAbsent(s.shiftId, () => []).add(s);
        }

        if (_selectedShiftId != null) {
          allShifts = allShifts.where((s) => s.id == _selectedShiftId).toList();
        }

        return Column(
          children: [
            // HIỂN THỊ TỔNG SỐ LỊCH Ở TRÊN CÙNG
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              color: Colors.amber.shade50,
              width: double.infinity,
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Colors.orange.shade900,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Tổng cộng: ${dailySchedules.length} lịch làm việc được phân công trong ngày.",
                    style: TextStyle(
                      color: Colors.orange.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: allShifts.length,
                itemBuilder: (context, index) {
                  final shift = allShifts[index];
                  final schedulesInShift = groupedSchedules[shift.id] ?? [];

                  if (schedulesInShift.isEmpty && _selectedShiftId == null)
                    return const SizedBox();

                  Color shiftColor = _getShiftColor(shift.name);
                  IconData shiftIcon = _getShiftIcon(shift.name);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // HEADER CA LÀM VIỆC
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: shiftColor.withOpacity(0.1),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            border: Border(
                              bottom: BorderSide(
                                color: shiftColor.withOpacity(0.2),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(shiftIcon, color: shiftColor),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      shift.name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: shiftColor,
                                      ),
                                    ),
                                    if (shift.note.isNotEmpty)
                                      Text(
                                        shift.note,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: shiftColor.withOpacity(0.8),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: shiftColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "${schedulesInShift.length} Nhân sự",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // DANH SÁCH NHÂN VIÊN TRONG CA
                        if (schedulesInShift.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Center(
                              child: Text(
                                "Ca này chưa phân công ai.",
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: schedulesInShift
                                  .map(
                                    (schedule) => _buildEmployeeChip(
                                      context,
                                      schedule,
                                      l10n,
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // WIDGET THẺ NHÂN VIÊN (HIỂN THỊ RÕ NÚT SỬA VÀ XÓA)
  Widget _buildEmployeeChip(
    BuildContext context,
    WorkSchedule schedule,
    AppLocalizations l10n,
  ) {
    return BlocBuilder<EmployeeCubit, EmployeeState>(
      builder: (context, state) {
        String empName = "Đang tải...";
        String position = "";

        if (state is EmployeeLoaded) {
          final emp = state.employees
              .where((e) => e.id == schedule.employeeId)
              .firstOrNull;
          if (emp != null) {
            empName = emp.fullName;
            position = emp.position;
          }
        }

        return Container(
          width: 300, // Tăng width để đủ không gian cho 2 nút bấm
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _primaryColor.withOpacity(0.1),
                child: Text(
                  empName.isNotEmpty ? empName[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: _primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      empName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      position.isNotEmpty ? position : 'Nhân viên',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // CỤM NÚT SỬA & XÓA CỦA RIÊNG TỪNG LỊCH NHÂN VIÊN
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () =>
                        ScheduleDialogHelper.showSingleScheduleEditDialog(
                          context,
                          schedule,
                          l10n,
                        ),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.edit_outlined,
                        color: Colors.blue,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => ScheduleDialogHelper.confirmDeleteSchedule(
                      context,
                      schedule,
                      l10n,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                        size: 18,
                      ),
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

  Widget _buildEmptyDay(DateTime day, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "Không có lịch làm việc ngày ${DateFormat('dd/MM').format(day)}",
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => ScheduleDialogHelper.showQuickScheduleDialog(
              context,
              l10n,
              _currentDate,
            ),
            icon: const Icon(Icons.add),
            label: const Text("Xếp lịch"),
          ),
        ],
      ),
    );
  }

  Widget _buildDateNavigator({required bool isFullWidth}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _changeWeek(-1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.date_range, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  "${DateFormat('dd/MM').format(_startOfWeek(_currentDate))} - ${DateFormat('dd/MM/yyyy').format(_endOfWeek(_currentDate))}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _changeWeek(1),
          ),
        ],
      ),
    );
  }
}
