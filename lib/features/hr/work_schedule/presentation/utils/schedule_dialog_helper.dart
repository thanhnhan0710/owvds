import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:owvds/features/hr/work_schedule/shift/domain/shift_model.dart';
import 'package:owvds/features/hr/work_schedule/shift/presentation/bloc/shift_cubit.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../work_schedule/domain/work_schedule_model.dart';
import '../../../work_schedule/presentation/bloc/work_schedule_cubit.dart';
import '../../../employee/domain/employee_model.dart';
import '../../../employee/presentation/bloc/employee_cubit.dart';

class ScheduleDialogHelper {
  static final Color _primaryColor = const Color(0xFF003366);

  static InputDecoration _inputDeco(
    String label, {
    IconData? icon,
  }) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.grey.shade50,
    prefixIcon: icon != null ? Icon(icon, size: 18, color: Colors.grey) : null,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  static String? _validateOvertime(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    double? ot = double.tryParse(value);
    if (ot == null) return "Số không hợp lệ";
    if (ot < 0) return "Không được âm";
    if (ot > 12) return "Tối đa 12h/ngày";
    return null;
  }

  static void _syncWeekdaysWithDateRange(
    DateTime start,
    DateTime end,
    Set<int> selectedWeekdays,
  ) {
    selectedWeekdays.clear();
    int daysDiff = end.difference(start).inDays;

    if (daysDiff >= 6) {
      selectedWeekdays.addAll([1, 2, 3, 4, 5, 6]);
    } else {
      for (int i = 0; i <= daysDiff; i++) {
        selectedWeekdays.add(start.add(Duration(days: i)).weekday);
      }
    }
  }

  static DateTime _calcEndDateBasedOnWeekdays(
    DateTime start,
    Set<int> weekdays,
  ) {
    if (weekdays.isEmpty) return start;
    DateTime maxDate = start;
    for (int wd in weekdays) {
      int daysToAdd = wd - start.weekday;
      if (daysToAdd < 0) daysToAdd += 7;
      DateTime targetDate = start.add(Duration(days: daysToAdd));
      if (targetDate.isAfter(maxDate)) {
        maxDate = targetDate;
      }
    }
    return maxDate;
  }

