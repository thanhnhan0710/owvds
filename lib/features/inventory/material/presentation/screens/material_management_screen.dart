// [SỬA LỖI 1]: Ẩn MaterialState của Flutter
import 'package:flutter/material.dart' hide MaterialState;
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:owvds/features/inventory/material/presentation/widgets/material_type_slidebar.dart';
// [SỬA LỖI 2]: Đã bổ sung import file MaterialListView
import 'package:owvds/features/inventory/material/presentation/widgets/material_list_view.dart';

import 'package:owvds/features/inventory/material_type/presentation/bloc/material_type_cubit.dart';
import '../bloc/material_cubit.dart';
import '../../../supplier/presentation/bloc/supplier_cubit.dart';

import '../../../../../core/widgets/responsive_layout.dart';
import '../../../../../core/network/websocket_service.dart';

class MaterialManagementScreen extends StatefulWidget {
  const MaterialManagementScreen({super.key});

  @override
  State<MaterialManagementScreen> createState() =>
      _MaterialManagementScreenState();
}

class _MaterialManagementScreenState extends State<MaterialManagementScreen> {
  // === STATE CỦA BỘ LỌC VÀ PHÂN TRANG ===
  int? _selectedTypeId;
  String _selectedTypeName = "Tất cả Nguyên vật liệu";
  int? _selectedSupplierId;
  String _searchQuery = "";

  int _currentPage = 1;
  final int _pageSize = 20; // Số lượng bản ghi trên 1 trang

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();

    // 1. Tải danh mục phụ (Loại NVL & Nhà cung cấp)
    context.read<MaterialTypeCubit>().loadTypes();
    context.read<SupplierCubit>().loadSuppliers(); // Để lấy cho Dropdown

    // 2. Tải danh sách NVL chính
    _fetchMaterials();

    // 3. Lắng nghe WebSocket
    WebSocketService().connect();
    WebSocketService().addListener(_onWebSocketMessage);
  }

  // Hàm gọi API với ĐÚNG cấu hình trang hiện tại
  void _fetchMaterials() {
    context.read<MaterialCubit>().loadMaterials(
      typeId: _selectedTypeId,
      supplierId: _selectedSupplierId,
      search: _searchQuery.isEmpty ? null : _searchQuery,
      skip: (_currentPage - 1) * _pageSize,
      limit: _pageSize,
    );
  }

  // Lắng nghe sự kiện từ Server
  void _onWebSocketMessage(String message) {
    if (!mounted) return;

    if (message == "REFRESH_MATERIAL_TYPES") {
      context.read<MaterialTypeCubit>().loadTypes();
    } else if (message == "REFRESH_MATERIALS") {
      // Khi server báo có người thay đổi NVL, chỉ load lại TRANG HIỆN TẠI (Page, Search, Bộ lọc giữ nguyên)
      _fetchMaterials();
    }
  }

  @override
  void dispose() {
    WebSocketService().removeListener(_onWebSocketMessage);
    super.dispose();
  }

  // --- CÁC HÀM XỬ LÝ SỰ KIỆN TỪ UI CON TÁC ĐỘNG LÊN STATE CHUNG ---
  void _onTypeSelected(int? typeId, String typeName) {
    setState(() {
      _selectedTypeId = typeId;
      _selectedTypeName = typeName;
      _currentPage = 1; // Reset về trang 1 khi đổi bộ lọc
    });
    _fetchMaterials();

    if (ResponsiveLayout.isMobile(context) &&
        _scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.pop(context);
    }
  }

  void _onSupplierChanged(int? supplierId) {
    setState(() {
      _selectedSupplierId = supplierId;
      _currentPage = 1;
    });
    _fetchMaterials();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _currentPage = 1;
    });
    _fetchMaterials();
  }

  void _onPageChanged(int newPage) {
    setState(() {
      _currentPage = newPage;
    });
    _fetchMaterials();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    // Lắng nghe trạng thái Export Excel (nếu Cubit bắn ra bytes)
    return BlocListener<MaterialCubit, MaterialState>(
      listener: (context, state) {
        if (state is MaterialExportSuccess) {
          // Bạn có thể cài file_saver để save byte ra máy người dùng
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Đã tạo xong file Excel. Vui lòng kiểm tra thư mục tải xuống.",
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        appBar: isDesktop
            ? null
            : AppBar(
                title: const Text(
                  "Nguyên vật liệu",
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
                child: MaterialTypeSidebar(
                  selectedTypeId: _selectedTypeId,
                  onTypeSelected: _onTypeSelected,
                ),
              ),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SIDEBAR TRÁI
            if (isDesktop)
              MaterialTypeSidebar(
                selectedTypeId: _selectedTypeId,
                onTypeSelected: _onTypeSelected,
              ),

            // NỘI DUNG CHÍNH
            Expanded(
              child: MaterialListView(
                selectedTypeId: _selectedTypeId,
                selectedTypeName: _selectedTypeName,
                selectedSupplierId: _selectedSupplierId,
                searchQuery: _searchQuery,
                currentPage: _currentPage,
                pageSize: _pageSize,
                onSupplierChanged: _onSupplierChanged,
                onSearchChanged: _onSearchChanged,
                onPageChanged: _onPageChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
