import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:owvds/features/hr/department/presentation/bloc/department_cubit.dart';
import 'package:owvds/features/hr/employee/presentation/bloc/employee_cubit.dart';

class HrDashboardScreen extends StatefulWidget {
  const HrDashboardScreen({super.key});

  @override
  State<HrDashboardScreen> createState() => _HrDashboardScreenState();
}

class _HrDashboardScreenState extends State<HrDashboardScreen> {
  final Color _primaryColor = const Color(0xFF003366);

  @override
  void initState() {
    super.initState();
    context.read<DepartmentCubit>().loadDepartments();
    context.read<EmployeeCubit>().loadPage(1);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1000;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          "Quản lý Nhân sự (HR)",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        foregroundColor: _primaryColor,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Badge(
              label: Text('2'),
              child: Icon(Icons.notifications_outlined),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Không có thông báo mới.')),
              );
            },
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            backgroundColor: Color(0xFF003366),
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "TỔNG QUAN NHÂN SỰ",
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
              crossAxisCount: isMobile ? 2 : (isTablet ? 3 : 4),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: isMobile ? 1.5 : 2.0,
              children: [
                BlocBuilder<EmployeeCubit, EmployeeState>(
                  builder: (context, state) {
                    String countStr = "...";
                    if (state is EmployeeLoaded) {
                      countStr = state.totalCount.toString();
                    }
                    return _buildKpiCard(
                      title: "Tổng nhân viên",
                      value: countStr,
                      icon: Icons.people_alt,
                      color: Colors.blue,
                    );
                  },
                ),

                BlocBuilder<DepartmentCubit, DepartmentState>(
                  builder: (context, state) {
                    String countStr = "...";
                    if (state is DepartmentLoaded) {
                      countStr = state.totalCount.toString();
                    }
                    return _buildKpiCard(
                      title: "Bộ phận",
                      value: countStr,
                      icon: Icons.apartment,
                      color: Colors.purple,
                    );
                  },
                ),

                _buildKpiCard(
                  title: "Có mặt hôm nay",
                  value: "--",
                  icon: Icons.how_to_reg,
                  color: Colors.green,
                ),
                _buildKpiCard(
                  title: "Nghỉ phép",
                  value: "--",
                  icon: Icons.event_busy,
                  color: Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 32),

            const Text(
              "QUẢN LÝ CHUNG",
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
                  title: "Danh sách Nhân viên",
                  subtitle: "Quản lý hồ sơ, hợp đồng",
                  icon: Icons.badge,
                  color: Colors.indigo,
                  onTap: () {
                    context.go('/employees');
                  },
                ),
                _buildFeatureCard(
                  context,
                  title: "Cơ cấu Bộ phận",
                  subtitle: "Phòng ban, Chức vụ",
                  icon: Icons.account_tree,
                  color: Colors.teal,
                  onTap: () {
                    context.go('/departments');
                  },
                ),
                // [ĐÃ SỬA] Điều hướng đến màn hình Schedule/Shift mới
                _buildFeatureCard(
                  context,
                  title: "Lịch làm việc (Ca)",
                  subtitle: "Phân ca, Xếp lịch dệt",
                  icon: Icons.calendar_month,
                  color: Colors.blueGrey,
                  onTap: () {
                    context.go(
                      '/schedules',
                    ); // Cập nhật đường dẫn này ở app_router.dart
                  },
                ),
              ],
            ),
          ],
        ),
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
