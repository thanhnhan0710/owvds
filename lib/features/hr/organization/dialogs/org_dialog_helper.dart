import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:owvds/features/hr/department/domain/department_model.dart';
import 'package:owvds/features/hr/department/presentation/bloc/department_cubit.dart';
import 'package:owvds/features/hr/employee/domain/employee_model.dart';
import 'package:owvds/features/hr/employee/presentation/bloc/employee_cubit.dart';
import 'package:owvds/features/hr/employee_group/domain/employee_group_model.dart';
import 'package:owvds/features/hr/employee_group/presentation/bloc/employee_group_cubit.dart';

class OrgDialogHelper {
  static final Color _primary = const Color(0xFF003366);

  static InputDecoration _deco(String label) => InputDecoration(
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

  // --- DIALOG BỘ PHẬN ---
  static void showDepartmentDialog(BuildContext context, Department? dept) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: dept?.name ?? '');
    final descCtrl = TextEditingController(text: dept?.description ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          dept == null ? "Thêm Bộ Phận" : "Sửa Bộ Phận",
          style: TextStyle(color: _primary, fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: _deco("Tên bộ phận *"),
                validator: (v) => v!.isEmpty ? "Bắt buộc" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descCtrl,
                decoration: _deco("Mô tả"),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final newDept = Department(
                  id: dept?.id ?? 0,
                  name: nameCtrl.text,
                  description: descCtrl.text,
                );
                if (dept == null) {
                  context.read<DepartmentCubit>().addDepartment(newDept);
                } else {
                  context.read<DepartmentCubit>().updateDepartment(newDept);
                }
                Navigator.pop(ctx);
              }
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }

  static void confirmDeleteDepartment(BuildContext context, Department dept) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text("Xóa Bộ Phận"),
          ],
        ),
        content: Text(
          "Bạn có chắc muốn xóa bộ phận '${dept.name}'? Mọi dữ liệu liên quan có thể bị ảnh hưởng.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              context.read<DepartmentCubit>().deleteDepartment(dept.id);
              Navigator.pop(ctx);
            },
            child: const Text("Xóa"),
          ),
        ],
      ),
    );
  }

  // --- DIALOG TỔ NHÂN VIÊN ---
  static void showGroupDialog(
    BuildContext context,
    EmployeeGroup? group,
    int departmentId,
  ) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: group?.name ?? '');
    final descCtrl = TextEditingController(text: group?.description ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          group == null ? "Thêm Tổ Mới" : "Sửa Thông Tin Tổ",
          style: TextStyle(color: _primary, fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: _deco("Tên Tổ (VD: Tổ Máy A) *"),
                validator: (v) => v!.isEmpty ? "Bắt buộc" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descCtrl,
                decoration: _deco("Mô tả công việc"),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final newGroup = EmployeeGroup(
                  id: group?.id ?? 0,
                  name: nameCtrl.text,
                  description: descCtrl.text,
                  departmentId: departmentId,
                );
                context.read<EmployeeGroupCubit>().saveGroup(
                  newGroup,
                  isEdit: group != null,
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }

  static void confirmDeleteGroup(BuildContext context, EmployeeGroup group) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text("Xóa Tổ"),
          ],
        ),
        content: Text("Bạn có chắc muốn xóa tổ '${group.name}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              context.read<EmployeeGroupCubit>().deleteGroup(group.id);
              Navigator.pop(ctx);
            },
            child: const Text("Xóa"),
          ),
        ],
      ),
    );
  }

  // --- DIALOG NHÂN VIÊN ---
  static void showEmployeeDialog(
    BuildContext context,
    Employee? emp,
    int currentDeptId,
    int? currentGroupId,
  ) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: emp?.fullName ?? '');
    final phoneCtrl = TextEditingController(text: emp?.phone ?? '');
    final emailCtrl = TextEditingController(text: emp?.email ?? '');
    final posCtrl = TextEditingController(text: emp?.position ?? '');

    int? selectedGroupId = emp?.groupId ?? currentGroupId;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(
          emp == null ? "Thêm Nhân Viên" : "Cập Nhật Hồ Sơ",
          style: TextStyle(color: _primary, fontWeight: FontWeight.bold),
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
                    decoration: _deco("Họ và Tên *"),
                    validator: (v) => v!.isEmpty ? "Bắt buộc" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: phoneCtrl,
                    decoration: _deco("Số điện thoại"),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailCtrl,
                    decoration: _deco("Email"),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: posCtrl,
                    decoration: _deco("Chức vụ (VD: Thợ máy)"),
                  ),
                  const SizedBox(height: 16),
                  // Dropdown chọn Tổ
                  BlocBuilder<EmployeeGroupCubit, EmployeeGroupState>(
                    builder: (context, state) {
                      List<EmployeeGroup> groups =
                          (state is EmployeeGroupLoaded) ? state.groups : [];
                      return DropdownButtonFormField<int?>(
                        value: selectedGroupId,
                        decoration: _deco("Thuộc Tổ (Tùy chọn)"),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text("Không thuộc tổ nào"),
                          ),
                          ...groups.map(
                            (g) => DropdownMenuItem(
                              value: g.id,
                              child: Text(g.name),
                            ),
                          ),
                        ],
                        onChanged: (val) => selectedGroupId = val,
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
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final newEmp = Employee(
                  id: emp?.id ?? 0,
                  fullName: nameCtrl.text,
                  email: emailCtrl.text,
                  phone: phoneCtrl.text,
                  address: emp?.address ?? '',
                  position: posCtrl.text,
                  departmentId: currentDeptId,
                  groupId: selectedGroupId,
                  note: emp?.note ?? '',
                  avatarUrl: emp?.avatarUrl ?? '',
                );
                context.read<EmployeeCubit>().saveEmployee(
                  employee: newEmp,
                  isEdit: emp != null,
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }
}
