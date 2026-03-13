import 'package:go_router/go_router.dart';
import 'package:owvds/core/routes/go_router_refresh_stream.dart';
import 'package:owvds/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:owvds/features/auth/presentation/screens/login_screen.dart';
import 'package:owvds/features/auth/presentation/screens/user_screen.dart';
import 'package:owvds/features/home/presentation/screens/admin_dashboard_screen.dart';
import 'package:owvds/features/hr/department/presentation/screens/department_screen.dart';
import 'package:owvds/features/hr/employee/presentation/screens/employee_screen.dart';
import 'package:owvds/features/hr/organization/screens/organization_screen.dart';
import 'package:owvds/features/hr/work_schedule/presentation/screens/work_schedule_screen.dart';
import 'package:owvds/features/inventory/PO/presentation/screens/purchase_management_screen.dart';
import 'package:owvds/features/inventory/material/presentation/screens/material_management_screen.dart';
import 'package:owvds/features/inventory/material_export/presentation/screens/material_export_screen.dart';
import 'package:owvds/features/inventory/material_inventory/presentation/screens/material_inventory_screen.dart';
import 'package:owvds/features/inventory/material_receipt/presentation/screens/material_receipt_screen.dart';
import 'package:owvds/features/inventory/share/presentation/screens/warehouse_dashboard_screen.dart';
import 'package:owvds/features/inventory/supplier/presentation/screens/supplier_management_screen.dart';
import 'package:owvds/features/log/presentation/screens/audit_log_screen.dart';
import 'package:owvds/features/production/basket/presentation/screens/baket_screen.dart';
import 'package:owvds/features/production/loom_state/presentation/screens/semi_finished_screen.dart';
import 'package:owvds/features/production/machine/machine_assignment/presentation/screens/loom_dashboard_screen.dart';
import 'package:owvds/features/production/machine/presentation/screens/macine_management_screen.dart';
import 'package:owvds/features/production/weaving_opperation/presentation/screens/machine_operation_screen.dart';
import 'package:owvds/features/production/weaving_opperation/presentation/screens/weving_ticket_list_screen.dart';
import 'package:owvds/features/qc/bom/presentation/screens/bom_screen.dart';
import 'package:owvds/features/qc/loom_state_standard/presentation/screens/loom_state_standard_screen.dart';
import 'package:owvds/features/qc/share/presentation/screens/qc_dashboard_screen.dart';

class AppRouter {
  static GoRouter router(AuthCubit authCubit) {
    return GoRouter(
      initialLocation: '/login',
      refreshListenable: GoRouterRefreshStream(authCubit.stream),
      redirect: (context, state) {
        final authState = authCubit.state;
        final bool loggedIn = authState is AuthAuthenticated;
        final bool loggingIn = state.matchedLocation == '/login';

        // 1. Nếu chưa đăng nhập: Bắt buộc ở trang login, cố tình vào trang khác sẽ bị đẩy về login
        if (!loggedIn) {
          return loggingIn ? null : '/login';
        }

        // 2. Nếu ĐÃ đăng nhập mà lại đang ở trang login: Chuyển thẳng vào Admin Dashboard
        if (loggingIn) {
          return '/admin-dashboard';
        }

        // 3. Đã đăng nhập và đang ở các trang khác: Cho phép đi tiếp (không check role nữa)
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/admin-dashboard',
          builder: (context, state) => const AdminDashboardScreen(),
        ),
        GoRoute(
          path: '/users',
          builder: (context, state) => const UserScreen(),
        ),
        GoRoute(
          path: '/logs',
          builder: (context, state) => const AuditLogScreen(),
        ),

        // HR
        GoRoute(
          path: '/hr-dashboard',
          builder: (context, state) =>
              const AdminDashboardScreen(), // Ta vẫn gọi vỏ bọc admin, admin sẽ load widget bên trong
        ),
        GoRoute(
          path: '/employees',
          builder: (context, state) => const EmployeeScreen(),
        ),
        GoRoute(
          path: '/departments',
          builder: (context, state) => const DepartmentScreen(),
        ),
        GoRoute(
          path: '/schedules',
          builder: (context, state) => const WorkScheduleScreen(),
        ),

        GoRoute(
          path: '/organization',
          builder: (context, state) => const OrganizationScreen(),
        ),

        // INVENTORY
        GoRoute(
          path: '/warehouse-dashboard',
          builder: (context, state) => const WarehouseDashboardScreen(),
        ),
        GoRoute(
          path: '/suppliers',
          builder: (context, state) => const SupplierManagementScreen(),
        ),
        GoRoute(
          path: '/materials',
          builder: (context, state) => const MaterialManagementScreen(),
        ),
        GoRoute(
          path: '/purchase-orders',
          builder: (context, state) => const PurchaseManagementScreen(),
        ),
        // Gắn liên kết Tồn Kho NVL
        GoRoute(
          path: '/inventorys',
          builder: (context, state) => const MaterialInventoryScreen(),
        ),
        // Gắn liên kết Nhập Kho NVL
        GoRoute(
          path: '/stock-in',
          builder: (context, state) => const MaterialReceiptScreen(),
        ),

        GoRoute(
          path: '/material-exports',
          builder: (context, state) => const MaterialExportScreen(),
        ),

        // PRODUCTION
        GoRoute(
          path: '/production-dashboard',
          builder: (context, state) =>
              const AdminDashboardScreen(), // Vẫn trỏ về AdminDashboardScreen để nó tự vẽ layout con
        ),
        GoRoute(
          path: '/semi-finished',
          builder: (context, state) => const SemiFinishedScreen(),
        ),
        GoRoute(
          path: '/machine-managements',
          builder: (context, state) => const MachineManagementScreen(),
        ),
        GoRoute(
          path: '/loom-dashboard',
          builder: (context, state) => const LoomDashboardScreen(),
        ),
        GoRoute(
          path: '/baskets',
          builder: (context, state) => const BasketScreen(),
        ),
        GoRoute(
          path: '/machine-operations',
          builder: (context, state) => const MachineOperationScreen(),
        ),
        GoRoute(
          path: '/weaving-tickets',
          builder: (context, state) => const WeavingTicketListScreen(),
        ),

        //QC
        GoRoute(
          path: '/qc-dashboard',
          builder: (context, state) => const QCDashboardScreen(),
        ),

        GoRoute(
          path: '/loom-state-standards',
          builder: (context, state) => const StandardScreen(),
        ),

        GoRoute(path: '/boms', builder: (context, state) => const BOMScreen()),
      ],
    );
  }
}
