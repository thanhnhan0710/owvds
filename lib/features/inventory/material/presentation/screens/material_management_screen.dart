import 'package:flutter/material.dart' hide MaterialState;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_saver/file_saver.dart';

import 'package:owvds/features/inventory/material/presentation/widgets/material_type_slidebar.dart';
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
  final int _pageSize = 20;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();

    // 1. Tải danh mục phụ (Loại NVL & Nhà cung cấp)
    context.read<MaterialTypeCubit>().loadTypes();
    context.read<SupplierCubit>().loadSuppliers();

    // 2. Tải danh sách NVL chính
    _fetchMaterials();

    // 3. Lắng nghe WebSocket
    WebSocketService().connect();
    WebSocketService().addListener(_onWebSocketMessage);
  }

  void _fetchMaterials() {
    context.read<MaterialCubit>().loadMaterials(
      typeId: _selectedTypeId,
      supplierId: _selectedSupplierId,
      search: _searchQuery.isEmpty ? null : _searchQuery,
      skip: (_currentPage - 1) * _pageSize,
      limit: _pageSize,
    );
  }

  void _onWebSocketMessage(String message) {
    if (!mounted) return;

    if (message == "REFRESH_MATERIAL_TYPES") {
      context.read<MaterialTypeCubit>().loadTypes();
    } else if (message == "REFRESH_MATERIALS") {
      _fetchMaterials();
    }
  }

  @override
  void dispose() {
    WebSocketService().removeListener(_onWebSocketMessage);
    super.dispose();
  }

  void _onTypeSelected(int? typeId, String typeName) {
    setState(() {
      _selectedTypeId = typeId;
      _selectedTypeName = typeName;
      _currentPage = 1;
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

    return BlocListener<MaterialCubit, MaterialState>(
      listener: (context, state) async {
        if (state is MaterialExportSuccess) {
          try {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Đang lưu file..."),
                duration: Duration(seconds: 1),
              ),
            );

            // [ĐÃ SỬA LỖI]: Bỏ tham số 'ext', đưa trực tiếp đuôi '.xlsx' vào tham số 'name' hoặc sử dụng đúng API của bản file_saver mới
            // Trong bản file_saver mới, tham số ext thường được thay thế bằng cách thêm vào name, hoặc thuộc tính `ext` được dùng nhưng yêu cầu kiểu chuỗi, hoặc đã bị deprecate.
            // Cách an toàn nhất là để `name` có sẵn đuôi file hoặc chỉ dùng `mimeType`.
            await FileSaver.instance.saveFile(
              name:
                  "Danh_Muc_NVL_${DateTime.now().millisecondsSinceEpoch}.xlsx", // Đưa thẳng đuôi file vào tên
              bytes: state.bytes,
              mimeType: MimeType.microsoftExcel,
            );

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Tải file Excel thành công!"),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Lỗi khi lưu file: $e"),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
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
