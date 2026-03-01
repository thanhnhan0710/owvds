import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart'; // [MỚI] Import go_router để chuyển trang
import 'package:owvds/features/area/presentation/bloc/area_cubit.dart';
import 'package:owvds/features/production/machine/machine/presentation/bloc/machine_cubit.dart';
import 'package:owvds/features/production/machine/machine_status/presentation/bloc/machine_status_cubit.dart';
import 'package:owvds/features/production/machine/machine_type/presentation/bloc/machine_type_cubit.dart';
import 'package:owvds/features/production/machine/presentation/widgets/area_slidebar.dart';
import '../../../../../core/widgets/responsive_layout.dart';
import '../../../../../core/network/websocket_service.dart';

import '../widgets/machine_list_view.dart';
import 'master_data_screen.dart';

class MachineManagementScreen extends StatefulWidget {
  const MachineManagementScreen({super.key});

  @override
  State<MachineManagementScreen> createState() =>
      _MachineManagementScreenState();
}

class _MachineManagementScreenState extends State<MachineManagementScreen> {
  int? _selectedAreaId;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    context.read<AreaCubit>().loadAreas();
    context.read<MachineTypeCubit>().loadTypes();
    context.read<MachineStatusCubit>().loadStatuses();
    context.read<MachineCubit>().loadMachines();

    WebSocketService().connect();
    WebSocketService().addListener(_onWebSocketMessage);
  }

  void _onWebSocketMessage(String message) {
    if (!mounted) return;
    if (message == "REFRESH_MACHINES") {
      context.read<MachineCubit>().loadMachines(filterAreaId: _selectedAreaId);
    } else if (message == "REFRESH_AREAS") {
      context.read<AreaCubit>().loadAreas();
    } else if (message == "REFRESH_MACHINE_TYPES") {
      context.read<MachineTypeCubit>().loadTypes();
    } else if (message == "REFRESH_MACHINE_STATUSES") {
      context.read<MachineStatusCubit>().loadStatuses();
    }
  }

  @override
  void dispose() {
    WebSocketService().removeListener(_onWebSocketMessage);
    super.dispose();
  }

  void _onAreaSelected(int? areaId) {
    setState(() => _selectedAreaId = areaId);
    context.read<MachineCubit>().loadMachines(filterAreaId: areaId);
    if (ResponsiveLayout.isMobile(context) &&
        _scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    // Sử dụng MediaQuery để nhận biết chính xác kích thước Mobile cho các Widget nội bộ
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        // [TỐI ƯU MOBILE 1]: Tiêu đề ngắn gọn hơn trên màn hình nhỏ
        title: Text(
          isMobile ? "Quản lý Máy móc" : "Quản lý Thiết Bị & Máy Móc",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 16 : 18,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF003366),
        elevation: 0.5,
        leading: isDesktop
            ? null
            : IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
        actions: [
          Theme(
            data: Theme.of(context).copyWith(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: PopupMenuButton<int>(
              tooltip: 'Quản lý danh mục',
              offset: const Offset(0, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 8.0 : 16.0,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.category_outlined,
                      color: Color(0xFF003366),
                      size: 22,
                    ),
                    // [TỐI ƯU MOBILE 2]: Ẩn chữ "Danh mục", chỉ giữ lại Icon trên điện thoại
                    if (!isMobile) ...[
                      const SizedBox(width: 8),
                      const Text(
                        'Danh mục',
                        style: TextStyle(
                          color: Color(0xFF003366),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: Color(0xFF003366),
                      ),
                    ],
                  ],
                ),
              ),
              onSelected: (index) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MasterDataScreen(initialIndex: index),
                  ),
                );
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 0,
                  child: Row(
                    children: [
                      Icon(
                        Icons.precision_manufacturing,
                        size: 20,
                        color: Colors.blueGrey,
                      ),
                      SizedBox(width: 12),
                      Text('Quản lý Loại máy'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 1,
                  child: Row(
                    children: [
                      Icon(
                        Icons.monitor_heart,
                        size: 20,
                        color: Colors.blueGrey,
                      ),
                      SizedBox(width: 12),
                      Text('Quản lý Trạng thái'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // [TỐI ƯU MOBILE 3]: Biến nút TextButton thành IconButton để tiết kiệm không gian trên điện thoại
          if (isMobile) ...[
            // [MỚI] Nút chuyển nhanh sang trang Điều độ Loom dệt cho Mobile
            IconButton(
              icon: const Icon(Icons.dashboard_customize, color: Colors.blue),
              tooltip: 'Quản lý Loom dệt',
              onPressed: () => context.push('/loom-dashboard'), // Chuyển trang
            ),
            IconButton(
              icon: const Icon(Icons.upload_file, color: Color(0xFF003366)),
              tooltip: 'Import Excel',
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.download, color: Colors.green.shade700),
              tooltip: 'Export Excel',
              onPressed: () => context.read<MachineCubit>().exportExcel(),
            ),
            const SizedBox(width: 4),
          ] else ...[
            const SizedBox(width: 8),
            // [MỚI] Nút chuyển nhanh sang trang Điều độ Loom dệt cho Desktop
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade50,
                foregroundColor: Colors.blue.shade800,
                elevation: 0,
              ),
              icon: const Icon(Icons.dashboard_customize, size: 18),
              label: const Text(
                'Điều độ Loom',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () => context.push('/loom-dashboard'), // Chuyển trang
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('Import Excel'),
              onPressed: () {},
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('Export Excel'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.green.shade700,
              ),
              onPressed: () => context.read<MachineCubit>().exportExcel(),
            ),
            const SizedBox(width: 16),
          ],
        ],
      ),
      drawer: isDesktop
          ? null
          : Drawer(
              child: AreaSidebar(
                selectedAreaId: _selectedAreaId,
                onAreaSelected: _onAreaSelected,
              ),
            ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop)
            AreaSidebar(
              selectedAreaId: _selectedAreaId,
              onAreaSelected: _onAreaSelected,
            ),
          Expanded(child: MachineListView(selectedAreaId: _selectedAreaId)),
        ],
      ),
    );
  }
}
