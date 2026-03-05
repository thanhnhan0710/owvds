import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:owvds/features/hr/work_schedule/shift/domain/shift_model.dart';
import 'package:owvds/features/hr/work_schedule/shift/presentation/bloc/shift_cubit.dart';

import '../../../../../core/widgets/responsive_layout.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../work_schedule/domain/work_schedule_model.dart';
import '../../../work_schedule/presentation/bloc/work_schedule_cubit.dart';
import '../../../employee/domain/employee_model.dart';
import '../../../employee/presentation/bloc/employee_cubit.dart';
import '../../../employee_group/domain/employee_group_model.dart';
import '../../../employee_group/presentation/bloc/employee_group_cubit.dart';
import '../utils/schedule_dialog_helper.dart';

class DailyScheduleView extends StatefulWidget {
  final int? selectedShiftId;
  final bool showOnlyOvertime;

  const DailyScheduleView({
    super.key,
    required this.selectedShiftId,
    required this.showOnlyOvertime,
  });

  @override
  State<DailyScheduleView> createState() => _DailyScheduleViewState();
}

class _DailyScheduleViewState extends State<DailyScheduleView>
    with TickerProviderStateMixin {
  final Color _primaryColor = const Color(0xFF003366);
  DateTime _currentDate = DateTime.now();
  late TabController _dayTabController;

  @override
  void initState() {
    super.initState();
    _dayTabController = TabController(
      length: 7,
      vsync: this,
      initialIndex: DateTime.now().weekday - 1,
    );
  }

  @override
  void dispose() {
    _dayTabController.dispose();
    super.dispose();
  }

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
    if (woy < 1) return _getWeekNumber(DateTime(date.year - 1, 12, 31));
    return woy;
  }

  List<WorkSchedule> _filterSchedules(List<WorkSchedule> all, DateTime date) {
    String dateStr = DateFormat('yyyy-MM-dd').format(date);
    var filtered = all.where((s) => s.workDate == dateStr).toList();

    if (widget.selectedShiftId != null) {
      filtered = filtered
          .where((s) => s.shiftId == widget.selectedShiftId)
          .toList();
    }
    if (widget.showOnlyOvertime) {
      filtered = filtered.where((s) => s.overtimeHours > 0).toList();
    }
    return filtered;
  }

  Color _getShiftColor(String shiftName) {
    String lower = shiftName.toLowerCase();
    if (lower.contains('sáng') || lower.contains('a')) {
      return Colors.orange.shade600;
    }
    if (lower.contains('chiều') || lower.contains('b')) {
      return Colors.blue.shade600;
    }
    if (lower.contains('đêm') || lower.contains('c')) {
      return Colors.indigo.shade600;
    }
    if (lower.contains('hành chính')) return Colors.teal.shade600;
    return Colors.blueGrey;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final weekDays = _getDaysInWeek();

    return BlocBuilder<WorkScheduleCubit, WorkScheduleState>(
      builder: (context, scheduleState) {
        List<WorkSchedule> allWeeklySchedules =
            (scheduleState is WorkScheduleLoaded)
            ? scheduleState.schedules
            : [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- HEADER BAR ĐÃ SỬA LỖI TRÀN MÀN HÌNH ---
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.calendar_view_week,
                      color: Colors.blue.shade800,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Phần tiêu đề (Bọc trong Expanded)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.showOnlyOvertime
                              ? "Danh Sách Tăng Ca"
                              : "Lịch Phân Công",
                          style: TextStyle(
                            fontSize: 18, // Giảm nhẹ fontSize để tiết kiệm chỗ
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "Tuần ${_getWeekNumber(_currentDate)} • Năm ${_currentDate.year}",
                          style: TextStyle(
                            fontSize: 13,
                            color: _primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Cụm Nút bấm (Sử dụng Wrap để tự rớt dòng nếu thiếu chỗ)
                  if (isDesktop) ...[
                    const SizedBox(width: 12),
                    Wrap(
                      spacing: 8, // Khoảng cách ngang giữa các nút
                      runSpacing: 8, // Khoảng cách dọc nếu rớt dòng
                      crossAxisAlignment: WrapCrossAlignment.center,
                      alignment: WrapAlignment.end,
                      children: [
                        _buildDateNavigator(isFullWidth: false),
                        ElevatedButton.icon(
                          onPressed: () =>
                              ScheduleDialogHelper.showAddOvertimeDialog(
                                context,
                                _currentDate,
                              ),
                          icon: const Icon(Icons.more_time, size: 16),
                          label: const Text("TĂNG CA"), // Làm ngắn text lại
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () =>
                              ScheduleDialogHelper.showQuickScheduleDialog(
                                context,
                                l10n,
                                _currentDate,
                              ),
                          icon: const Icon(Icons.calendar_month, size: 16),
                          label: const Text("XẾP CA"), // Làm ngắn text lại
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ],
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
                labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                tabs: weekDays.map((day) {
                  int count = _filterSchedules(allWeeklySchedules, day).length;
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
                                    ? (widget.showOnlyOvertime
                                          ? Colors.orange.shade100
                                          : Colors.blue.shade100)
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                "$count",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: count > 0
                                      ? (widget.showOnlyOvertime
                                            ? Colors.orange.shade900
                                            : Colors.blue.shade900)
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

            // NỘI DUNG CHÍNH DƯỚI TAB
            Expanded(
              child: (scheduleState is WorkScheduleLoading)
                  ? Center(
                      child: CircularProgressIndicator(color: _primaryColor),
                    )
                  : TabBarView(
                      controller: _dayTabController,
                      children: weekDays.map((day) {
                        List<WorkSchedule> dailyList = _filterSchedules(
                          allWeeklySchedules,
                          day,
                        );
                        if (dailyList.isEmpty) {
                          return _buildEmptyState(day, l10n);
                        }

                        return _buildGroupedScheduleView(dailyList, l10n);
                      }).toList(),
                    ),
            ),
          ],
        );
      },
    );
  }

  // --- LOGIC NHÓM HAI CẤP: CA (SHIFT) -> TỔ (GROUP) ---
  Widget _buildGroupedScheduleView(
    List<WorkSchedule> dailySchedules,
    AppLocalizations l10n,
  ) {
    return BlocBuilder<EmployeeCubit, EmployeeState>(
      builder: (context, empState) {
        List<Employee> allEmployees = (empState is EmployeeLoaded)
            ? empState.employees
            : [];

        return BlocBuilder<ShiftCubit, ShiftState>(
          builder: (context, shiftState) {
            List<Shift> allShifts = (shiftState is ShiftLoaded)
                ? shiftState.shifts
                : [];
            allShifts.sort((a, b) => a.id.compareTo(b.id));

            return BlocBuilder<EmployeeGroupCubit, EmployeeGroupState>(
              builder: (context, groupState) {
                List<EmployeeGroup> allGroups =
                    (groupState is EmployeeGroupLoaded)
                    ? groupState.groups
                    : [];

                Map<int, int?> empToGroupMap = {
                  for (var e in allEmployees) e.id: e.groupId,
                };

                Map<int, String> groupNames = {
                  for (var g in allGroups) g.id: g.name,
                };

                return ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: allShifts.length,
                  itemBuilder: (context, sIndex) {
                    final shift = allShifts[sIndex];

                    final schedulesInShift = dailySchedules
                        .where((s) => s.shiftId == shift.id)
                        .toList();
                    if (schedulesInShift.isEmpty) return const SizedBox();

                    Map<int?, List<WorkSchedule>> groupedByGroup = {};
                    for (var s in schedulesInShift) {
                      int? gId = empToGroupMap[s.employeeId];
                      groupedByGroup.putIfAbsent(gId, () => []).add(s);
                    }

                    Color shiftColor = _getShiftColor(shift.name);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 32),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300, width: 2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: shiftColor.withOpacity(0.15),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(10),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  shift.name.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: shiftColor,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                Text(
                                  "${schedulesInShift.length} nhân sự",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: shiftColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...groupedByGroup.entries.map((entry) {
                            int? gId = entry.key;
                            List<WorkSchedule> gSchedules = entry.value;
                            String gName = gId == null
                                ? "Nhân sự không thuộc Tổ"
                                : (groupNames[gId] ?? "Tổ không xác định");

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    16,
                                    16,
                                    8,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.people_outline,
                                        size: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        gName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade800,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        "${gSchedules.length} người",
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: gSchedules
                                        .map(
                                          (s) => _buildEmployeeCard(
                                            context,
                                            s,
                                            allEmployees,
                                            l10n,
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                                const Divider(),
                              ],
                            );
                          }),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  // --- THẺ NHÂN VIÊN VỚI THÔNG TIN TĂNG CA ---
  Widget _buildEmployeeCard(
    BuildContext context,
    WorkSchedule schedule,
    List<Employee> allEmployees,
    AppLocalizations l10n,
  ) {
    final emp = allEmployees
        .where((e) => e.id == schedule.employeeId)
        .firstOrNull;
    String empName = emp?.fullName ?? "Unknown";
    String position = emp?.position ?? "Nhân viên";

    bool hasOt = schedule.overtimeHours > 0;

    return Container(
      width: 260,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasOt ? Colors.orange.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasOt ? Colors.orange.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: hasOt
                ? Colors.orange.shade200
                : _primaryColor.withOpacity(0.1),
            child: Text(
              empName[0].toUpperCase(),
              style: TextStyle(
                color: hasOt ? Colors.orange.shade900 : _primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        empName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Text(
                  position,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (hasOt)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade600,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "+${schedule.overtimeHours}h Tăng ca",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Column(
            children: [
              InkWell(
                onTap: () => ScheduleDialogHelper.showSingleScheduleEditDialog(
                  context,
                  schedule,
                  l10n,
                ),
                child: const Icon(Icons.edit, color: Colors.blue, size: 16),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => ScheduleDialogHelper.confirmDeleteSchedule(
                  context,
                  schedule,
                  l10n,
                ),
                child: const Icon(Icons.delete, color: Colors.red, size: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(DateTime day, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            widget.showOnlyOvertime
                ? "Không có ai tăng ca ngày ${DateFormat('dd/MM').format(day)}"
                : "Chưa xếp lịch ngày ${DateFormat('dd/MM').format(day)}",
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 12),
          if (!widget.showOnlyOvertime)
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
