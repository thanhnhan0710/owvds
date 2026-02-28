import 'package:go_router/go_router.dart';
import 'package:owvds/core/routes/go_router_refresh_stream.dart';
import 'package:owvds/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:owvds/features/auth/presentation/screens/login_screen.dart';
import 'package:owvds/features/home/presentation/screens/admin_dashboard_screen.dart';
import 'package:owvds/features/production/loom_state/presentation/screens/semi_finished_screen.dart';

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

        // HR

        // INVENTORY

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
      ],
    );
  }
}
