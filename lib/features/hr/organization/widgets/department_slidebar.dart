import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:owvds/features/hr/department/presentation/bloc/department_cubit.dart';
import 'package:owvds/features/hr/organization/dialogs/org_dialog_helper.dart';

class DepartmentSidebar extends StatefulWidget {
  final int? selectedDeptId;
  final Function(int) onDeptSelected;

  const DepartmentSidebar({
    super.key,
    required this.selectedDeptId,
    required this.onDeptSelected,
  });

  @override
  State<DepartmentSidebar> createState() => _DepartmentSidebarState();
}

class _DepartmentSidebarState extends State<DepartmentSidebar> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  final Color _primary = const Color(0xFF003366);

  void _onSearch(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<DepartmentCubit>().searchDepartments(query);
    });
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
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "CƠ CẤU BỘ PHẬN",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add_circle, color: _primary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () =>
                      OrgDialogHelper.showDepartmentDialog(context, null),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _onSearch,
                // [ĐÃ SỬA]: Căn chỉnh chữ chính giữa chiều dọc
                textAlignVertical: TextAlignVertical.center,
                decoration: const InputDecoration(
                  hintText: "Tìm bộ phận...",
                  prefixIcon: Icon(Icons.search, size: 18),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero, // Hủy padding thừa gây lệch
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BlocBuilder<DepartmentCubit, DepartmentState>(
              builder: (context, state) {
                if (state is DepartmentLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is DepartmentLoaded) {
                  return ListView.builder(
                    itemCount: state.departments.length,
                    itemBuilder: (context, index) {
                      final dept = state.departments[index];
                      final isSelected = widget.selectedDeptId == dept.id;

                      return InkWell(
                        onTap: () => widget.onDeptSelected(dept.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _primary.withOpacity(0.08)
                                : Colors.transparent,
                            border: Border(
                              left: BorderSide(
                                color: isSelected
                                    ? _primary
                                    : Colors.transparent,
                                width: 4,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.domain,
                                color: isSelected ? _primary : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  dept.name,
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? _primary
                                        : Colors.black87,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isSelected)
                                Row(
                                  children: [
                                    InkWell(
                                      onTap: () =>
                                          OrgDialogHelper.showDepartmentDialog(
                                            context,
                                            dept,
                                          ),
                                      child: const Icon(
                                        Icons.edit,
                                        size: 16,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () =>
                                          OrgDialogHelper.confirmDeleteDepartment(
                                            context,
                                            dept,
                                          ),
                                      child: const Icon(
                                        Icons.delete,
                                        size: 16,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
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
