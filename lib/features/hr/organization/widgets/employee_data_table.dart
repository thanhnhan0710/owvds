import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:owvds/features/hr/employee/domain/employee_model.dart';
import 'package:owvds/features/hr/employee/presentation/bloc/employee_cubit.dart';
import 'package:owvds/features/hr/employee_group/presentation/bloc/employee_group_cubit.dart';
import 'package:owvds/features/hr/organization/dialogs/org_dialog_helper.dart';

import '../../../../../core/widgets/responsive_layout.dart';

class EmployeeDataTable extends StatefulWidget {
  final int currentDeptId;
  final int? currentGroupId;

  const EmployeeDataTable({
    super.key,
    required this.currentDeptId,
    required this.currentGroupId,
  });

  @override
  State<EmployeeDataTable> createState() => _EmployeeDataTableState();
}

class _EmployeeDataTableState extends State<EmployeeDataTable> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  final Color _primary = const Color(0xFF003366);

  void _onSearch(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().isEmpty) {
        if (widget.currentGroupId != null) {
          context.read<EmployeeCubit>().loadEmployeesByGroup(
            widget.currentGroupId!,
          );
        } else {
          context.read<EmployeeCubit>().loadEmployeesByDepartment(
            widget.currentDeptId,
          );
        }
      } else {
        context.read<EmployeeCubit>().searchEmployees(query);
      }
    });
  }

  // Hàm phụ trợ để lấy tên Tổ từ ID
  String _getGroupName(int? groupId, BuildContext context) {
    if (groupId == null) return "Chưa phân tổ";
    final groupState = context.read<EmployeeGroupCubit>().state;
    if (groupState is EmployeeGroupLoaded) {
      final g = groupState.groups.where((g) => g.id == groupId).firstOrNull;
      if (g != null) return g.name;
    }
    return "Tổ ID: $groupId";
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header & Search
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: _onSearch,
                      // [ĐÃ SỬA]: Căn chỉnh chữ chính giữa, tránh bị lệch
                      textAlignVertical: TextAlignVertical.center,
                      decoration: const InputDecoration(
                        hintText: "Tìm kiếm nhân viên...",
                        prefixIcon: Icon(Icons.search, size: 18),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  icon: const Icon(Icons.person_add, size: 18),
                  // Rút gọn text trên Mobile
                  label: Text(isMobile ? "Thêm" : "Thêm Nhân Viên"),
                  onPressed: () => OrgDialogHelper.showEmployeeDialog(
                    context,
                    null,
                    widget.currentDeptId,
                    widget.currentGroupId,
                  ),
                ),
              ],
            ),
          ),

          // NỘI DUNG DANH SÁCH (BẢNG CHO DESKTOP, LIST CHO MOBILE)
          Expanded(
            child: BlocBuilder<EmployeeCubit, EmployeeState>(
              builder: (context, state) {
                if (state is EmployeeLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is EmployeeLoaded) {
                  if (state.employees.isEmpty) {
                    return Center(
                      child: Text(
                        "Không có nhân viên nào.",
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    );
                  }

                  return isMobile
                      ? _buildMobileList(state.employees)
                      : _buildDesktopTable(state.employees);
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- GIAO DIỆN DESKTOP ---
  Widget _buildDesktopTable(List<Employee> employees) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
          columns: const [
            DataColumn(
              label: Text(
                'NHÂN VIÊN',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'CHỨC VỤ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            // [MỚI] Thêm cột TỔ trên Desktop
            DataColumn(
              label: Text(
                'TỔ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'LIÊN HỆ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'THAO TÁC',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
          rows: employees
              .map(
                (emp) => DataRow(
                  cells: [
                    DataCell(
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: _primary.withOpacity(0.1),
                            child: Text(
                              emp.fullName.isNotEmpty
                                  ? emp.fullName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: _primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            emp.fullName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    DataCell(Text(emp.position)),
                    // [MỚI] Hiển thị tên tổ
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getGroupName(emp.groupId, context),
                          style: TextStyle(
                            color: Colors.teal.shade800,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.email,
                                size: 12,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                emp.email,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.phone,
                                size: 12,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                emp.phone,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: Colors.blue,
                              size: 18,
                            ),
                            onPressed: () => OrgDialogHelper.showEmployeeDialog(
                              context,
                              emp,
                              widget.currentDeptId,
                              widget.currentGroupId,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 18,
                            ),
                            onPressed: () => context
                                .read<EmployeeCubit>()
                                .deleteEmployee(emp.id),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  // --- GIAO DIỆN MOBILE ---
  Widget _buildMobileList(List<Employee> employees) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: employees.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final emp = employees[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: _primary.withOpacity(0.1),
                    child: Text(
                      emp.fullName.isNotEmpty
                          ? emp.fullName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: _primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          emp.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          emp.position,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                    onSelected: (val) {
                      if (val == 'edit') {
                        OrgDialogHelper.showEmployeeDialog(
                          context,
                          emp,
                          widget.currentDeptId,
                          widget.currentGroupId,
                        );
                      }
                      if (val == 'delete') {
                        context.read<EmployeeCubit>().deleteEmployee(emp.id);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18, color: Colors.blue),
                            SizedBox(width: 8),
                            Text("Sửa"),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text("Xóa", style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // [MỚI] Hiển thị Tổ trên Mobile
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "Tổ: ${_getGroupName(emp.groupId, context)}",
                  style: TextStyle(
                    color: Colors.teal.shade800,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.phone, size: 14, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(emp.phone, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.email, size: 14, color: Colors.blue),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            emp.email,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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
}
