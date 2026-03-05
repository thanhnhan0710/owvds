// ignore: unused_import
import 'dart:async'; // Import thư viện xử lý Stream
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:owvds/features/inventory/supplier/presentation/widgets/supplier_category_slidebar.dart';

import '../../../supplier_category/domain/supplier_category_model.dart';
import '../../../supplier_category/presentation/bloc/supplier_category_cubit.dart';
import '../bloc/supplier_cubit.dart';
import '../widgets/supplier_list_view.dart';

import '../../../../../core/widgets/responsive_layout.dart';
import '../../../../../core/network/websocket_service.dart'; // Import service WebSocket

class SupplierManagementScreen extends StatefulWidget {
  const SupplierManagementScreen({super.key});

  @override
  State<SupplierManagementScreen> createState() =>
      _SupplierManagementScreenState();
}

class _SupplierManagementScreenState extends State<SupplierManagementScreen> {
  int? _selectedCategoryId;
  String _selectedCategoryName = "Tất cả Nhà cung cấp";
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>(); // Key để điều khiển Drawer trên Mobile

  @override
  void initState() {
    super.initState();

    // Tải dữ liệu lần đầu
    context.read<SupplierCategoryCubit>().loadCategories();
    context.read<SupplierCubit>().loadSuppliers();

    // Kích hoạt và lắng nghe WebSocket toàn cục
    WebSocketService().connect();
    WebSocketService().addListener(_onWebSocketMessage);
  }

  // Hàm xử lý khi nhận được tín hiệu từ Backend
  void _onWebSocketMessage(String message) {
    if (!mounted) return; // Đảm bảo widget còn tồn tại trên màn hình

    if (message == "REFRESH_SUPPLIER_CATEGORIES") {
      // Cập nhật lại cột bên trái (danh sách loại NCC)
      context.read<SupplierCategoryCubit>().loadCategories();
    } else if (message == "REFRESH_SUPPLIERS") {
      // Cập nhật lại khung bên phải (giữ nguyên bộ lọc loại đang chọn)
      context.read<SupplierCubit>().loadSuppliers(
        categoryId: _selectedCategoryId,
      );
    }
  }

  @override
  void dispose() {
    // Gỡ bỏ listener khi thoát khỏi màn hình này để tránh rò rỉ bộ nhớ (Memory Leak)
    WebSocketService().removeListener(_onWebSocketMessage);
    super.dispose();
  }

  void _handleCategorySelected(int? categoryId, String categoryName) {
    setState(() {
      _selectedCategoryId = categoryId;
      _selectedCategoryName = categoryName;
    });
    context.read<SupplierCubit>().loadSuppliers(categoryId: categoryId);

    // Đóng Drawer nếu đang ở Mobile
    if (ResponsiveLayout.isMobile(context) &&
        _scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.pop(context);
    }
  }

  void _handleCategoryDeleted(int deletedId) {
    if (_selectedCategoryId == deletedId) {
      _handleCategorySelected(null, "Tất cả Nhà cung cấp");
    }
  }

  void _handleCategoryUpdated(SupplierCategory updatedCat) {
    if (_selectedCategoryId == updatedCat.categoryId) {
      setState(() {
        _selectedCategoryName = updatedCat.categoryName;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: isDesktop
          ? null
          : AppBar(
              title: const Text(
                "Quản lý Nhà cung cấp",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF003366),
              elevation: 0.5,
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
            ),
      drawer: isDesktop
          ? null
          : Drawer(
              child: SupplierCategorySidebar(
                selectedCategoryId: _selectedCategoryId,
                onCategorySelected: _handleCategorySelected,
                onCategoryDeleted: _handleCategoryDeleted,
                onCategoryUpdated: _handleCategoryUpdated,
              ),
            ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BÊN TRÁI: SIDEBAR PHÂN LOẠI (Chỉ hiện trên Desktop)
          if (isDesktop)
            SupplierCategorySidebar(
              selectedCategoryId: _selectedCategoryId,
              onCategorySelected: _handleCategorySelected,
              onCategoryDeleted: _handleCategoryDeleted,
              onCategoryUpdated: _handleCategoryUpdated,
            ),

          // BÊN PHẢI: DANH SÁCH NHÀ CUNG CẤP
          Expanded(
            child: SupplierListView(
              selectedCategoryId: _selectedCategoryId,
              selectedCategoryName: _selectedCategoryName,
            ),
          ),
        ],
      ),
    );
  }
}
