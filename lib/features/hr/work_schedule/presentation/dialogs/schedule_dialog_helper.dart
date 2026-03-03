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

  static InputDecoration _inputDeco(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey.shade50,
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      item == null
                          ? "Thêm ca thành công"
                          : "Cập nhật ca thành công",
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.successDeleted),
                  backgroundColor: Colors.red,
                ),
              );
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
  // DIALOGS CHO XẾP LỊCH (WORK SCHEDULE)
  // ==========================================

  // 1. Xếp lịch nhanh (Hàng loạt)
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
    int? selectedEmpId;
    int? selectedShiftId;
    List<int> selectedWeekdays = [
      1,
      2,
      3,
      4,
      5,
      6,
    ]; // Mặc định từ T2->T7 (Bỏ CN)
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
                    child: Icon(Icons.add_task, color: _primaryColor),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Xếp Lịch Nhanh",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Form(
                key: formKey,
                child: SizedBox(
                  width: 500,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "1. Chọn Nhân Viên & Ca",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        BlocBuilder<EmployeeCubit, EmployeeState>(
                          builder: (context, state) {
                            List<Employee> list = (state is EmployeeLoaded)
                                ? state.employees
                                : [];
                            return DropdownButtonFormField<int>(
                              value: selectedEmpId,
                              decoration: _inputDeco(l10n.employee),
                              isExpanded: true,
                              items: list
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e.id,
                                      child: Text(e.fullName),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) => selectedEmpId = val,
                              validator: (v) => v == null ? "Required" : null,
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        BlocBuilder<ShiftCubit, ShiftState>(
                          builder: (context, state) {
                            List<Shift> list = (state is ShiftLoaded)
                                ? state.shifts
                                : [];
                            return DropdownButtonFormField<int>(
                              value: selectedShiftId,
                              decoration: _inputDeco("Chọn Ca làm việc"),
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
                              validator: (v) => v == null ? "Required" : null,
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          "2. Chọn Khoảng Thời Gian",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
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
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: _inputDeco("Từ ngày - Đến ngày"),
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
                        const SizedBox(height: 16),
                        const Text(
                          "Áp dụng cho các ngày (CN mặc định nghỉ):",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (int i = 1; i <= 7; i++)
                              FilterChip(
                                label: Text(i == 7 ? "CN" : "Thứ ${i + 1}"),
                                selected: selectedWeekdays.contains(i),
                                onSelected: (_) => setStateDialog(
                                  () => selectedWeekdays.contains(i)
                                      ? selectedWeekdays.remove(i)
                                      : selectedWeekdays.add(i),
                                ),
                                selectedColor: i == 7
                                    ? Colors.red.shade100
                                    : Colors.blue.shade100,
                                checkmarkColor: i == 7
                                    ? Colors.red
                                    : Colors.blue,
                                backgroundColor: Colors.white,
                                side: BorderSide(
                                  color: selectedWeekdays.contains(i)
                                      ? Colors.transparent
                                      : Colors.grey.shade300,
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
                  child: Text(
                    l10n.cancel,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text("XẾP LỊCH"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    if (formKey.currentState!.validate() &&
                        selectedEmpId != null &&
                        selectedShiftId != null) {
                      if (selectedWeekdays.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Vui lòng chọn ít nhất 1 ngày!"),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }
                      Navigator.pop(ctx);
                      int count = 0;
                      for (
                        int i = 0;
                        i <= endDate.difference(startDate).inDays;
                        i++
                      ) {
                        DateTime day = startDate.add(Duration(days: i));
                        if (selectedWeekdays.contains(day.weekday)) {
                          final newItem = WorkSchedule(
                            id: 0,
                            workDate: DateFormat('yyyy-MM-dd').format(day),
                            employeeId: selectedEmpId!,
                            shiftId: selectedShiftId!,
                          );
                          scheduleCubit.saveSchedule(
                            schedule: newItem,
                            isEdit: false,
                          );
                          count++;
                        }
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Đang tạo $count lịch làm việc..."),
                          backgroundColor: Colors.green,
                        ),
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

  // 2. Sửa 1 lịch cá nhân cụ thể
  static void showSingleScheduleEditDialog(
    BuildContext context,
    WorkSchedule schedule,
    AppLocalizations l10n,
  ) {
    DateTime selectedDate = DateTime.parse(schedule.workDate);
    int? selectedEmpId = schedule.employeeId;
    int? selectedShiftId = schedule.shiftId;
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
                      color: Colors.orange.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.edit_calendar,
                      color: Colors.orange.shade800,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Cập Nhật Lịch",
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
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setStateDialog(() => selectedDate = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: _inputDeco("Ngày làm việc"),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('dd/MM/yyyy').format(selectedDate),
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
                        const SizedBox(height: 16),
                        BlocBuilder<EmployeeCubit, EmployeeState>(
                          builder: (context, state) {
                            List<Employee> list = (state is EmployeeLoaded)
                                ? state.employees
                                : [];
                            return DropdownButtonFormField<int>(
                              value: selectedEmpId,
                              decoration: _inputDeco(l10n.employee),
                              isExpanded: true,
                              items: list
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e.id,
                                      child: Text(e.fullName),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) => selectedEmpId = val,
                              validator: (v) => v == null ? "Required" : null,
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        BlocBuilder<ShiftCubit, ShiftState>(
                          builder: (context, state) {
                            List<Shift> list = (state is ShiftLoaded)
                                ? state.shifts
                                : [];
                            return DropdownButtonFormField<int>(
                              value: selectedShiftId,
                              decoration: _inputDeco("Chọn Ca làm việc"),
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
                              validator: (v) => v == null ? "Required" : null,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    l10n.cancel,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text("CẬP NHẬT"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    if (formKey.currentState!.validate() &&
                        selectedEmpId != null &&
                        selectedShiftId != null) {
                      Navigator.pop(ctx);
                      final updatedSchedule = WorkSchedule(
                        id: schedule.id,
                        workDate: DateFormat('yyyy-MM-dd').format(selectedDate),
                        employeeId: selectedEmpId!,
                        shiftId: selectedShiftId!,
                      );
                      scheduleCubit.saveSchedule(
                        schedule: updatedSchedule,
                        isEdit: true,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Cập nhật lịch thành công!"),
                          backgroundColor: Colors.green,
                        ),
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
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Text(l10n.deleteSchedule),
          ],
        ),
        content: Text(
          "Xóa lịch làm việc ngày ${DateFormat('dd/MM/yyyy').format(DateTime.parse(item.workDate))}?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<WorkScheduleCubit>().deleteSchedule(item.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Đã xóa lịch làm việc"),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.deleteSchedule),
          ),
        ],
      ),
    );
  }
}
