import 'package:flutter/material.dart' hide MaterialState;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// Đảm bảo import đúng đường dẫn đến file AdminSidebar và ResponsiveLayout của bạn
import 'package:owvds/features/home/presentation/widgets/admin_sidebar.dart';
import 'package:owvds/core/widgets/responsive_layout.dart';
import 'package:owvds/core/network/websocket_service.dart';

import 'package:owvds/features/inventory/material/presentation/bloc/material_cubit.dart';
import 'package:owvds/features/inventory/material_receipt/presentation/bloc/material_receipt_cubit.dart';
// [MỚI]: Import Cubit Tồn kho để tính toán cảnh báo
import 'package:owvds/features/inventory/material_inventory/presentation/bloc/material_inventory_cubit.dart';

class WarehouseDashboardScreen extends StatefulWidget {
  const WarehouseDashboardScreen({super.key});

  @override
  State<WarehouseDashboardScreen> createState() =>
      _WarehouseDashboardScreenState();
}

class _WarehouseDashboardScreenState extends State<WarehouseDashboardScreen> {
  final Color _primaryColor = const Color(0xFF003366);
  final Color _bgColor = const Color(0xFFF5F7FA);

  // Khai báo key để mở Drawer trên Mobile
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Tải toàn bộ dữ liệu cần thiết cho Dashboard
    context.read<MaterialCubit>().loadMaterials();
    context.read<MaterialReceiptCubit>().loadInitial();
    context.read<MaterialInventoryCubit>().loadInventories();

