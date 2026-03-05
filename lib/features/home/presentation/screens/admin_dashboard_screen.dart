import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:owvds/features/hr/share/presentation/screens/hr_dashboard_screen.dart';
import 'package:owvds/features/inventory/share/presentation/screens/warehouse_dashboard_screen.dart';
import 'package:owvds/l10n/app_localizations.dart';

import '../../../../core/widgets/responsive_layout.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';

// Import các widget layout
import '../widgets/admin_sidebar.dart';
import '../widgets/admin_topbar.dart';
import '../widgets/dashboard_content.dart';

// Import màn hình Production Dashboard
import '../../../production/share/presentation/screens/production_dashboard.dart';
// [MỚI] Import màn hình HR Dashboard

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Color _primaryColor = const Color(0xFF003366);
  final Color _backgroundColor = const Color(0xFFF5F7FA);

  void _onNavigate(String route) {
    if (route == '#') {
      _showUnderDevelopmentDialog();
    } else {
      context.go(route);
      // Đóng Drawer nếu đang ở màn hình Mobile
      if (ResponsiveLayout.isMobile(context) &&
          _scaffoldKey.currentState?.isDrawerOpen == true) {
        Navigator.pop(context);
      }
    }
  }

  void _showUnderDevelopmentDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.construction_rounded, color: Colors.orange),
            const SizedBox(width: 10),
            Text(l10n.notice),
          ],
        ),
        content: Text(l10n.featureUnderDevelopment),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close, style: TextStyle(color: _primaryColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    // Lấy thông tin user
    final authState = context.watch<AuthCubit>().state;
    String userRole = 'Staff';
    String userName = 'User';
    bool isAdmin = false;

    if (authState is AuthAuthenticated) {
      userRole = authState.user.role;
      userName = authState.user.fullName;
      isAdmin = (userRole == 'admin' || authState.user.isSuperuser);
    }

    String currentPath = '/admin-dashboard';
    try {
      currentPath = GoRouterState.of(context).uri.path;
    } catch (_) {}

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _backgroundColor,
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: _primaryColor,
              leading: IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.white),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              title: Text(
                l10n.erpSystemShort,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Colors.white),
                  onPressed: () => context.read<AuthCubit>().logout(),
                ),
              ],
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
                  AdminTopBar(
                    userName: userName,
                    userRole: userRole,
                    primaryColor: _primaryColor,
                  ),
                Expanded(
                  // [SỬA]: Kiểm tra nếu là các trang có sẵn khung bao (như Dashboard)
                  // thì không cần bọc thêm padding và SingleChildScrollView để các form bên trong tự xử lý responsive
                  child: Builder(
                    builder: (context) {
                      // 1. Nếu là trang chủ
                      if (currentPath == '/admin-dashboard' ||
                          currentPath == '/dashboard') {
                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: DashboardContent(primaryColor: _primaryColor),
                        );
                      }
                      // 2. Nếu là trang Quản lý Sản Xuất (Production Dashboard)
                      else if (currentPath == '/production-dashboard') {
                        return const SingleChildScrollView(
                          padding: EdgeInsets.all(24),
                          child: ProductionDashboard(),
                        );
                      }
                      // 3. [MỚI] Điều hướng đến trang HR Dashboard
                      else if (currentPath == '/hr-dashboard' ||
                          currentPath == '/hr') {
                        // Trang HrDashboardScreen đã tự có Scaffold và SingleChildScrollView
                        // Nên ta trả về thẳng widget này mà không cần bọc gì thêm
                        return const HrDashboardScreen();
                      }
                      // 4. [MỚI] Điều hướng đến trang Warehouse Dashboard
                      else if (currentPath == '/warehouse-dashboard' ||
                          currentPath == '/warehouse') {
                        return const WarehouseDashboardScreen();
                      }
                      // 5. Các trang khác chưa có giao diện lồng vào
                      else {
                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: _buildPlaceholderContent(l10n, currentPath),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Placeholder cho các trang chưa có giao diện
  Widget _buildPlaceholderContent(AppLocalizations l10n, String currentPath) {
    return Container(
      height: 500,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.widgets_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            l10n.pageContent(currentPath),
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
