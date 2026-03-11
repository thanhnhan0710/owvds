import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:owvds/core/widgets/responsive_layout.dart';
import 'package:owvds/features/home/presentation/widgets/admin_sidebar.dart';

class QCDashboardScreen extends StatelessWidget {
  const QCDashboardScreen({super.key});

  final Color _primaryColor = const Color(0xFF003366);
  final Color _bgColor = const Color(0xFFF5F7FA);

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isMobile = ResponsiveLayout.isMobile(context);
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    void onNavigate(String route) {
      if (isMobile && scaffoldKey.currentState?.isDrawerOpen == true) {
        Navigator.pop(context);
      }
      if (route != '#') context.go(route);
    }

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: _bgColor,
      appBar: isDesktop
          ? null
          : AppBar(
              title: const Text(
                "QC Dashboard",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => scaffoldKey.currentState?.openDrawer(),
              ),
            ),
      drawer: isDesktop
          ? null
          : Drawer(
              child: AdminSidebar(
                currentPath: '/qc-dashboard',
                isAdmin: true,
                onNavigate: onNavigate,
              ),
            ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop)
            AdminSidebar(
              currentPath: '/qc-dashboard',
              isAdmin: true,
              onNavigate: onNavigate,
            ),
          Expanded(
            child: Column(
              children: [
                // HEADER DESKTOP
                if (isDesktop)
                  Container(
                    height: 70,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Tổng quan Chất lượng (QC)",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: _primaryColor,
                              ),
                            ),
                            Text(
                              "Quản lý tiêu chuẩn và định mức sản xuất",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                // NỘI DUNG CHÍNH
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- PHẦN 1: THỐNG KÊ NHANH ---
                        _buildSectionTitle("Thống kê dữ liệu"),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            int crossAxisCount = isMobile
                                ? 1
                                : (constraints.maxWidth > 900 ? 3 : 2);
                            return GridView.count(
                              crossAxisCount: crossAxisCount,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: isMobile ? 3.0 : 2.5,
                              children: [
                                _buildStatCard(
                                  title: "Tiêu chuẩn BTP",
                                  value: "128",
                                  subtitle: "Bản ghi đã duyệt",
                                  icon: Icons.precision_manufacturing_rounded,
                                  color: Colors.blue,
                                ),
                                _buildStatCard(
                                  title: "Tiêu chuẩn Thành phẩm",
                                  value: "85",
                                  subtitle: "Bản ghi đã duyệt",
                                  icon: Icons.fact_check_rounded,
                                  color: Colors.green,
                                ),
                                _buildStatCard(
                                  title: "Định mức Vật tư",
                                  value: "42",
                                  subtitle: "Đang áp dụng",
                                  icon: Icons.scale_rounded,
                                  color: Colors.orange,
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 32),

                        // --- PHẦN 2: CHỨC NĂNG CHÍNH ---
                        _buildSectionTitle("Quản lý danh mục"),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            int crossAxisCount = isMobile
                                ? 1
                                : (constraints.maxWidth > 1000 ? 3 : 2);
                            return GridView.count(
                              crossAxisCount: crossAxisCount,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: isMobile ? 2.5 : 2.0,
                              children: [
                                _buildActionCard(
                                  title: "Tiêu chuẩn Bán thành phẩm",
                                  subtitle:
                                      "Quản lý thông số Rộng, Dày, Lực đứt của phôi, mộc...",
                                  icon: Icons.precision_manufacturing_outlined,
                                  color1: Colors.blue.shade700,
                                  color2: Colors.blue.shade400,
                                  onTap: () =>
                                      onNavigate('/loom-state-standards'),
                                ),
                                _buildActionCard(
                                  title: "Tiêu chuẩn Thành phẩm",
                                  subtitle:
                                      "Thông số chất lượng vải sau nhuộm, hoàn tất...",
                                  icon: Icons.fact_check_outlined,
                                  color1: Colors.green.shade700,
                                  color2: Colors.teal.shade400,
                                  onTap: () =>
                                      onNavigate('/qc/product-standards'),
                                ),
                                _buildActionCard(
                                  title: "Quản lý Định mức",
                                  subtitle:
                                      "Thiết lập hao hụt, định mức nguyên liệu cho từng mã",
                                  icon: Icons.pie_chart_outline_rounded,
                                  color1: Colors.orange.shade700,
                                  color2: Colors.deepOrange.shade400,
                                  onTap: () => onNavigate('/boms'),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 32),

                        // --- PHẦN 3: HOẠT ĐỘNG GẦN ĐÂY ---
                        _buildSectionTitle("Hoạt động cập nhật gần đây"),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: 4, // Dữ liệu giả lập 4 dòng
                            separatorBuilder: (context, index) =>
                                Divider(height: 1, color: Colors.grey.shade100),
                            itemBuilder: (context, index) {
                              final activities = [
                                {
                                  "title": "Cập nhật tiêu chuẩn BTP mã SP-001",
                                  "time": "10 phút trước",
                                  "user": "Nguyễn Văn A",
                                  "color": Colors.blue,
                                },
                                {
                                  "title": "Thêm mới định mức vật tư Lô 22A",
                                  "time": "1 giờ trước",
                                  "user": "Trần Thị B",
                                  "color": Colors.orange,
                                },
                                {
                                  "title":
                                      "Chỉnh sửa tiêu chuẩn Thành phẩm T-99",
                                  "time": "Hôm qua, 14:30",
                                  "user": "Lê Văn C",
                                  "color": Colors.green,
                                },
                                {
                                  "title": "Xóa định mức cũ không còn sử dụng",
                                  "time": "Hôm qua, 09:15",
                                  "user": "Nguyễn Văn A",
                                  "color": Colors.red,
                                },
                              ];
                              final item = activities[index];
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 8,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: (item['color'] as Color)
                                      .withOpacity(0.1),
                                  child: Icon(
                                    Icons.history_rounded,
                                    color: item['color'] as Color,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  item['title'] as String,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 14,
                                        color: Colors.grey.shade500,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        item['time'] as String,
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Icon(
                                        Icons.person_outline,
                                        size: 14,
                                        color: Colors.grey.shade500,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        item['user'] as String,
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: isMobile
                                    ? null
                                    : OutlinedButton(
                                        onPressed: () {},
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          side: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        child: const Text(
                                          "Chi tiết",
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                              );
                            },
                          ),
                        ),
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

  // --- WIDGET TIÊU ĐỀ MỤC ---
  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: _primaryColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  // --- WIDGET THẺ THỐNG KÊ ---
  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
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
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET THẺ HÀNH ĐỘNG (GRADIENT) ---
  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color1,
    required Color color2,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color1, color2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color1.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Icon Watermark (Chìm ở Background)
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  icon,
                  size: 120,
                  color: Colors.white.withOpacity(0.15),
                ),
              ),
              // Nội dung chính
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: Colors.white, size: 24),
                    ),
                    const Spacer(),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Mũi tên góc trên bên phải
              Positioned(
                top: 20,
                right: 20,
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withOpacity(0.7),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
