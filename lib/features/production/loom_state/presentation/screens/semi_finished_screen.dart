import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:owvds/features/production/loom_state/product/presentation/bloc/product_cubit.dart';
import 'package:owvds/features/production/loom_state/product_type/presentation/bloc/product_type_cubit.dart';

import '../../../../../core/widgets/responsive_layout.dart';
import '../../../../../core/network/websocket_service.dart'; // Import service của bạn

import '../widgets/product_type_sidebar.dart';
import '../widgets/product_grid_view.dart';

class SemiFinishedScreen extends StatefulWidget {
  const SemiFinishedScreen({super.key});

  @override
  State<SemiFinishedScreen> createState() => _SemiFinishedScreenState();
}

class _SemiFinishedScreenState extends State<SemiFinishedScreen> {
  int? _selectedTypeId;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // 1. Tải dữ liệu ban đầu
    context.read<ProductTypeCubit>().loadProductTypes();
    context.read<ProductCubit>().loadProducts();

    // 2. Kích hoạt và lắng nghe WebSocket toàn cục
    WebSocketService().connect();
    WebSocketService().addListener(_onWebSocketMessage);
  }

  // Hàm xử lý khi nhận được tín hiệu từ Backend
  void _onWebSocketMessage(String message) {
    if (!mounted) return; // Đảm bảo widget còn tồn tại trên màn hình

    if (message == "REFRESH_PRODUCTS") {
      // Reload danh sách sản phẩm (vẫn giữ nguyên bộ lọc loại đang chọn)
      context.read<ProductCubit>().loadProducts(typeId: _selectedTypeId);
    } else if (message == "REFRESH_PRODUCT_TYPES") {
      // Reload danh sách loại sản phẩm bên cột trái
      context.read<ProductTypeCubit>().loadProductTypes();
    }
  }

  @override
  void dispose() {
    // Gỡ bỏ listener khi thoát khỏi màn hình này để tránh rò rỉ bộ nhớ (Memory Leak)
    WebSocketService().removeListener(_onWebSocketMessage);
    super.dispose();
  }

  void _onTypeSelected(int? typeId) {
    setState(() {
      _selectedTypeId = typeId;
    });
    context.read<ProductCubit>().loadProducts(typeId: typeId);

    // Đóng Drawer nếu đang ở Mobile
    if (ResponsiveLayout.isMobile(context) &&
        _scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          "Quản lý Bán Thành Phẩm",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
          if (isDesktop) ...[
            TextButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('Import Excel'),
              onPressed: () {
                // Xử lý File Picker (gọi hàm importExcel của ProductCubit)
              },
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('Export Excel'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.green.shade700,
              ),
              onPressed: () => context.read<ProductCubit>().exportExcel(),
            ),
            const SizedBox(width: 16),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.download, color: Colors.green),
              onPressed: () => context.read<ProductCubit>().exportExcel(),
            ),
          ],
        ],
      ),
      // Drawer cho Mobile
      drawer: isDesktop
          ? null
          : Drawer(
              child: ProductTypeSidebar(
                selectedTypeId: _selectedTypeId,
                onTypeSelected: _onTypeSelected,
              ),
            ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar cho Desktop
          if (isDesktop)
            ProductTypeSidebar(
              selectedTypeId: _selectedTypeId,
              onTypeSelected: _onTypeSelected,
            ),

          Expanded(child: ProductGridView(selectedTypeId: _selectedTypeId)),
        ],
      ),
    );
  }
}
