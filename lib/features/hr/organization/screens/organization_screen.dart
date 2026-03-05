import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:owvds/features/hr/department/presentation/bloc/department_cubit.dart';
import 'package:owvds/features/hr/employee/presentation/bloc/employee_cubit.dart';
import 'package:owvds/features/hr/employee_group/presentation/bloc/employee_group_cubit.dart';
import 'package:owvds/features/hr/organization/widgets/department_slidebar.dart';

import '../../../../../core/widgets/responsive_layout.dart';
import '../../../../../core/network/websocket_service.dart';
import '../widgets/group_horizontal_list.dart';
import '../widgets/employee_data_table.dart';

class OrganizationScreen extends StatefulWidget {
  const OrganizationScreen({super.key});

  @override
  State<OrganizationScreen> createState() => _OrganizationScreenState();
}

class _OrganizationScreenState extends State<OrganizationScreen> {
  int? _selectedDeptId;
  int? _selectedGroupId;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Color _primaryColor = const Color(0xFF003366);

  @override
  void initState() {
    super.initState();
    context.read<DepartmentCubit>().loadDepartments();

    // [MỚI] Tích hợp WebSocket
    WebSocketService().connect();
    WebSocketService().addListener(_onWebSocketMessage);
  }

  @override
  void dispose() {
    WebSocketService().removeListener(_onWebSocketMessage);
    super.dispose();
  }

  // [MỚI] Hàm xử lý WebSocket
  void _onWebSocketMessage(String message) {
    if (!mounted) return;
    if (message == "REFRESH_DEPARTMENTS") {
      context.read<DepartmentCubit>().loadDepartments();
    } else if (message == "REFRESH_EMPLOYEE_GROUPS" &&
        _selectedDeptId != null) {
      context.read<EmployeeGroupCubit>().loadGroupsByDepartment(
        _selectedDeptId!,
      );
    } else if (message == "REFRESH_EMPLOYEES" && _selectedDeptId != null) {
      if (_selectedGroupId != null) {
        context.read<EmployeeCubit>().loadEmployeesByGroup(_selectedGroupId!);
      } else {
        context.read<EmployeeCubit>().loadEmployeesByDepartment(
          _selectedDeptId!,
        );
      }
    }
  }

  void _onDeptSelected(int deptId) {
    if (_selectedDeptId == deptId) return;
    setState(() {
      _selectedDeptId = deptId;
      _selectedGroupId = null; // Reset tổ khi đổi bộ phận
    });

    context.read<EmployeeGroupCubit>().loadGroupsByDepartment(deptId);
    context.read<EmployeeCubit>().loadEmployeesByDepartment(deptId);

    // [MỚI] Đóng Drawer trên Mobile sau khi chọn xong Bộ phận
    if (ResponsiveLayout.isMobile(context) &&
        _scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.pop(context);
    }
  }

  void _onGroupSelected(int? groupId) {
    setState(() {
      _selectedGroupId = groupId;
    });
    if (groupId == null) {
      context.read<EmployeeCubit>().loadEmployeesByDepartment(_selectedDeptId!);
    } else {
      context.read<EmployeeCubit>().loadEmployeesByGroup(groupId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return BlocListener<DepartmentCubit, DepartmentState>(
      listener: (context, state) {
        if (state is DepartmentLoaded &&
            state.departments.isNotEmpty &&
            _selectedDeptId == null) {
          _onDeptSelected(state.departments.first.id);
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF5F7FA),
        // [MỚI] Thêm AppBar & Drawer cho Mobile
        appBar: isDesktop
            ? null
            : AppBar(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                title: const Text(
                  "Cơ cấu Tổ chức",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
              ),
        drawer: isDesktop
            ? null
            : Drawer(
                child: DepartmentSidebar(
                  selectedDeptId: _selectedDeptId,
                  onDeptSelected: _onDeptSelected,
                ),
              ),
        body: Row(
          children: [
            // CỘT TRÁI: BỘ PHẬN (Chỉ hiện trên Desktop/Tablet lớn)
            if (isDesktop)
              DepartmentSidebar(
                selectedDeptId: _selectedDeptId,
                onDeptSelected: _onDeptSelected,
              ),

            // VÙNG PHẢI: TỔ & NHÂN VIÊN
            Expanded(
              child: _selectedDeptId == null
                  ? const Center(
                      child: Text(
                        "Vui lòng chọn một Bộ Phận",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Phần trên: Thanh trượt Tổ
                        GroupHorizontalList(
                          currentDeptId: _selectedDeptId!,
                          selectedGroupId: _selectedGroupId,
                          onGroupSelected: _onGroupSelected,
                        ),
                        // Phần dưới: Danh sách nhân viên
                        EmployeeDataTable(
                          currentDeptId: _selectedDeptId!,
                          currentGroupId: _selectedGroupId,
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
