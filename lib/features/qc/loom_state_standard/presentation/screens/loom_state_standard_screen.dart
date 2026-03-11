import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:owvds/core/network/websocket_service.dart';
import 'package:owvds/core/widgets/responsive_layout.dart';
import 'package:owvds/features/home/presentation/widgets/admin_sidebar.dart';
import 'package:owvds/features/qc/loom_state_standard/domain/loom_state_standard_model.dart';
import 'package:owvds/features/qc/loom_state_standard/presentation/bloc/loom_state_standard_cubit.dart';

// [SỬA] Đổi import Material thành Product
import 'package:owvds/features/production/loom_state/product/presentation/bloc/product_cubit.dart';

import '../dialogs/standard_dialog.dart';
import '../widgets/standard_data_source.dart';

class StandardScreen extends StatefulWidget {
  const StandardScreen({super.key});

  @override
  State<StandardScreen> createState() => _StandardScreenState();
}

class _StandardScreenState extends State<StandardScreen> {
  final Color _primaryColor = const Color(0xFF003366);
  final Color _bgColor = const Color(0xFFF5F7FA);
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Tải danh sách tiêu chuẩn
    context.read<StandardCubit>().loadStandards();

    // [SỬA] Tải danh sách Product thay vì Material để dùng trong Dialog
    context.read<ProductCubit>().loadProducts();

    // Đăng ký lắng nghe WebSocket
    WebSocketService().connect();
    WebSocketService().addListener(_onWebSocketMessage);
  }

  @override
  void dispose() {
    WebSocketService().removeListener(_onWebSocketMessage);
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onWebSocketMessage(String message) {
    if (!mounted) return;
    if (message == "REFRESH_STANDARDS") {
      context.read<StandardCubit>().refreshCurrentState();
    }
  }

  void _onSearch(String keyword) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<StandardCubit>().searchStandards(keyword);
    });
  }

  void _onNavigate(String route) {
    if (ResponsiveLayout.isMobile(context) &&
        _scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.pop(context);
    }
    if (route != '#') context.go(route);
  }

  void _openCreateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const StandardDialog(),
    );
  }

  void _openEditDialog(Standard standard) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StandardDialog(standard: standard),
    );
  }

  void _confirmDelete(Standard standard) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: Text(
          "Bạn có chắc muốn xóa tiêu chuẩn của sản phẩm: ${standard.product?.itemCode ?? 'N/A'}?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<StandardCubit>().deleteStandard(standard.standardId);
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isMobile = ResponsiveLayout.isMobile(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _bgColor,
      appBar: isDesktop
          ? null
          : AppBar(
              title: const Text(
                "Tiêu Chuẩn Bán Thành Phẩm",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              backgroundColor: Colors.white,
              foregroundColor: _primaryColor,
              elevation: 0.5,
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add_box),
                  color: Colors.teal,
                  onPressed: _openCreateDialog,
                ),
              ],
            ),
      drawer: isDesktop
          ? null
          : Drawer(
              child: AdminSidebar(
                currentPath: '/standards',
                isAdmin: true,
                onNavigate: _onNavigate,
              ),
            ),
      body: BlocListener<StandardCubit, StandardState>(
        listener: (context, state) {
          if (state is StandardActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is StandardError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isDesktop)
              AdminSidebar(
                currentPath: '/standards',
                isAdmin: true,
                onNavigate: _onNavigate,
              ),
            Expanded(
              child: Column(
                children: [
                  if (isDesktop)
                    Container(
                      height: 64,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            "Quản Lý Tiêu Chuẩn Bán Thành Phẩm",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: _primaryColor,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(
                              Icons.refresh,
                              color: Colors.blueGrey,
                            ),
                            onPressed: () => context
                                .read<StandardCubit>()
                                .refreshCurrentState(),
                            tooltip: "Làm mới",
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: _openCreateDialog,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text("Thêm Tiêu Chuẩn"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Thanh tìm kiếm
                  Container(
                    padding: const EdgeInsets.all(24),
                    child: SizedBox(
                      width: isMobile ? double.infinity : 400,
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: _onSearch,
                        decoration: InputDecoration(
                          hintText: "Tìm kiếm theo mã sản phẩm, ghi chú...",
                          prefixIcon: const Icon(Icons.search, size: 18),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Bảng dữ liệu
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 24,
                      ).copyWith(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: BlocBuilder<StandardCubit, StandardState>(
                        builder: (context, state) {
                          if (state is StandardLoading) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (state is StandardLoaded) {
                            if (state.displayedStandards.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.assignment_late_outlined,
                                      size: 64,
                                      color: Colors.grey.shade300,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      "Chưa có tiêu chuẩn nào.",
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            // Sử dụng PaginatedDataTable cho Desktop và ListView cho Mobile
                            if (isMobile) {
                              return _buildMobileList(state.displayedStandards);
                            }

                            final dataSource = StandardDataSource(
                              standards: state.displayedStandards,
                              onEdit: _openEditDialog,
                              onDelete: _confirmDelete,
                            );

                            return SingleChildScrollView(
                              child: PaginatedDataTable(
                                header: const Text(
                                  "Danh sách tiêu chuẩn",
                                  style: TextStyle(fontSize: 16),
                                ),
                                columns: const [
                                  DataColumn(
                                    label: Text(
                                      'Mã Sản Phẩm',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Rộng (mm)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Dày (mm)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Đứt (daN)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Giãn (%)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Mật độ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'TL (g/m)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Độ cong',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Thao tác',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                                source: dataSource,
                                rowsPerPage:
                                    state.displayedStandards.length > 10
                                    ? 10
                                    : (state.displayedStandards.isEmpty
                                          ? 1
                                          : state.displayedStandards.length),
                                showCheckboxColumn: false,
                                dataRowMinHeight: 60,
                                dataRowMaxHeight: 60,
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Giao diện list card cho Mobile
  Widget _buildMobileList(List<Standard> standards) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: standards.length,
      itemBuilder: (context, index) {
        final std = standards[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.indigo.shade100),
                      ),
                      child: Text(
                        std.product?.itemCode ?? "ID: ${std.productId}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo.shade800,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.blue,
                            size: 20,
                          ),
                          onPressed: () => _openEditDialog(std),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: 20,
                          ),
                          onPressed: () => _confirmDelete(std),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 24),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _buildInfoItem("Rộng:", "${std.widthMm} mm"),
                    _buildInfoItem("Dày:", "${std.thicknessMm} mm"),
                    _buildInfoItem(
                      "Lực đứt:",
                      "${std.breakingStrengthDan} daN",
                    ),
                    _buildInfoItem(
                      "Độ giãn:",
                      "${std.elongationAtLoadPercent} %",
                    ),
                    _buildInfoItem("Mật độ ngang:", std.weftDensity),
                    _buildInfoItem("Trọng lượng:", "${std.weightGm} g/m"),
                    _buildInfoItem("Độ cong:", std.curved ?? "N/A"),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }
}
