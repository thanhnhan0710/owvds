import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:owvds/features/hr/work_schedule/shift/presentation/bloc/shift_cubit.dart';

import '../../../../../core/widgets/responsive_layout.dart';
import '../../../../../core/network/websocket_service.dart';
import '../../../../../l10n/app_localizations.dart'; // [MỚI]
import '../../../work_schedule/presentation/bloc/work_schedule_cubit.dart';
import '../../../employee/presentation/bloc/employee_cubit.dart';
import '../../../employee_group/presentation/bloc/employee_group_cubit.dart';

import '../widgets/schedule_sidebar.dart';
import '../widgets/daily_schedule_view.dart';
import '../utils/schedule_dialog_helper.dart'; // [MỚI]

class WorkScheduleScreen extends StatefulWidget {
  const WorkScheduleScreen({super.key});

  @override
  State<WorkScheduleScreen> createState() => _WorkScheduleScreenState();
}

class _WorkScheduleScreenState extends State<WorkScheduleScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Color _primaryColor = const Color(0xFF003366);

  int? _selectedShiftId;
  bool _showOnlyOvertime = false;

  @override
  void initState() {
    super.initState();
    context.read<WorkScheduleCubit>().loadSchedules();
    context.read<EmployeeCubit>().loadPage(1);
    context.read<EmployeeGroupCubit>().loadGroups();
    context.read<ShiftCubit>().loadShifts();

    WebSocketService().connect();
    WebSocketService().addListener(_onWebSocketMessage);
  }

  @override
  void dispose() {
    WebSocketService().removeListener(_onWebSocketMessage);
    super.dispose();
  }

  void _onWebSocketMessage(String message) {
    if (!mounted) return;
    if (message == "REFRESH_WORK_SCHEDULES") {
      context.read<WorkScheduleCubit>().loadSchedules();
    }
    if (message == "REFRESH_EMPLOYEES") {
      context.read<EmployeeCubit>().loadPage(1);
    }
    if (message == "REFRESH_EMPLOYEE_GROUPS") {
      context.read<EmployeeGroupCubit>().loadGroups();
    }
    if (message == "REFRESH_SHIFTS") context.read<ShiftCubit>().loadShifts();
  }

  void _onShiftSelected(int? shiftId) {
    setState(() {
      _selectedShiftId = shiftId;
    });
  }

  void _toggleOvertimeFilter(bool value) {
    setState(() {
      _showOnlyOvertime = value;
    });
  }

  // Mở Bottom Sheet cho Mobile
  void _showMobileActionMenu(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "Tùy chọn",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.calendar_month, color: _primaryColor),
                ),
                title: const Text("Xếp Ca Làm Việc"),
                subtitle: const Text("Xếp ca hàng loạt cho nhân viên"),
                onTap: () {
                  Navigator.pop(ctx);
                  ScheduleDialogHelper.showQuickScheduleDialog(
                    context,
                    l10n,
                    DateTime.now(),
                  );
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.more_time, color: Colors.orange.shade800),
                ),
                title: const Text("Đăng Ký Tăng Ca"),
                subtitle: const Text("Thêm giờ tăng ca cho người đã có lịch"),
                onTap: () {
                  Navigator.pop(ctx);
                  ScheduleDialogHelper.showAddOvertimeDialog(
                    context,
                    DateTime.now(),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              title: const Text(
                "Quản lý Lịch & Tăng ca",
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
              child: ScheduleSidebar(
                selectedShiftId: _selectedShiftId,
                onShiftSelected: _onShiftSelected,
                showOnlyOvertime: _showOnlyOvertime,
                onOvertimeToggle: _toggleOvertimeFilter,
              ),
            ),
      floatingActionButton: !isDesktop
          ? FloatingActionButton(
              backgroundColor: _primaryColor,
              onPressed: () => _showMobileActionMenu(context, l10n),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop)
            ScheduleSidebar(
              selectedShiftId: _selectedShiftId,
              onShiftSelected: _onShiftSelected,
              showOnlyOvertime: _showOnlyOvertime,
              onOvertimeToggle: _toggleOvertimeFilter,
            ),

          Expanded(
            child: DailyScheduleView(
              selectedShiftId: _selectedShiftId,
              showOnlyOvertime: _showOnlyOvertime,
            ),
          ),
        ],
      ),
    );
  }
}