    // [WEBSOCKET]: Lắng nghe sự kiện để cập nhật Dashboard Realtime
    WebSocketService().connect();
    WebSocketService().addListener(_onWebSocketMessage);
  }

  void _onWebSocketMessage(String message) {
    if (!mounted) return;
    if (message == "REFRESH_MATERIAL_RECEIPTS") {
      context.read<MaterialReceiptCubit>().loadInitial();
    } else if (message == "REFRESH_MATERIAL_INVENTORIES") {
      context.read<MaterialInventoryCubit>().loadInventories();
    }
  }

  @override
  void dispose() {
    WebSocketService().removeListener(_onWebSocketMessage);
    super.dispose();
  }

  // Hàm xử lý điều hướng chung cho Sidebar
  void _onNavigate(String route) {
    if (ResponsiveLayout.isMobile(context) &&
        _scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.pop(context); // Đóng drawer nếu đang ở trên mobile
    }
    if (route != '#') {
      context.go(route); // Chuyển trang
    }
  }

  // Cụm Avatar và Thông báo (Truyền số lượng cảnh báo vào)
  List<Widget> _buildAppBarActions(int alertCount) {
    return [
      IconButton(
        icon: Badge(
          label: Text(alertCount.toString()),
          isLabelVisible:
              alertCount > 0, // Tự động ẩn dấu đỏ nếu không có cảnh báo
          child: const Icon(Icons.notifications_active_outlined),
        ),
        onPressed: () {
          if (alertCount > 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '⚠️ Có $alertCount loại vật tư đang dưới mức tồn kho an toàn!',
                ),
                backgroundColor: Colors.red.shade600,
              ),
            );
          }
        },
        tooltip: "Cảnh báo tồn kho",
      ),
      const SizedBox(width: 8),
      const CircleAvatar(
        radius: 16,
        backgroundColor: Color(0xFF003366),
        child: Icon(Icons.person, color: Colors.white, size: 18),
      ),
      const SizedBox(width: 16),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = ResponsiveLayout.isMobile(context);
    final isTablet = screenWidth >= 600 && screenWidth < 1000;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    // Mock User Info
    bool isAdmin = true;
    String currentPath = '/warehouse-dashboard';

    // Lắng nghe trạng thái của các Cubit
    final matState = context.watch<MaterialCubit>().state;
    final invState = context.watch<MaterialInventoryCubit>().state;
    final receiptState = context.watch<MaterialReceiptCubit>().state;

    // --- TÍNH TOÁN KPI ---
    String matCountStr = "...";
    if (matState is MaterialLoaded) {
      // Ép kiểu dynamic tránh lỗi nếu bạn code totalCount là int
      matCountStr = (matState as dynamic).totalCount.toString();
    }

    String receiptCountStr = "...";
    if (receiptState is MaterialReceiptLoaded) {
      receiptCountStr =
          receiptState.receipts.length.toString() +
          (receiptState.hasNextPage ? "+" : "");
    }

    // Tính toán Tồn kho sắp hết (Low Stock)
    int lowStockCount = 0;
    bool invHasNext = false;
    if (matState is MaterialLoaded && invState is MaterialInventoryLoaded) {
      invHasNext = invState.hasNextPage;
      for (var inv in invState.inventories) {
        var matches = matState.materials.where(
          (m) => m.materialId == inv.materialId,
        );
        final mat = matches.isNotEmpty ? matches.first : null;

        // Nếu số lượng Kg hiện tại < Mức quy định tối thiểu
        if (mat != null &&
            mat.minStockLevel > 0 &&
            inv.quantityKg < mat.minStockLevel) {
          lowStockCount++;
        }
      }
    }
    String lowStockStr =
        (matState is MaterialLoaded && invState is MaterialInventoryLoaded)
        ? "$lowStockCount${invHasNext ? '+' : ''}"
        : "...";

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _bgColor,

      appBar: isDesktop
          ? null
          : AppBar(
              title: const Text(
                "Bảng Điều Khiển - Kho NVL",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              backgroundColor: Colors.white,
              foregroundColor: _primaryColor,
              elevation: 0.5,
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              actions: _buildAppBarActions(lowStockCount), // Truyền số cảnh báo
            ),

      drawer: isDesktop
          ? null
          : Drawer(
              child: AdminSidebar(
                currentPath: currentPath,
                isAdmin: isAdmin,
                onNavigate: _onNavigate,
              ),
            ),

      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop)
            AdminSidebar(
              currentPath: currentPath,
              isAdmin: isAdmin,
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
                          "Bảng Điều Khiển - Kho NVL",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: _primaryColor,
                          ),
                        ),
                        const Spacer(),
                        ..._buildAppBarActions(
                          lowStockCount,
                        ), // Truyền số cảnh báo
                      ],
                    ),
                  ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- PHẦN 1: TỔNG QUAN KPI ---
                        const Text(
                          "TỔNG QUAN TRONG NGÀY",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: isMobile ? 2 : (isTablet ? 4 : 4),
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: isMobile ? 1.5 : 2.0,
                          children: [
                            _buildKpiCard(
                              title: "Mã NVL",
                              value: matCountStr,
                              icon: Icons.category,
                              color: Colors.blue,
                            ),
                            _buildKpiCard(
                              title: "Sắp hết hàng",
                              value: lowStockStr,
                              icon: Icons.warning_amber_rounded,
                              color: Colors.redAccent,
                            ),
                            _buildKpiCard(
                              title: "Phiếu Nhập",
                              value: receiptCountStr,
                              icon: Icons.input,
                              color: Colors.teal,
                            ),
                            _buildKpiCard(
                              title: "Phiếu Xuất",
                              value: "24", // Đợi tích hợp Phiếu xuất
                              icon: Icons.output,
                              color: Colors.orange,
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // --- PHẦN 2: DANH MỤC CHỨC NĂNG ---
                        const Text(
                          "DANH MỤC QUẢN LÝ",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: isMobile ? 1 : (isTablet ? 2 : 3),
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: isMobile ? 3.0 : 2.5,
                          children: [
                            _buildFeatureCard(
                              context,
                              title: "Đơn Mua Hàng (PO)",
                              subtitle: "Quản lý mua sắm vật tư",
                              icon: Icons.shopping_cart,
                              color: Colors.blueAccent,
                              onTap: () => _onNavigate('/purchase-orders'),
                            ),
                            _buildFeatureCard(
                              context,
                              title: "Nhà Cung Cấp",
                              subtitle: "Quản lý đối tác, liên hệ",
                              icon: Icons.local_shipping,
                              color: Colors.indigo,
                              onTap: () => _onNavigate('/suppliers'),
                            ),
                            _buildFeatureCard(
                              context,
                              title: "Nguyên Vật Liệu",
                              subtitle: "Danh mục mã NVL, quy cách",
                              icon: Icons.layers,
                              color: Colors.blueGrey,
                              onTap: () => _onNavigate('/materials'),
                            ),
                            _buildFeatureCard(
                              context,
                              title: "Tồn Kho NVL",
                              subtitle: "Tra cứu số lượng, thẻ kho",
                              icon: Icons.inventory,
                              color: Colors.purple,
                              onTap: () => _onNavigate('/inventorys'),
                            ),
                            _buildFeatureCard(
                              context,
                              title: "Nhập Kho NVL",
                              subtitle: "Tạo phiếu nhập, kiểm hàng",
                              icon: Icons.add_box,
                              color: Colors.teal,
                              onTap: () => _onNavigate('/stock-in'),
                            ),
                            _buildFeatureCard(
                              context,
                              title: "Xuất Kho NVL",
                              subtitle: "Xuất sản xuất, xuất trả",
                              icon: Icons.outbox,
                              color: Colors.orange.shade700,
                              onTap: () => _onNavigate('/material-exports'),
                            ),
                            _buildFeatureCard(
                              context,
                              title: "Báo Cáo Kho",
                              subtitle: "Nhập xuất tồn, cảnh báo",
                              icon: Icons.bar_chart,
                              color: Colors.redAccent,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Tính năng Báo cáo đang phát triển',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // --- PHẦN 3: GIAO DỊCH GẦN ĐÂY ---
                        if (!isMobile) ...[
                          const Text(
                            "GIAO DỊCH GẦN ĐÂY",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: 4,
                              separatorBuilder: (context, index) => Divider(
                                height: 1,
                                color: Colors.grey.shade200,
                              ),
                              itemBuilder: (context, index) {
                                bool isImport = index % 2 == 0;
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isImport
                                        ? Colors.teal.shade50
                                        : Colors.orange.shade50,
                                    child: Icon(
                                      isImport
                                          ? Icons.arrow_downward
                                          : Icons.arrow_upward,
                                      color: isImport
                                          ? Colors.teal
                                          : Colors.orange,
                                      size: 18,
                                    ),
                                  ),
                                  title: Text(
                                    isImport
                                        ? "PNK-202403-00${index + 1}"
                                        : "PXK-202403-00${index + 1}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    isImport
                                        ? "Nhập Sợi Cotton từ NCC A"
                                        : "Xuất Nhựa PET cho Tổ Sản Xuất 1",
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "Hôm nay",
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        isImport ? "+ 1,500 kg" : "- 300 kg",
                                        style: TextStyle(
                                          color: isImport
                                              ? Colors.teal
                                              : Colors.orange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: _primaryColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.7), color],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
