import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:owvds/features/hr/department/presentation/bloc/department_cubit.dart';
import 'package:owvds/features/hr/department/domain/department_model.dart';
import 'package:owvds/features/hr/employee/presentation/bloc/employee_cubit.dart';
import 'package:owvds/features/hr/employee/domain/employee_model.dart';

class HrDashboardScreen extends StatefulWidget {
  const HrDashboardScreen({super.key});

  @override
  State<HrDashboardScreen> createState() => _HrDashboardScreenState();
}

class _HrDashboardScreenState extends State<HrDashboardScreen> {
  final Color _primaryColor = const Color(0xFF003366);

  // --- TRẠNG THÁI CHO HOẠT ĐỘNG & THÔNG BÁO ---
  final List<Map<String, dynamic>> _activities = [];
  int _unreadCount = 0;

  bool _isEmployeeSeeded = false;
  bool _isDeptSeeded = false;
  List<Employee> _cachedEmployees = [];
  List<Department> _cachedDepts = [];

  @override
  void initState() {
    super.initState();
    context.read<DepartmentCubit>().loadDepartments();
    context.read<EmployeeCubit>().loadPage(1);
  }

  // Hàm chuyển đổi thời gian sang dạng "Vừa xong", "10 phút trước"...
  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return "Vừa xong";
    if (diff.inMinutes < 60) return "${diff.inMinutes} phút trước";
    if (diff.inHours < 24) return "${diff.inHours} giờ trước";
    if (diff.inDays < 7) return "${diff.inDays} ngày trước";
    return "${time.day}/${time.month}/${time.year}";
  }

  // Hàm thêm thông báo mới vào danh sách
  void _addActivity(String title, String desc, IconData icon, Color color) {
    setState(() {
      _activities.insert(0, {
        "title": title,
        "desc": desc,
        "timestamp": DateTime.now(),
        "icon": icon,
        "color": color,
      });
      _unreadCount++;
      // Chỉ giữ lại 20 thông báo gần nhất cho nhẹ máy
      if (_activities.length > 20) {
        _activities.removeLast();
      }
    });
  }

  // --- HÀM HIỂN THỊ POPUP THÔNG BÁO ---
  void _showNotificationsDialog() {
    // Reset số đếm chưa đọc khi mở popup
    setState(() {
      _unreadCount = 0;
    });

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
            height: 400,
            child: _activities.isEmpty
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
                    itemCount: _activities.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final act = _activities[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 0,
                          vertical: 12,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: (act['color'] as Color).withOpacity(
                            0.1,
                          ),
                          child: Icon(
                            act['icon'] as IconData,
                            color: act['color'] as Color,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          act['title'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              act['desc'],
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _formatTime(act['timestamp']),
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1000;

    return MultiBlocListener(
      listeners: [
        // --- LẮNG NGHE SỰ THAY ĐỔI CỦA NHÂN VIÊN ---
        BlocListener<EmployeeCubit, EmployeeState>(
          listener: (context, state) {
            if (state is EmployeeLoaded) {
              if (!_isEmployeeSeeded) {
                // Khởi tạo dữ liệu lần đầu (Không phát thông báo)
                if (state.employees.isNotEmpty) {
                  final newest = state.employees.reduce(
                    (curr, next) => curr.id > next.id ? curr : next,
                  );
                  setState(() {
                    _activities.add({
                      "title": "Nhân sự mới nhất",
                      "desc":
                          "Nhân viên ${newest.fullName} vừa gia nhập hệ thống.",
                      "timestamp": DateTime.now().subtract(
                        const Duration(minutes: 5),
                      ),
                      "icon": Icons.person_add,
                      "color": Colors.blue,
                    });
                  });
                }
                _isEmployeeSeeded = true;
                _cachedEmployees = List.from(state.employees);
              } else {
                // So sánh để phát hiện THÊM / SỬA / XÓA
                final newEmps = state.employees;
                final added = newEmps
                    .where((n) => !_cachedEmployees.any((o) => o.id == n.id))
                    .toList();
                final removed = _cachedEmployees
                    .where((o) => !newEmps.any((n) => n.id == o.id))
                    .toList();

                if (added.isNotEmpty) {
                  _addActivity(
                    "Thêm nhân viên mới",
                    "Vừa thêm hồ sơ nhân viên: ${added.first.fullName}",
                    Icons.person_add,
                    Colors.green,
                  );
                } else if (removed.isNotEmpty) {
                  _addActivity(
                    "Xoá nhân viên",
                    "Đã xoá hồ sơ nhân viên: ${removed.first.fullName}",
                    Icons.person_remove,
                    Colors.red,
                  );
                } else {
                  // Kiểm tra xem có ai bị thay đổi thông tin không
                  for (var n in newEmps) {
                    final o = _cachedEmployees.firstWhere(
                      (old) => old.id == n.id,
                      orElse: () => n,
                    );
                    if (n.fullName != o.fullName ||
                        n.position != o.position ||
                        n.departmentId != o.departmentId ||
                        n.groupId != o.groupId) {
                      _addActivity(
                        "Cập nhật hồ sơ",
                        "Đã thay đổi thông tin nhân viên: ${n.fullName}",
                        Icons.manage_accounts,
                        Colors.orange,
                      );
                      break; // Chỉ cần thông báo 1 lần cho đợt cập nhật này
                    }
                  }
                }
                _cachedEmployees = List.from(newEmps);
              }
            }
          },
        ),

        // --- LẮNG NGHE SỰ THAY ĐỔI CỦA PHÒNG BAN ---
        BlocListener<DepartmentCubit, DepartmentState>(
          listener: (context, state) {
            if (state is DepartmentLoaded) {
              if (!_isDeptSeeded) {
                if (state.departments.isNotEmpty) {
                  final newest = state.departments.reduce(
                    (curr, next) => curr.id > next.id ? curr : next,
                  );
                  setState(() {
                    _activities.add({
                      "title": "Phòng ban mới nhất",
                      "desc": "Bộ phận ${newest.name} vừa được thiết lập.",
                      "timestamp": DateTime.now().subtract(
                        const Duration(hours: 1),
                      ),
                      "icon": Icons.domain_add,
                      "color": Colors.purple,
                    });
                  });
                }
                _isDeptSeeded = true;
                _cachedDepts = List.from(state.departments);
              } else {
                // So sánh
                final newDepts = state.departments;
                final added = newDepts
                    .where((n) => !_cachedDepts.any((o) => o.id == n.id))
                    .toList();
                final removed = _cachedDepts
                    .where((o) => !newDepts.any((n) => n.id == o.id))
                    .toList();

                if (added.isNotEmpty) {
                  _addActivity(
                    "Thêm bộ phận mới",
                    "Vừa thiết lập phòng ban: ${added.first.name}",
                    Icons.domain_add,
                    Colors.green,
                  );
                } else if (removed.isNotEmpty) {
                  _addActivity(
                    "Xoá bộ phận",
                    "Đã gỡ bỏ phòng ban: ${removed.first.name}",
                    Icons.domain_disabled,
                    Colors.red,
                  );
                } else {
                  for (var n in newDepts) {
                    final o = _cachedDepts.firstWhere(
                      (old) => old.id == n.id,
                      orElse: () => n,
                    );
                    if (n.name != o.name || n.description != o.description) {
                      _addActivity(
                        "Cập nhật bộ phận",
                        "Thay đổi thông tin phòng: ${n.name}",
                        Icons.edit_note,
                        Colors.orange,
                      );
                      break;
                    }
                  }
                }
                _cachedDepts = List.from(newDepts);
              }
            }
          },
        ),
      ],
      child: Scaffold(
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
              icon: Badge(
                label: Text('$_unreadCount'),
                isLabelVisible: _unreadCount > 0,
                backgroundColor: Colors.redAccent,
                child: const Icon(Icons.notifications_outlined, size: 26),
              ),
              onPressed: _showNotificationsDialog,
              tooltip: "Thông báo",
            ),
            const SizedBox(width: 8),
            const CircleAvatar(
              backgroundColor: Color(0xFF003366),
              child: Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: BlocBuilder<DepartmentCubit, DepartmentState>(
          builder: (context, deptState) {
            return BlocBuilder<EmployeeCubit, EmployeeState>(
              builder: (context, empState) {
                int totalEmployees = 0;
                if (empState is EmployeeLoaded)
                  totalEmployees = empState.totalCount;

                int totalDepartments = 0;
                if (deptState is DepartmentLoaded)
                  totalDepartments = deptState.departments.length;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle("TỔNG QUAN NHÂN SỰ"),
                      const SizedBox(height: 16),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: isMobile ? 2 : (isTablet ? 3 : 4),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: isMobile ? 1.5 : 2.0,
                        children: [
                          _buildKpiCard(
                            title: "Tổng nhân viên",
                            value: empState is EmployeeLoading
                                ? "..."
                                : totalEmployees.toString(),
                            icon: Icons.people_alt,
                            color: Colors.blue,
                          ),
                          _buildKpiCard(
                            title: "Bộ phận",
                            value: deptState is DepartmentLoading
                                ? "..."
                                : totalDepartments.toString(),
                            icon: Icons.apartment,
                            color: Colors.purple,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      _buildSectionTitle("QUẢN LÝ CHUNG"),
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
                            title: "Cơ cấu Tổ chức",
                            subtitle: "Bộ phận, Tổ & Nhân viên",
                            icon: Icons.account_tree,
                            color: Colors.teal,
                            onTap: () => context.go('/organization'),
                          ),
                          _buildFeatureCard(
                            context,
                            title: "Danh sách Nhân viên",
                            subtitle: "Tra cứu hồ sơ toàn bộ",
                            icon: Icons.badge,
                            color: Colors.indigo,
                            onTap: () => context.go('/employees'),
                          ),
                          _buildFeatureCard(
                            context,
                            title: "Lịch làm việc (Ca)",
                            subtitle: "Phân ca, Xếp lịch dệt",
                            icon: Icons.calendar_month,
                            color: Colors.blueGrey,
                            onTap: () => context.go('/schedules'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // --- DANH SÁCH HOẠT ĐỘNG GẦN ĐÂY ---
                      _buildSectionTitle("HOẠT ĐỘNG CẬP NHẬT"),
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
                        child: _activities.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(32.0),
                                child: Center(
                                  child: Text(
                                    "Hệ thống chưa ghi nhận hoạt động nào.",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _activities.length > 5
                                    ? 5
                                    : _activities
                                          .length, // Hiển thị tối đa 5 ở màn hình chính
                                separatorBuilder: (context, index) => Divider(
                                  height: 1,
                                  color: Colors.grey.shade100,
                                ),
                                itemBuilder: (context, index) {
                                  final act = _activities[index];
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor: (act['color'] as Color)
                                          .withOpacity(0.1),
                                      child: Icon(
                                        act['icon'] as IconData,
                                        color: act['color'] as Color,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      act['title'],
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
                                          Expanded(
                                            child: Text(
                                              "${_formatTime(act['timestamp'])} - ${act['desc']}",
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 12,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    trailing: isMobile
                                        ? null
                                        : OutlinedButton(
                                            onPressed: () {
                                              if (act['icon'] ==
                                                      Icons.domain_add ||
                                                  act['icon'] ==
                                                      Icons.edit_note) {
                                                context.go('/organization');
                                              } else {
                                                context.go('/employees');
                                              }
                                            },
                                            style: OutlinedButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
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
                );
              },
            );
          },
        ),
      ),
    );
  }

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
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade600,
            letterSpacing: 1.2,
          ),
        ),
      ],
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