  // ==========================================
  // DIALOGS CHO CA LÀM VIỆC (SHIFT)
  // ==========================================
  static void showShiftEditDialog(
    BuildContext context,
    Shift? item,
    AppLocalizations l10n,
  ) {
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final noteCtrl = TextEditingController(text: item?.note ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.all(24),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        title: Text(
          item == null ? "Thêm Ca Làm Việc" : "Sửa Ca Làm Việc",
          style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: _inputDeco(
                      "Tên Ca (VD: Ca A, Ca B, Hành chính) *",
                    ),
                    validator: (v) => v!.isEmpty ? "Bắt buộc" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: noteCtrl,
                    decoration: _inputDeco("Ghi chú (VD: 06:00 - 14:00)"),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.all(24),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l10n.cancel,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final newItem = Shift(
                  id: item?.id ?? 0,
                  name: nameCtrl.text,
                  note: noteCtrl.text,
                );
                context.read<ShiftCubit>().saveShift(
                  shift: newItem,
                  isEdit: item != null,
                );
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  static void confirmDeleteShift(
    BuildContext context,
    Shift item,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Text(l10n.deleteShift),
          ],
        ),
        content: Text(l10n.confirmDeleteShift(item.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<ShiftCubit>().deleteShift(item.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.deleteShift),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // DIALOGS CHO XẾP LỊCH & TĂNG CA HÀNG LOẠT
  // ==========================================

  // 1. Xếp lịch ca nhanh (Hàng loạt Nhân viên + Hàng loạt Ngày)
  static void showQuickScheduleDialog(
    BuildContext context,
    AppLocalizations l10n,
    DateTime currentDate,
  ) {
    DateTime startOfWeek(DateTime date) =>
        date.subtract(Duration(days: date.weekday - 1));
    DateTime endOfWeek(DateTime date) =>
        date.add(Duration(days: DateTime.daysPerWeek - date.weekday));

    DateTime startDate = startOfWeek(currentDate);
    DateTime endDate = endOfWeek(currentDate);

    int? selectedShiftId;
    Set<int> selectedWeekdays = {1, 2, 3, 4, 5, 6};
    Set<int> selectedEmpIds = {};
    String empSearchQuery = "";

    final otCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final employeeCubit = context.read<EmployeeCubit>();
    final shiftCubit = context.read<ShiftCubit>();
    final scheduleCubit = context.read<WorkScheduleCubit>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: employeeCubit),
          BlocProvider.value(value: shiftCubit),
        ],
        child: StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              titlePadding: const EdgeInsets.all(24),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.calendar_month, color: _primaryColor),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Xếp Ca Hàng Loạt",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Form(
                key: formKey,
                child: SizedBox(
                  width: 600,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "1. Cấu hình Ca & Thời gian",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: BlocBuilder<ShiftCubit, ShiftState>(
                                builder: (context, state) {
                                  List<Shift> list = (state is ShiftLoaded)
                                      ? state.shifts
                                      : [];
                                  return DropdownButtonFormField<int>(
                                    value: selectedShiftId,
                                    decoration: _inputDeco(
                                      "Ca làm việc (8 Tiếng)",
                                    ),
                                    isExpanded: true,
                                    items: list
                                        .map(
                                          (s) => DropdownMenuItem(
                                            value: s.id,
                                            child: Text(s.name),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (val) => selectedShiftId = val,
                                    validator: (v) =>
                                        v == null ? "Bắt buộc" : null,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: otCtrl,
                                decoration: _inputDeco("Tăng ca (Giờ)"),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                validator: _validateOvertime,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () async {
                            final picked = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                              initialDateRange: DateTimeRange(
                                start: startDate,
                                end: endDate,
                              ),
                            );
                            if (picked != null) {
                              setStateDialog(() {
                                startDate = picked.start;
                                endDate = picked.end;
                                _syncWeekdaysWithDateRange(
                                  startDate,
                                  endDate,
                                  selectedWeekdays,
                                );
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: _inputDeco(
                              "Áp dụng từ ngày - đến ngày",
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${DateFormat('dd/MM/yyyy').format(startDate)}  -  ${DateFormat('dd/MM/yyyy').format(endDate)}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Icon(
                                  Icons.date_range,
                                  color: Colors.blue,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            for (int i = 1; i <= 7; i++)
                              FilterChip(
                                label: Text(
                                  i == 7 ? "CN" : "T${i + 1}",
                                  style: const TextStyle(fontSize: 12),
                                ),
                                selected: selectedWeekdays.contains(i),
                                onSelected: (_) => setStateDialog(() {
                                  if (selectedWeekdays.contains(i)) {
                                    selectedWeekdays.remove(i);
                                  } else {
                                    selectedWeekdays.add(i);
                                  }
                                  if (selectedWeekdays.isNotEmpty) {
                                    endDate = _calcEndDateBasedOnWeekdays(
                                      startDate,
                                      selectedWeekdays,
                                    );
                                  } else {
                                    endDate = startDate;
                                  }
                                }),
                                selectedColor: i == 7
                                    ? Colors.red.shade100
                                    : Colors.blue.shade100,
                                checkmarkColor: i == 7
                                    ? Colors.red
                                    : Colors.blue,
                                padding: EdgeInsets.zero,
                              ),
                          ],
                        ),
                        const Divider(height: 32),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "2. Chọn Nhân Viên",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              "Đã chọn: ${selectedEmpIds.length}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          onChanged: (val) => setStateDialog(
                            () => empSearchQuery = val.toLowerCase(),
                          ),
                          decoration:
                              _inputDeco(
                                "Tìm tên, chức vụ...",
                                icon: Icons.search,
                              ).copyWith(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                        ),
                        const SizedBox(height: 8),

                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: BlocBuilder<EmployeeCubit, EmployeeState>(
                            builder: (context, state) {
                              if (state is! EmployeeLoaded)
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );

                              List<Employee> displayList = state.employees
                                  .where((e) {
                                    return e.fullName.toLowerCase().contains(
                                          empSearchQuery,
                                        ) ||
                                        (e.position).toLowerCase().contains(
                                          empSearchQuery,
                                        );
                                  })
                                  .toList();

                              if (displayList.isEmpty)
                                return const Center(
                                  child: Text("Không tìm thấy nhân viên"),
                                );

                              bool isAllSelected =
                                  displayList.isNotEmpty &&
                                  displayList.every(
                                    (e) => selectedEmpIds.contains(e.id),
                                  );

                              return Column(
                                children: [
                                  CheckboxListTile(
                                    title: const Text(
                                      "Chọn tất cả danh sách dưới",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    value: isAllSelected,
                                    onChanged: (val) {
                                      setStateDialog(() {
                                        if (val == true) {
                                          selectedEmpIds.addAll(
                                            displayList.map((e) => e.id),
                                          );
                                        } else {
                                          selectedEmpIds.removeAll(
                                            displayList.map((e) => e.id),
                                          );
                                        }
                                      });
                                    },
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    tileColor: Colors.blue.shade50,
                                    dense: true,
                                  ),
                                  const Divider(height: 1),
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: displayList.length,
                                      itemBuilder: (ctx, index) {
                                        final emp = displayList[index];
                                        return CheckboxListTile(
                                          title: Text(
                                            emp.fullName,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          subtitle: Text(
                                            emp.position,
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                          value: selectedEmpIds.contains(
                                            emp.id,
                                          ),
                                          onChanged: (val) {
                                            setStateDialog(() {
                                              if (val == true) {
                                                selectedEmpIds.add(emp.id);
                                              } else {
                                                selectedEmpIds.remove(emp.id);
                                              }
                                            });
                                          },
                                          controlAffinity:
                                              ListTileControlAffinity.leading,
                                          dense: true,
                                        );
                                      },
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
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    "Hủy",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text("XẾP CA"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () {
                    if (formKey.currentState!.validate() &&
                        selectedShiftId != null) {
                      if (selectedWeekdays.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Vui lòng chọn ít nhất 1 thứ!"),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }
                      if (selectedEmpIds.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Vui lòng chọn ít nhất 1 nhân viên!"),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      final scheduleState = scheduleCubit.state;
                      if (scheduleState is WorkScheduleLoaded) {
                        Navigator.pop(ctx);
                        double parsedOt = double.tryParse(otCtrl.text) ?? 0.0;

                        // Tính trước tổng Tăng ca hiện tại của từng nhân viên trong tháng
                        Map<String, double> monthlyOtMap = {};
                        for (var s in scheduleState.schedules) {
                          try {
                            DateTime d = DateTime.parse(s.workDate);
                            String key = "${s.employeeId}_${d.year}_${d.month}";
                            monthlyOtMap[key] =
                                (monthlyOtMap[key] ?? 0.0) + s.overtimeHours;
                          } catch (_) {}
                        }

                        int countNew = 0;
                        int skipConflictCount = 0;
                        int skipOtCount = 0;

                        for (
                          int i = 0;
                          i <= endDate.difference(startDate).inDays;
                          i++
                        ) {
                          DateTime day = startDate.add(Duration(days: i));
                          if (selectedWeekdays.contains(day.weekday)) {
                            String targetDateStr = DateFormat(
                              'yyyy-MM-dd',
                            ).format(day);
                            String monthKey = "${day.year}_${day.month}";

                            for (int empId in selectedEmpIds) {
                              // [MỚI] Tránh Lỗi 409 Conflict: Quét xem ngày đó đã có lịch chưa
                              bool exists = scheduleState.schedules.any(
                                (s) =>
                                    s.employeeId == empId &&
                                    s.workDate == targetDateStr,
                              );
                              if (exists) {
                                skipConflictCount++;
                                continue;
                              }

                              // [MỚI] Tránh Lỗi 400 Bad Request: Quét xem có vượt quá 40h/tháng không
                              String empMonthKey = "${empId}_$monthKey";
                              double currentOt =
                                  monthlyOtMap[empMonthKey] ?? 0.0;
                              if (currentOt + parsedOt > 40.0) {
                                skipOtCount++;
                                continue;
                              }

                              // Cập nhật lại số tính toán tạm thời để vòng lặp kế tiếp có số đúng
                              monthlyOtMap[empMonthKey] = currentOt + parsedOt;

                              final newItem = WorkSchedule(
                                id: 0,
                                workDate: targetDateStr,
                                employeeId: empId,
                                shiftId: selectedShiftId!,
                                overtimeHours: parsedOt,
                              );
                              scheduleCubit.saveSchedule(
                                schedule: newItem,
                                isEdit: false,
                              );
                              countNew++;
                            }
                          }
                        }

                        String msg = "Thành công: Đã tạo $countNew lịch mới.";
                        if (skipConflictCount > 0)
                          msg +=
                              " Bỏ qua $skipConflictCount lượt do đã có lịch.";
                        if (skipOtCount > 0)
                          msg +=
                              " Bỏ qua $skipOtCount lượt do sẽ làm quá 40h/tháng.";

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(msg),
                            backgroundColor:
                                (skipConflictCount > 0 || skipOtCount > 0)
                                ? Colors.orange.shade800
                                : Colors.green,
                            duration: const Duration(seconds: 5),
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // 2. Tăng Ca Siêu Tốc
  static void showAddOvertimeDialog(
    BuildContext context,
    DateTime currentDate,
  ) {
    DateTime startDate = currentDate;
    DateTime endDate = currentDate;
    Set<int> selectedWeekdays = {currentDate.weekday};
    Set<int> selectedEmpIds = {};
    int? selectedShiftId;
    String empSearchQuery = "";

    final otCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final employeeCubit = context.read<EmployeeCubit>();
    final shiftCubit = context.read<ShiftCubit>();
    final scheduleCubit = context.read<WorkScheduleCubit>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: employeeCubit),
          BlocProvider.value(value: shiftCubit),
        ],
        child: StatefulBuilder(
          builder: (context, setStateDialog) {
            bool hasSunday = selectedWeekdays.contains(7);

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              titlePadding: const EdgeInsets.all(24),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.more_time, color: Colors.orange.shade800),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Tăng Ca / Xếp lịch nghỉ",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Form(
                key: formKey,
                child: SizedBox(
                  width: 600,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade100),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Colors.orange.shade800,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Quy tắc: Với ngày thường, bạn phải CÓ LỊCH CA CHÍNH mới được thêm tăng ca. Nếu làm ngày nghỉ (Chủ nhật), hệ thống tự động tạo lịch dựa trên Ca được chọn.",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: InkWell(
                                onTap: () async {
                                  final picked = await showDateRangePicker(
                                    context: context,
                                    initialDateRange: DateTimeRange(
                                      start: startDate,
                                      end: endDate,
                                    ),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                  );
                                  if (picked != null) {
                                    setStateDialog(() {
                                      startDate = picked.start;
                                      endDate = picked.end;
                                      _syncWeekdaysWithDateRange(
                                        startDate,
                                        endDate,
                                        selectedWeekdays,
                                      );
                                      hasSunday = selectedWeekdays.contains(7);
                                    });
                                  }
                                },
                                child: InputDecorator(
                                  decoration: _inputDeco("Từ ngày - Đến ngày"),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "${DateFormat('dd/MM/yyyy').format(startDate)}  -  ${DateFormat('dd/MM/yyyy').format(endDate)}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.calendar_today,
                                        color: Colors.blue,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: otCtrl,
                                decoration: _inputDeco("Giờ TC thêm"),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty)
                                    return "Bắt buộc";
                                  return _validateOvertime(v);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            for (int i = 1; i <= 7; i++)
                              FilterChip(
                                label: Text(
                                  i == 7 ? "CN" : "T${i + 1}",
                                  style: const TextStyle(fontSize: 12),
                                ),
                                selected: selectedWeekdays.contains(i),
                                onSelected: (_) => setStateDialog(() {
                                  if (selectedWeekdays.contains(i)) {
                                    selectedWeekdays.remove(i);
                                  } else {
                                    selectedWeekdays.add(i);
                                  }

                                  if (selectedWeekdays.isNotEmpty) {
                                    endDate = _calcEndDateBasedOnWeekdays(
                                      startDate,
                                      selectedWeekdays,
                                    );
                                  } else {
                                    endDate = startDate;
                                  }

                                  hasSunday = selectedWeekdays.contains(7);
                                }),
                                selectedColor: i == 7
                                    ? Colors.red.shade100
                                    : Colors.blue.shade100,
                                checkmarkColor: i == 7
                                    ? Colors.red
                                    : Colors.blue,
                                padding: EdgeInsets.zero,
                              ),
                          ],
                        ),

                        if (hasSunday) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade100),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Tạo lịch cho Chủ Nhật",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                BlocBuilder<ShiftCubit, ShiftState>(
                                  builder: (context, state) {
                                    List<Shift> list = (state is ShiftLoaded)
                                        ? state.shifts
                                        : [];
                                    return DropdownButtonFormField<int>(
                                      value: selectedShiftId,
                                      decoration: _inputDeco(
                                        "Ca áp dụng (Bắt buộc)",
                                      ),
                                      isExpanded: true,
                                      items: list
                                          .map(
                                            (s) => DropdownMenuItem(
                                              value: s.id,
                                              child: Text(s.name),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (val) => selectedShiftId = val,
                                      validator: (v) => v == null
                                          ? "Bắt buộc chọn 1 ca"
                                          : null,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],

                        const Divider(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Chọn Nhân Viên Tăng Ca",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              "Đã chọn: ${selectedEmpIds.length}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          onChanged: (val) => setStateDialog(
                            () => empSearchQuery = val.toLowerCase(),
                          ),
                          decoration:
                              _inputDeco(
                                "Tìm tên, chức vụ...",
                                icon: Icons.search,
                              ).copyWith(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: BlocBuilder<EmployeeCubit, EmployeeState>(
                            builder: (context, state) {
                              if (state is! EmployeeLoaded)
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );

                              List<Employee> displayList = state.employees
                                  .where((e) {
                                    return e.fullName.toLowerCase().contains(
                                          empSearchQuery,
                                        ) ||
                                        (e.position).toLowerCase().contains(
                                          empSearchQuery,
                                        );
                                  })
                                  .toList();

                              if (displayList.isEmpty)
                                return const Center(
                                  child: Text("Không tìm thấy nhân viên"),
                                );

                              bool isAllSelected =
                                  displayList.isNotEmpty &&
                                  displayList.every(
                                    (e) => selectedEmpIds.contains(e.id),
                                  );

                              return Column(
                                children: [
                                  CheckboxListTile(
                                    title: const Text(
                                      "Chọn tất cả",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    value: isAllSelected,
                                    onChanged: (val) {
                                      setStateDialog(() {
                                        if (val == true) {
                                          selectedEmpIds.addAll(
                                            displayList.map((e) => e.id),
                                          );
                                        } else {
                                          selectedEmpIds.removeAll(
                                            displayList.map((e) => e.id),
                                          );
                                        }
                                      });
                                    },
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    tileColor: Colors.orange.shade50,
                                    activeColor: Colors.orange.shade700,
                                    dense: true,
                                  ),
                                  const Divider(height: 1),
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: displayList.length,
                                      itemBuilder: (ctx, index) {
                                        final emp = displayList[index];
                                        return CheckboxListTile(
                                          title: Text(
                                            emp.fullName,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          subtitle: Text(
                                            emp.position,
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                          value: selectedEmpIds.contains(
                                            emp.id,
                                          ),
                                          activeColor: Colors.orange.shade700,
                                          onChanged: (val) {
                                            setStateDialog(() {
                                              if (val == true) {
                                                selectedEmpIds.add(emp.id);
                                              } else {
                                                selectedEmpIds.remove(emp.id);
                                              }
                                            });
                                          },
                                          controlAffinity:
                                              ListTileControlAffinity.leading,
                                          dense: true,
                                        );
                                      },
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
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    "Hủy",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text("LƯU TĂNG CA"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      if (selectedEmpIds.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Vui lòng chọn nhân viên!"),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }
                      if (selectedWeekdays.isEmpty) return;

                      final scheduleState = scheduleCubit.state;
                      if (scheduleState is WorkScheduleLoaded) {
                        Navigator.pop(ctx);
                        double parsedOt = double.tryParse(otCtrl.text) ?? 0.0;

                        // [MỚI] TÍNH TRƯỚC SỐ OT TRONG THÁNG ĐỂ CHẶN LỖI 400 BAD REQUEST
                        Map<String, double> monthlyOtMap = {};
                        for (var s in scheduleState.schedules) {
                          try {
                            DateTime d = DateTime.parse(s.workDate);
                            String key = "${s.employeeId}_${d.year}_${d.month}";
                            monthlyOtMap[key] =
                                (monthlyOtMap[key] ?? 0.0) + s.overtimeHours;
                          } catch (_) {}
                        }

                        int updateCount = 0;
                        int newCount = 0;
                        int skipNoShiftCount = 0;
                        int skipOtCount = 0;

                        for (
                          int i = 0;
                          i <= endDate.difference(startDate).inDays;
                          i++
                        ) {
                          DateTime day = startDate.add(Duration(days: i));
                          if (selectedWeekdays.contains(day.weekday)) {
                            String targetDateStr = DateFormat(
                              'yyyy-MM-dd',
                            ).format(day);
                            String monthKey = "${day.year}_${day.month}";

                            for (int empId in selectedEmpIds) {
                              String empMonthKey = "${empId}_$monthKey";
                              double currentOt =
                                  monthlyOtMap[empMonthKey] ?? 0.0;

                              WorkSchedule? existingSchedule = scheduleState
                                  .schedules
                                  .where(
                                    (s) =>
                                        s.employeeId == empId &&
                                        s.workDate == targetDateStr,
                                  )
                                  .firstOrNull;

                              double oldOt =
                                  existingSchedule?.overtimeHours ?? 0.0;
                              // Tính tổng OT mới (nếu là update thì bù trừ OT cũ)
                              double newTotalOt = currentOt - oldOt + parsedOt;

                              // KIỂM TRA ĐIỀU KIỆN > 40H
                              if (newTotalOt > 40.0) {
                                skipOtCount++;
                                continue;
                              }

                              // Cập nhật mảng tính tạm thời
                              monthlyOtMap[empMonthKey] = newTotalOt;

                              if (existingSchedule != null) {
                                final updatedSchedule = WorkSchedule(
                                  id: existingSchedule.id,
                                  workDate: existingSchedule.workDate,
                                  employeeId: existingSchedule.employeeId,
                                  shiftId: existingSchedule.shiftId,
                                  overtimeHours: parsedOt,
                                );
                                scheduleCubit.saveSchedule(
                                  schedule: updatedSchedule,
                                  isEdit: true,
                                );
                                updateCount++;
                              } else {
                                if (day.weekday == 7 &&
                                    selectedShiftId != null) {
                                  final newSchedule = WorkSchedule(
                                    id: 0,
                                    workDate: targetDateStr,
                                    employeeId: empId,
                                    shiftId: selectedShiftId!,
                                    overtimeHours: parsedOt,
                                  );
                                  scheduleCubit.saveSchedule(
                                    schedule: newSchedule,
                                    isEdit: false,
                                  );
                                  newCount++;
                                } else {
                                  skipNoShiftCount++;
                                }
                              }
                            }
                          }
                        }

                        String msg =
                            "Cập nhật $updateCount lịch cũ, Tạo $newCount lịch CN.";
                        if (skipNoShiftCount > 0)
                          msg +=
                              " Bỏ qua $skipNoShiftCount người (Chưa có ca).";
                        if (skipOtCount > 0)
                          msg += " Chặn $skipOtCount lượt (>40h/tháng).";

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(msg),
                            backgroundColor:
                                (skipNoShiftCount > 0 || skipOtCount > 0)
                                ? Colors.blueGrey
                                : Colors.green,
                            duration: const Duration(seconds: 6),
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // 3. Sửa 1 lịch cá nhân cụ thể
  static void showSingleScheduleEditDialog(
    BuildContext context,
    WorkSchedule schedule,
    AppLocalizations l10n,
  ) {
    DateTime selectedDate = DateTime.parse(schedule.workDate);
    int? selectedEmpId = schedule.employeeId;
    int? selectedShiftId = schedule.shiftId;
    final otCtrl = TextEditingController(
      text: schedule.overtimeHours > 0 ? schedule.overtimeHours.toString() : '',
    );
    final formKey = GlobalKey<FormState>();

    final employeeCubit = context.read<EmployeeCubit>();
    final shiftCubit = context.read<ShiftCubit>();
    final scheduleCubit = context.read<WorkScheduleCubit>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: employeeCubit),
          BlocProvider.value(value: shiftCubit),
        ],
        child: StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              titlePadding: const EdgeInsets.all(24),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.edit_calendar,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Chỉnh Sửa Lịch Cá Nhân",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Form(
                key: formKey,
                child: SizedBox(
                  width: 400,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InputDecorator(
                          decoration: _inputDeco("Ngày làm việc"),
                          child: Text(
                            DateFormat('dd/MM/yyyy').format(selectedDate),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 16),
                        BlocBuilder<EmployeeCubit, EmployeeState>(
                          builder: (context, state) {
                            List<Employee> list = (state is EmployeeLoaded)
                                ? state.employees
                                : [];
                            return DropdownButtonFormField<int>(
                              value: selectedEmpId,
                              decoration: _inputDeco("Nhân viên"),
                              isExpanded: true,
                              items: list
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e.id,
                                      child: Text(e.fullName),
                                    ),
                                  )
                                  .toList(),
                              onChanged: null,
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: BlocBuilder<ShiftCubit, ShiftState>(
                                builder: (context, state) {
                                  List<Shift> list = (state is ShiftLoaded)
                                      ? state.shifts
                                      : [];
                                  return DropdownButtonFormField<int>(
                                    value: selectedShiftId,
                                    decoration: _inputDeco("Đổi Ca làm việc"),
                                    isExpanded: true,
                                    items: list
                                        .map(
                                          (s) => DropdownMenuItem(
                                            value: s.id,
                                            child: Text(s.name),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (val) => selectedShiftId = val,
                                    validator: (v) =>
                                        v == null ? "Bắt buộc" : null,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: otCtrl,
                                decoration: _inputDeco("Giờ TC thêm"),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                validator: _validateOvertime,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    "Hủy",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text("CẬP NHẬT"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (formKey.currentState!.validate() &&
                        selectedShiftId != null) {
                      Navigator.pop(ctx);
                      final updatedSchedule = WorkSchedule(
                        id: schedule.id,
                        workDate: schedule.workDate,
                        employeeId: selectedEmpId,
                        shiftId: selectedShiftId!,
                        overtimeHours: double.tryParse(otCtrl.text) ?? 0.0,
                      );
                      scheduleCubit.saveSchedule(
                        schedule: updatedSchedule,
                        isEdit: true,
                      );
                    }
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static void confirmDeleteSchedule(
    BuildContext context,
    WorkSchedule item,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text("Xóa Lịch"),
          ],
        ),
        content: Text(
          "Xóa lịch làm việc ngày ${DateFormat('dd/MM/yyyy').format(DateTime.parse(item.workDate))}?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<WorkScheduleCubit>().deleteSchedule(item.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Xóa Lịch"),
          ),
        ],
      ),
    );
  }
}
