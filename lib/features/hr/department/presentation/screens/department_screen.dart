import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/responsive_layout.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/network/websocket_service.dart'; // Import WebSocket

import '../../domain/department_model.dart';
import '../bloc/department_cubit.dart';

class DepartmentScreen extends StatefulWidget {
  const DepartmentScreen({super.key});

  @override
  State<DepartmentScreen> createState() => _DepartmentScreenState();
}

class _DepartmentScreenState extends State<DepartmentScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  final Color _primaryColor = const Color(0xFF003366);
  final Color _accentColor = const Color(0xFF0055AA);

  @override
  void initState() {
    super.initState();
    // 1. Load data ban đầu
    context.read<DepartmentCubit>().loadDepartments();

    // 2. Kết nối và lắng nghe WebSocket
    WebSocketService().connect();
    WebSocketService().addListener(_onWebSocketMessage);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();

    // 3. Hủy lắng nghe
    WebSocketService().removeListener(_onWebSocketMessage);
    super.dispose();
  }

  // --- WEBSOCKET HANDLER ---
  void _onWebSocketMessage(String message) {
    if (message == "REFRESH_DEPARTMENTS") {
      debugPrint("WebSocket: Cập nhật lại danh sách Bộ phận.");
      if (mounted) {
        context.read<DepartmentCubit>().loadDepartments();
      }
    }
  }

  // --- SEARCH HANDLER ---
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().isEmpty) {
        context.read<DepartmentCubit>().loadDepartments();
      } else {
        context.read<DepartmentCubit>().searchDepartments(query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Nền xám nhạt chuyên nghiệp
      body: BlocBuilder<DepartmentCubit, DepartmentState>(
        builder: (context, state) {
          int totalDepts = 0;
          if (state is DepartmentLoaded) {
            totalDepts = state.departments.length;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- HEADER SECTION ---
              Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      offset: const Offset(0, 2),
                      blurRadius: 10,
                    )
                  ],
                ),
                child: Column(
                  children: [
                    // Title Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.domain,
                                  color: _primaryColor, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.departmentTitle,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: _primaryColor,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Human Resources Structure",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (isDesktop)
                          ElevatedButton.icon(
                            onPressed: () =>
                                _showEditDialog(context, null, l10n),
                            icon:
                                const Icon(Icons.add_circle_outline, size: 18),
                            label: Text(l10n.addDept.toUpperCase()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 18),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              textStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Stats & Search Row
                    Row(
                      children: [
                        if (isDesktop) ...[
                          _buildStatBadge(
                              Icons.grid_view_rounded,
                              l10n.totalDepartments,
                              "$totalDepts",
                              Colors.blue),
                          const SizedBox(width: 16),
                          _buildStatBadge(Icons.check_circle_outline,
                              l10n.status, l10n.active, Colors.green),
                          const Spacer(),
                        ],

                        // Search Bar
                        Expanded(
                          flex: isDesktop ? 0 : 1,
                          child: Container(
                            width: isDesktop ? 350 : double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.grey.shade100,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2))
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              textInputAction: TextInputAction.search,
                              onChanged: _onSearchChanged,
                              decoration: InputDecoration(
                                hintText: l10n.searchDept,
                                hintStyle: TextStyle(
                                    color: Colors.grey.shade400, fontSize: 14),
                                prefixIcon: Icon(Icons.search,
                                    color: Colors.grey.shade400),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear,
                                            color: Colors.grey, size: 18),
                                        onPressed: () {
                                          _searchController.clear();
                                          _onSearchChanged('');
                                          setState(() {});
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                              ),
                              onSubmitted: (value) {
                                context
                                    .read<DepartmentCubit>()
                                    .searchDepartments(value);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // --- CONTENT SECTION ---
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Builder(
                    builder: (context) {
                      if (state is DepartmentLoading) {
                        return Center(
                            child: CircularProgressIndicator(
                                color: _primaryColor));
                      } else if (state is DepartmentError) {
                        return _buildErrorState(state.message);
                      } else if (state is DepartmentLoaded) {
                        if (state.departments.isEmpty) {
                          return _buildEmptyState();
                        }
                        return isDesktop
                            ? _buildDesktopTable(
                                context, state.departments, l10n)
                            : _buildMobileListView(
                                context, state.departments, l10n);
                      }
                      return const SizedBox();
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: !isDesktop
          ? FloatingActionButton(
              backgroundColor: _accentColor,
              elevation: 4,
              onPressed: () => _showEditDialog(context, null, l10n),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  // --- DESKTOP TABLE VIEW ---
  Widget _buildDesktopTable(BuildContext context, List<Department> departments,
      AppLocalizations l10n) {
    return SingleChildScrollView(
      // ignore: sized_box_for_whitespace
      child: Container(
        width: double.infinity,
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    headingRowColor:
                        WidgetStateProperty.all(const Color(0xFFF9FAFB)),
                    headingRowHeight: 56,
                    dataRowMinHeight: 64,
                    dataRowMaxHeight: 64,
                    horizontalMargin: 32,
                    columnSpacing: 40,
                    columns: [
                      DataColumn(
                          label: Text(l10n.deptName.toUpperCase(),
                              style: _headerStyle)),
                      DataColumn(
                          label: Text(l10n.deptDesc.toUpperCase(),
                              style: _headerStyle)),
                      DataColumn(
                          label: Text(l10n.members.toUpperCase(),
                              style: _headerStyle)),
                      DataColumn(
                          label: Text(l10n.actions.toUpperCase(),
                              style: _headerStyle)),
                    ],
                    rows: departments.asMap().entries.map((entry) {
                      final index = entry.key;
                      final dept = entry.value;
                      final color = WidgetStateProperty.all(
                        index % 2 == 0
                            ? Colors.white
                            : const Color(0xFFF9FAFB).withOpacity(0.5),
                      );

                      return DataRow(
                        color: color,
                        cells: [
                          DataCell(Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: _getRandomColor(dept.name)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  dept.name.substring(0, 1).toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _getRandomColor(dept.name),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(dept.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                      fontSize: 14)),
                            ],
                          )),
                          DataCell(
                            Text(
                              dept.description,
                              style: TextStyle(
                                  color: Colors.grey.shade600, height: 1.4),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DataCell(
                            _buildActionButton(Icons.people_alt_outlined,
                                Colors.teal, "View Employees", () {
                              context.go('/employees?departmentId=${dept.id}');
                            }),
                          ),
                          DataCell(Row(
                            children: [
                              _buildActionButton(
                                  Icons.edit_outlined,
                                  Colors.blue,
                                  "Edit",
                                  () => _showEditDialog(context, dept, l10n)),
                              const SizedBox(width: 12),
                              _buildActionButton(
                                  Icons.delete_outline,
                                  Colors.red,
                                  "Delete",
                                  () => _confirmDelete(context, dept, l10n)),
                            ],
                          )),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  TextStyle get _headerStyle => TextStyle(
      color: Colors.grey.shade600,
      fontWeight: FontWeight.bold,
      fontSize: 12,
      letterSpacing: 0.8);

  Widget _buildActionButton(
      IconData icon, Color color, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  // --- MOBILE LIST VIEW ---
  Widget _buildMobileListView(BuildContext context,
      List<Department> departments, AppLocalizations l10n) {
    return ListView.separated(
      itemCount: departments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final dept = departments[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _getRandomColor(dept.name).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          dept.name.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _getRandomColor(dept.name),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dept.name,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87)),
                            const SizedBox(height: 4),
                            Text(
                              dept.description,
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey.shade600),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMobileActionButton(
                        icon: Icons.people_alt_outlined,
                        label: "Employees",
                        color: Colors.teal,
                        onTap: () =>
                            context.go('/employees?departmentId=${dept.id}'),
                      ),
                      _buildMobileActionButton(
                        icon: Icons.edit_outlined,
                        label: l10n.editDept,
                        color: Colors.blue,
                        onTap: () => _showEditDialog(context, dept, l10n),
                      ),
                      _buildMobileActionButton(
                        icon: Icons.delete_outline,
                        label: l10n.deleteDept,
                        color: Colors.red,
                        onTap: () => _confirmDelete(context, dept, l10n),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileActionButton(
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Color _getRandomColor(String seed) {
    final colors = [
      Colors.blue.shade700,
      Colors.orange.shade700,
      Colors.teal.shade700,
      Colors.purple.shade700,
      Colors.indigo.shade700,
      Colors.pink.shade700,
    ];
    return colors[seed.hashCode.abs() % colors.length];
  }

  Widget _buildStatBadge(
      IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
              Text(value,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.grey.shade100, shape: BoxShape.circle),
            child: Icon(Icons.folder_off_outlined,
                size: 48, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          Text("No departments found",
              style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
              onPressed: () =>
                  context.read<DepartmentCubit>().loadDepartments(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text("Reload"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                elevation: 1,
              ))
        ],
      ),
    );
  }

  void _showEditDialog(
      BuildContext context, Department? department, AppLocalizations l10n) {
    final nameController = TextEditingController(text: department?.name ?? '');
    final descController =
        TextEditingController(text: department?.description ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.all(24),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        actionsPadding: const EdgeInsets.all(24),
        title: Text(
          department == null ? l10n.addDept : l10n.editDept,
          style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: l10n.deptName,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300)),
                  ),
                  validator: (v) => v!.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: l10n.deptDesc,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300)),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: Colors.grey.shade600),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final newDept = Department(
                  id: department?.id ?? 0,
                  name: nameController.text,
                  description: descController.text,
                );

                if (department == null) {
                  context.read<DepartmentCubit>().addDepartment(newDept);
                } else {
                  context.read<DepartmentCubit>().updateDepartment(newDept);
                }
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(department == null
                      ? l10n.successAdded
                      : l10n.successUpdated),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.green,
                ));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, Department dept, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
            const SizedBox(width: 10),
            Text(l10n.deleteDept),
          ],
        ),
        content: Text(l10n.confirmDelete(dept.name),
            style: TextStyle(color: Colors.grey.shade800)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              context.read<DepartmentCubit>().deleteDepartment(dept.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(l10n.successDeleted),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.redAccent,
              ));
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0),
            child: Text(l10n.deleteDept),
          ),
        ],
      ),
    );
  }
}
