import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:owvds/features/hr/employee_group/presentation/bloc/employee_group_cubit.dart';
import 'package:owvds/features/hr/organization/dialogs/org_dialog_helper.dart';

class GroupHorizontalList extends StatelessWidget {
  final int currentDeptId;
  final int? selectedGroupId;
  final Function(int?) onGroupSelected;

  const GroupHorizontalList({
    super.key,
    required this.currentDeptId,
    required this.selectedGroupId,
    required this.onGroupSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: BlocBuilder<EmployeeGroupCubit, EmployeeGroupState>(
        builder: (context, state) {
          if (state is EmployeeGroupLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          List<Widget> items = [];

          // Thẻ "Tất cả"
          items.add(
            _buildGroupChip(
              context,
              title: "Tất cả nhân sự",
              isSelected: selectedGroupId == null,
              onTap: () => onGroupSelected(null),
            ),
          );

          // Danh sách các tổ
          if (state is EmployeeGroupLoaded) {
            for (var group in state.groups) {
              items.add(
                _buildGroupChip(
                  context,
                  title: group.name,
                  isSelected: selectedGroupId == group.id,
                  onTap: () => onGroupSelected(group.id),
                  onEdit: () => OrgDialogHelper.showGroupDialog(
                    context,
                    group,
                    currentDeptId,
                  ),
                  onDelete: () =>
                      OrgDialogHelper.confirmDeleteGroup(context, group),
                ),
              );
            }
          }

          // Nút thêm Tổ
          items.add(
            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 16),
              child: ActionChip(
                backgroundColor: Colors.blue.shade50,
                label: const Row(
                  children: [
                    Icon(Icons.add, size: 16, color: Colors.blue),
                    SizedBox(width: 4),
                    Text(
                      "Thêm Tổ",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                onPressed: () => OrgDialogHelper.showGroupDialog(
                  context,
                  null,
                  currentDeptId,
                ),
              ),
            ),
          );

          return ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ), // Giảm padding dọc
            children: items,
          );
        },
      ),
    );
  }

  Widget _buildGroupChip(
    BuildContext context, {
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ), // Chỉnh nhỏ lại một chút
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF003366) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF003366)
                  : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              if (onEdit != null && onDelete != null) ...[
                const SizedBox(width: 12),
                InkWell(
                  onTap: onEdit,
                  child: Icon(
                    Icons.edit,
                    size: 14,
                    color: isSelected ? Colors.white70 : Colors.grey,
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: onDelete,
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: isSelected ? Colors.red.shade300 : Colors.red,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
