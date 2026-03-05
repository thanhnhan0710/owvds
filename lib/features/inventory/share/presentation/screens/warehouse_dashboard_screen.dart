import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Đảm bảo import đúng đường dẫn đến file AdminSidebar và ResponsiveLayout của bạn
import 'package:owvds/features/home/presentation/widgets/admin_sidebar.dart';
import 'package:owvds/core/widgets/responsive_layout.dart';
import 'package:owvds/features/home/presentation/widgets/admin_topbar.dart';

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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = ResponsiveLayout.isMobile(context);
    final isTablet = screenWidth >= 600 && screenWidth < 1000;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    // Mock User Info (Có thể lấy từ AuthCubit sau)
    String userName = "Admin";
    String userRole = "Administrator";
    bool isAdmin = true;
    String currentPath = '/warehouse-dashboard';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _bgColor,

      // Trên Desktop tắt AppBar mặc định vì sẽ tự dựng Header bên trong
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
              actions: [
                IconButton(
                  icon: const Badge(
                    label: Text('3'),
                    child: Icon(Icons.notifications_active_outlined),
                  ),
                  onPressed: () {},
                  tooltip: "Cảnh báo tồn kho",
                ),
                const SizedBox(width: 8),
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(0xFF003366),
                  child: Icon(Icons.person, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 16),
              ],
            ),

      // Đưa Sidebar vào Drawer cho phiên bản Mobile/Tablet nhỏ
      drawer: isDesktop
          ? null
          : Drawer(
              child: AdminSidebar(
                currentPath: currentPath,
                isAdmin: isAdmin,
                onNavigate: _onNavigate,
              ),
            ),

      // Bố cục chính
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cột 1: Hiển thị thanh Admin Sidebar cố định trên màn hình lớn (Desktop)
          if (isDesktop)
            AdminSidebar(
              currentPath: currentPath,
              isAdmin: isAdmin,
              onNavigate: _onNavigate,
            ),

          // Cột 2: Nội dung trang Dashboard
          Expanded(
            child: Column(
              children: [
                // TopBar cho Desktop
                if (isDesktop)
                  AdminTopBar(
                    userName: userName,
                    userRole: userRole,
                    primaryColor: _primaryColor,
                  ),

                // Nội dung chính
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- Tiêu đề trang (Desktop) ---
                        if (isDesktop) ...[
                          Text(
                            "Bảng Điều Khiển - Kho NVL",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _primaryColor,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

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
                              value: "1,245",
                              icon: Icons.category,
                              color: Colors.blue,
                            ),
                            _buildKpiCard(
                              title: "Sắp hết hàng",
                              value: "12",
                              icon: Icons.warning_amber_rounded,
                              color: Colors.redAccent,
                            ),
                            _buildKpiCard(
                              title: "Phiếu Nhập",
                              value: "8",
                              icon: Icons.input,
                              color: Colors.teal,
                            ),
                            _buildKpiCard(
                              title: "Phiếu Xuất",
                              value: "24",
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
