import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:owvds/features/hr/share/presentation/screens/hr_dashboard_screen.dart';
import 'package:owvds/features/inventory/share/presentation/screens/warehouse_dashboard_screen.dart';
import 'package:owvds/features/qc/share/presentation/screens/qc_dashboard_screen.dart';
import 'package:owvds/features/production/share/presentation/screens/production_dashboard.dart';
import 'package:owvds/l10n/app_localizations.dart';

import '../../../../core/widgets/responsive_layout.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/admin_topbar.dart';
import '../widgets/dashboard_content.dart';

// ─── DESIGN TOKENS ────────────────────────────────────────────────────────────
const _kSidebarBg = Color(0xFF0A1628);
const _kPageBg = Color(0xFFF0F4FA);
const _kPrimary = Color(0xFF2563EB);

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // ── Navigation handler ───────────────────────────────────────────────────────
  void _onNavigate(String route) {
    if (route == '#') {
      _showUnderDevelopmentDialog();
    } else {
      context.go(route);
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
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.construction_rounded,
                  color: Colors.orange.shade600,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.notice,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0A1628),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.featureUnderDevelopment,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF9BA8BB),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFEFF6FF),
                    foregroundColor: _kPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    l10n.close,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    // Auth state
    final authState = context.watch<AuthCubit>().state;
    String userRole = 'Staff';
    String userName = 'User';
    bool isAdmin = false;

    if (authState is AuthAuthenticated) {
      userRole = authState.user.role;
      userName = authState.user.fullName;
      isAdmin = userRole == 'admin' || authState.user.isSuperuser;
    }

    // Current path
    String currentPath = '/admin-dashboard';
    try {
      currentPath = GoRouterState.of(context).uri.path;
    } catch (_) {}

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _kPageBg,

      // ── Mobile AppBar ────────────────────────────────────────────────────────
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: _kSidebarBg,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.white),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              title: const Text(
                'ERP',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Colors.white),
                  onPressed: () => context.read<AuthCubit>().logout(),
                ),
              ],
            ),

      // ── Mobile Drawer ────────────────────────────────────────────────────────
      drawer: isDesktop
          ? null
          : Drawer(
              width: 248,
              child: AdminSidebar(
                currentPath: currentPath,
                isAdmin: isAdmin,
                onNavigate: _onNavigate,
                userName: userName,
                userRole: userRole,
              ),
            ),

      // ── Body ─────────────────────────────────────────────────────────────────
      body: Row(
        children: [
          // Sidebar (desktop only)
          if (isDesktop)
            AdminSidebar(
              currentPath: currentPath,
              isAdmin: isAdmin,
              onNavigate: _onNavigate,
              userName: userName,
              userRole: userRole,
            ),

          Expanded(
            child: Column(
              children: [
                // TopBar (desktop only)
                if (isDesktop)
                  AdminTopBar(
                    userName: userName,
                    userRole: userRole,
                    primaryColor: _kPrimary,
                  ),

                // Page content
                Expanded(child: _buildPage(context, l10n, currentPath)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Route → Widget mapping ──────────────────────────────────────────────────
  Widget _buildPage(BuildContext context, AppLocalizations l10n, String path) {
    // 1. Main dashboard
    if (path == '/admin-dashboard' || path == '/dashboard') {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: DashboardContent(primaryColor: _kPrimary),
      );
    }

    // 2. Production
    if (path == '/production-dashboard') {
      return const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: ProductionDashboard(),
      );
    }

    // 3. HR
    if (path == '/hr-dashboard' || path == '/hr') {
      return const HrDashboardScreen();
    }

    // 4. Warehouse
    if (path == '/warehouse-dashboard' || path == '/warehouse') {
      return const WarehouseDashboardScreen();
    }

    // 5. QC
    if (path == '/qc-dashboard') {
      return const QCDashboardScreen();
    }

    // 6. Placeholder for unbuilt pages
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: _PlaceholderPage(l10n: l10n, path: path),
    );
  }
}

// ─── PLACEHOLDER PAGE ─────────────────────────────────────────────────────────
class _PlaceholderPage extends StatelessWidget {
  final AppLocalizations l10n;
  final String path;

  const _PlaceholderPage({required this.l10n, required this.path});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 480,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAF0FB)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FA),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.widgets_rounded,
              size: 32,
              color: Colors.grey.shade300,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            l10n.pageContent(path),
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Trang đang được phát triển',
            style: TextStyle(color: Colors.grey.shade300, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
