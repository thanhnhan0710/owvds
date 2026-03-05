import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:owvds/features/hr/work_schedule/shift/domain/shift_model.dart';
import 'package:owvds/features/hr/work_schedule/shift/presentation/bloc/shift_cubit.dart';

class ScheduleSidebar extends StatelessWidget {
  final int? selectedShiftId;
  final Function(int?) onShiftSelected;
  final bool showOnlyOvertime;
  final Function(bool) onOvertimeToggle;

  const ScheduleSidebar({
    super.key,
    required this.selectedShiftId,
    required this.onShiftSelected,
    required this.showOnlyOvertime,
    required this.onOvertimeToggle,
  });

  Color _getShiftColor(String shiftName) {
    String lower = shiftName.toLowerCase();
    if (lower.contains('sáng') || lower.contains('a'))
      return Colors.orange.shade600;
    if (lower.contains('chiều') || lower.contains('b'))
      return Colors.blue.shade600;
    if (lower.contains('đêm') || lower.contains('c'))
      return Colors.indigo.shade600;
    if (lower.contains('hành chính')) return Colors.teal.shade600;
    return Colors.blueGrey;
  }

  @override
  Widget build(BuildContext context) {
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
              children: [
                const Icon(Icons.access_time_filled, color: Color(0xFF003366)),
                const SizedBox(width: 8),
                const Text(
                  "Các Ca Làm Việc",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF003366),
                  ),
                ),
              ],
            ),
          ),

          // [MỚI] BỘ LỌC DANH SÁCH TĂNG CA
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: showOnlyOvertime
                  ? Colors.orange.shade50
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: showOnlyOvertime
                    ? Colors.orange.shade200
                    : Colors.grey.shade300,
              ),
            ),
            child: CheckboxListTile(
              title: Text(
                "Chỉ xem Tăng ca",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: showOnlyOvertime
                      ? Colors.orange.shade900
                      : Colors.grey.shade700,
                  fontSize: 13,
                ),
              ),
              value: showOnlyOvertime,
              onChanged: (val) => onOvertimeToggle(val ?? false),
              activeColor: Colors.orange.shade700,
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ),
          const SizedBox(height: 12),
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
                        isSelected: selectedShiftId == null,
                        onTap: () => onShiftSelected(null),
                      ),
                      const Divider(height: 1),
                      ...allShifts.map((shift) {
                        return _buildSidebarItem(
                          title: shift.name,
                          subtitle: shift.note.isNotEmpty
                              ? shift.note
                              : "8 tiếng/ngày",
                          icon: Icons.label_important,
                          color: _getShiftColor(shift.name),
                          isSelected: selectedShiftId == shift.id,
                          onTap: () => onShiftSelected(shift.id),
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
          ],
        ),
      ),
    );
  }
}
