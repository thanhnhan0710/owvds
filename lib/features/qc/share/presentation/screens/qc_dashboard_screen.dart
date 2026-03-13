import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:owvds/core/widgets/responsive_layout.dart';
import 'package:owvds/features/home/presentation/widgets/admin_sidebar.dart';
import 'package:owvds/features/qc/bom/domain/bom_model.dart';
import 'package:owvds/features/qc/bom/presentation/bloc/bom_cubit.dart';

// Imports Bloc & Model cho lấy dữ liệu thật
import 'package:owvds/features/qc/loom_state_standard/presentation/bloc/loom_state_standard_cubit.dart';
import 'package:owvds/features/qc/loom_state_standard/domain/loom_state_standard_model.dart';

class QCDashboardScreen extends StatefulWidget {
  const QCDashboardScreen({super.key});

  @override
  State<QCDashboardScreen> createState() => _QCDashboardScreenState();
}

class _QCDashboardScreenState extends State<QCDashboardScreen> {
  final Color _primaryColor = const Color(0xFF003366);
  final Color _bgColor = const Color(0xFFF5F7FA);
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Yêu cầu tải dữ liệu mới nhất khi vào Dashboard
    context.read<StandardCubit>().loadStandards();
    context.read<BOMCubit>().loadBOMHeaders();
  }

  void onNavigate(String route) {
    if (ResponsiveLayout.isMobile(context) &&
        scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.pop(context);
    }
    if (route != '#') context.go(route);
  }

  // Hàm hỗ trợ format thời gian thông minh
  String _formatDate(DateTime? date) {
    if (date == null) return "Gần đây";
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return "Vừa xong";
    if (diff.inMinutes < 60) return "${diff.inMinutes} phút trước";
    if (diff.inHours < 24) return "${diff.inHours} giờ trước";
    if (diff.inDays < 7) return "${diff.inDays} ngày trước";
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  // --- HÀM HIỂN THỊ POPUP THÔNG BÁO ---
  void _showNotificationsDialog(List<Map<String, dynamic>> notifications) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Thông báo hệ thống",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            height: 350,
            child: notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 48,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Không có thông báo mới",
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final n = notifications[index];
                      return _buildNotificationItem(
                        n['title'],
                        n['desc'],
                        n['time'],
                        n['icon'],
                        isWarning: n['isWarning'] ?? false,
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Đóng"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNotificationItem(
    String title,
    String desc,
    String time,
    IconData icon, {
    bool isWarning = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
      leading: CircleAvatar(
        backgroundColor: isWarning ? Colors.red.shade50 : Colors.blue.shade50,
        child: Icon(
          icon,
          color: isWarning ? Colors.red : Colors.blue,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            desc,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 6),
          Text(
            time,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      isThreeLine: true,
    );
  }

  // --- WIDGET NÚT THÔNG BÁO ---
  Widget _buildNotificationButton(List<Map<String, dynamic>> notifs) {
    return IconButton(
      icon: Badge(
        label: Text('${notifs.length}'),
        isLabelVisible: notifs.isNotEmpty,
        backgroundColor: Colors.redAccent,
        child: const Icon(Icons.notifications_none_rounded, size: 26),
      ),
      onPressed: () => _showNotificationsDialog(notifs),
      tooltip: "Thông báo",
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isMobile = ResponsiveLayout.isMobile(context);

    // Bọc toàn bộ trang bằng 2 BlocBuilder để luôn có dữ liệu thật nhất
    return BlocBuilder<StandardCubit, StandardState>(
      builder: (context, standardState) {
        return BlocBuilder<BOMCubit, BOMState>(
          builder: (context, bomState) {
            // 1. Trích xuất dữ liệu mảng thực tế
            List<BOMHeader> boms = [];
            if (bomState is BOMListLoaded) boms = bomState.boms;

            List<Standard> standards = [];
            if (standardState is StandardLoaded) {
              standards = standardState.displayedStandards;
            }

            // 2. Tạo dữ liệu "Hoạt động gần đây" thật từ list đã lấy
            List<Map<String, dynamic>> realActivities = [];
            for (var b in boms) {
              realActivities.add({
                "title":
                    "Cập nhật Định mức mã PID ${b.productId} (Năm ${b.applicableYear})",
                "time": _formatDate(b.updatedAt),
                "user": "Quản trị viên",
                "color": Colors.orange,
                "timestamp": b.updatedAt ?? DateTime(2000),
                "icon": Icons.scale_rounded,
              });
            }
            for (var s in standards) {
              realActivities.add({
                "title":
                    "Cập nhật Tiêu chuẩn BTP mã ${s.product?.itemCode ?? s.productId}",
                "time": "Gần đây",
                "user": "QC/KCS",
                "color": Colors.blue,
                "timestamp": DateTime(
                  2000,
                ), // Fallback nếu Standard không có date
                "icon": Icons.precision_manufacturing_rounded,
              });
            }
            // Sắp xếp ưu tiên thời gian mới nhất (descending)
            realActivities.sort(
              (a, b) => (b['timestamp'] as DateTime).compareTo(
                a['timestamp'] as DateTime,
              ),
            );
            final displayActivities = realActivities
                .take(6)
                .toList(); // Lấy 6 hoạt động mới nhất

            // 3. Tạo dữ liệu "Thông báo" thật
            List<Map<String, dynamic>> realNotifs = [];

            // Thông báo cảnh báo: Các BOM đang bị vô hiệu hóa (Inactive) cần xem xét
            final inactiveBoms = boms.where((b) => !b.isActive).toList();
            for (var b in inactiveBoms.take(5)) {
              realNotifs.add({
                "title": "BOM chưa kích hoạt",
                "desc":
                    "Định mức năm ${b.applicableYear} (PID: ${b.productId}) đang ở trạng thái tắt. Vui lòng kiểm tra lại.",
                "time": _formatDate(b.updatedAt),
                "icon": Icons.warning_amber_rounded,
                "isWarning": true,
              });
            }

            // Thông báo thông tin: Vừa có tiêu chuẩn BTP mới được duyệt
            if (standards.isNotEmpty) {
              final latestStd = standards.first;
              realNotifs.add({
                "title": "Tiêu chuẩn BTP hiện hành",
                "desc":
                    "Mã sản phẩm ${latestStd.product?.itemCode ?? latestStd.productId} đang được áp dụng theo tiêu chuẩn mới nhất.",
                "time": "Gần đây",
                "icon": Icons.info_outline_rounded,
                "isWarning": false,
              });
            }

            return Scaffold(
              key: scaffoldKey,
              backgroundColor: _bgColor,
              appBar: isDesktop
                  ? null
                  : AppBar(
                      title: const Text(
                        "QC Dashboard",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      leading: IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: () => scaffoldKey.currentState?.openDrawer(),
                      ),
                      actions: [
                        _buildNotificationButton(realNotifs),
                        const SizedBox(width: 8),
                      ],
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                // Nút thông báo trên Desktop
                                _buildNotificationButton(realNotifs),
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
                                _buildSectionTitle("Thống kê dữ liệu thực"),
                                const SizedBox(height: 16),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    int crossAxisCount = isMobile
                                        ? 1
                                        : (constraints.maxWidth > 900 ? 3 : 2);
                                    return GridView.count(
                                      crossAxisCount: crossAxisCount,
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                      childAspectRatio: isMobile ? 3.0 : 2.5,
                                      children: [
                                        _buildStatCard(
                                          title: "Tiêu chuẩn BTP",
                                          value:
                                              "${standards.length}", // Real Data
                                          subtitle: "Bản ghi đã lưu hệ thống",
                                          icon: Icons
                                              .precision_manufacturing_rounded,
                                          color: Colors.blue,
                                        ),
                                        // Thẻ này tạm để demo vì hiện tại chưa có Product Standards Cubit
                                        _buildStatCard(
                                          title: "Tiêu chuẩn Thành phẩm",
                                          value: "0",
                                          subtitle: "Tính năng đang phát triển",
                                          icon: Icons.fact_check_rounded,
                                          color: Colors.green,
                                        ),
                                        _buildStatCard(
                                          title: "Định mức Vật tư",
                                          value: "${boms.length}", // Real Data
                                          subtitle: "BOM hiện hành",
                                          icon: Icons.pie_chart_rounded,
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
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                      childAspectRatio: isMobile ? 2.5 : 2.0,
                                      children: [
                                        _buildActionCard(
                                          title: "Tiêu chuẩn Bán thành phẩm",
                                          subtitle:
                                              "Quản lý thông số Rộng, Dày, Lực đứt của phôi, mộc...",
                                          icon: Icons
                                              .precision_manufacturing_outlined,
                                          color1: Colors.blue.shade700,
                                          color2: Colors.blue.shade400,
                                          onTap: () => onNavigate(
                                            '/loom-state-standards',
                                          ),
                                        ),
                                        _buildActionCard(
                                          title: "Tiêu chuẩn Thành phẩm",
                                          subtitle:
                                              "Thông số chất lượng vải sau nhuộm, hoàn tất...",
                                          icon: Icons.fact_check_outlined,
                                          color1: Colors.green.shade700,
                                          color2: Colors.teal.shade400,
                                          onTap: () => onNavigate(
                                            '/qc/product-standards',
                                          ),
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
                                _buildSectionTitle(
                                  "Hoạt động cập nhật gần đây",
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.02),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: displayActivities.isEmpty
                                      ? const Padding(
                                          padding: EdgeInsets.all(40.0),
                                          child: Center(
                                            child: Text(
                                              "Hệ thống chưa ghi nhận hoạt động nào gần đây.",
                                              style: TextStyle(
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                        )
                                      : ListView.separated(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount: displayActivities.length,
                                          separatorBuilder: (context, index) =>
                                              Divider(
                                                height: 1,
                                                color: Colors.grey.shade100,
                                              ),
                                          itemBuilder: (context, index) {
                                            final item =
                                                displayActivities[index];
                                            return ListTile(
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 20,
                                                    vertical: 12,
                                                  ),
                                              leading: CircleAvatar(
                                                backgroundColor:
                                                    (item['color'] as Color)
                                                        .withOpacity(0.1),
                                                child: Icon(
                                                  item['icon'] as IconData,
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
                                                padding: const EdgeInsets.only(
                                                  top: 6.0,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.access_time,
                                                      size: 14,
                                                      color:
                                                          Colors.grey.shade500,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      item['time'] as String,
                                                      style: TextStyle(
                                                        color: Colors
                                                            .grey
                                                            .shade600,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 16),
                                                    Icon(
                                                      Icons.person_outline,
                                                      size: 14,
                                                      color:
                                                          Colors.grey.shade500,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      item['user'] as String,
                                                      style: TextStyle(
                                                        color: Colors
                                                            .grey
                                                            .shade600,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              trailing: isMobile
                                                  ? null
                                                  : OutlinedButton(
                                                      onPressed: () {
                                                        if (item['color'] ==
                                                            Colors.orange) {
                                                          onNavigate('/boms');
                                                        } else {
                                                          onNavigate(
                                                            '/loom-state-standards',
                                                          );
                                                        }
                                                      },
                                                      style: OutlinedButton.styleFrom(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 16,
                                                            ),
                                                        side: BorderSide(
                                                          color: Colors
                                                              .grey
                                                              .shade300,
                                                        ),
                                                      ),
                                                      child: const Text(
                                                        "Chi tiết",
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                        ),
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
          },
        );
      },
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
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  icon,
                  size: 120,
                  color: Colors.white.withOpacity(0.15),
                ),
              ),
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
