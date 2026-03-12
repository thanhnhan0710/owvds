import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:owvds/core/widgets/responsive_layout.dart';
import 'package:owvds/features/hr/employee/domain/employee_model.dart';
import 'package:owvds/features/hr/employee/presentation/bloc/employee_cubit.dart';
import 'package:owvds/l10n/app_localizations.dart';

import '../../../../../core/network/websocket_service.dart'; // [MỚI] Import WebSocket
import '../../domain/user_model.dart';
import '../bloc/user_cubit.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce; // [MỚI] Timer cho việc tìm kiếm

  final Color _primaryColor = const Color(0xFF003366);
  final Color _bgLight = const Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    context.read<UserCubit>().loadUsers();
    context.read<EmployeeCubit>().loadEmployees();

    // [MỚI] Kết nối và lắng nghe WebSocket
    WebSocketService().connect();
    WebSocketService().addListener(_onWebSocketMessage);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();

    // [MỚI] Hủy lắng nghe WebSocket
    WebSocketService().removeListener(_onWebSocketMessage);
    super.dispose();
  }

  // [MỚI] Hàm xử lý WebSocket
  void _onWebSocketMessage(String message) {
    if (message == "REFRESH_USERS") {
      debugPrint("WebSocket: Làm mới danh sách Người dùng.");
      if (mounted) {
        // Tôn trọng từ khóa tìm kiếm hiện tại nếu có
        if (_searchController.text.isNotEmpty) {
          context.read<UserCubit>().searchUsers(_searchController.text);
        } else {
          context.read<UserCubit>().loadUsers();
        }
      }
    }
  }

  // [MỚI] Hàm tìm kiếm có delay (Debounce)
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().isEmpty) {
        context.read<UserCubit>().loadUsers();
      } else {
        context.read<UserCubit>().searchUsers(query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: _bgLight,
      body: SelectionArea(
        child: BlocConsumer<UserCubit, UserState>(
          listener: (context, state) {
            if (state is UserError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- HEADER ---
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.people_alt,
                              color: _primaryColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            l10n.userManagementTitle,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (isDesktop)
                            ElevatedButton.icon(
                              onPressed: () =>
                                  _showEditDialog(context, null, l10n),
                              icon: const Icon(Icons.add, size: 18),
                              label: Text(l10n.addUser.toUpperCase()),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          color: _bgLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged, // Gọi hàm debounce
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText: l10n.searchUser,
                            prefixIcon: const Icon(Icons.search),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      color: Colors.grey,
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      _onSearchChanged('');
                                      setState(() {});
                                    },
                                  )
                                : null,
                          ),
                          onSubmitted: (val) => _onSearchChanged(val),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // --- CONTENT ---
                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (state is UserLoading) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: _primaryColor,
                          ),
                        );
                      }
                      if (state is UserLoaded) {
                        if (state.users.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_off_outlined,
                                  size: 60,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  l10n.noUserFound,
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          );
                        }
                        return isDesktop
                            ? _buildDesktopTable(state.users, l10n)
                            : _buildMobileList(state.users, l10n);
                      }
                      return const SizedBox();
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: !isDesktop
          ? FloatingActionButton(
              backgroundColor: _primaryColor,
              onPressed: () => _showEditDialog(context, null, l10n),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  // --- DESKTOP TABLE ---
  Widget _buildDesktopTable(List<User> users, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(
                    const Color(0xFFF9FAFB),
                  ),
                  dataRowMinHeight: 65,
                  dataRowMaxHeight: 85,
                  columnSpacing: 24,
                  columns: [
                    DataColumn(
                      label: Text(
                        l10n.username.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        l10n.phone.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        l10n.employee.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        l10n.role.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        l10n.status.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        l10n.lastLogin.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        l10n.actions.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  rows: users.map((user) {
                    return DataRow(
                      cells: [
                        // 1. User Info
                        DataCell(
                          Container(
                            constraints: const BoxConstraints(maxWidth: 250),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.blue.shade50,
                                  child: Text(
                                    user.fullName.isNotEmpty
                                        ? user.fullName[0].toUpperCase()
                                        : 'U',
                                    style: TextStyle(color: _primaryColor),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        user.fullName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        user.email,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // 2. Phone
                        DataCell(
                          Text(
                            user.phoneNumber.isEmpty ? "-" : user.phoneNumber,
                          ),
                        ),

                        // 3. Employee Linked
                        DataCell(
                          user.employeeName != null
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      user.employeeName!,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  l10n.notLinked,
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                        ),

                        // 4. Role
                        DataCell(
                          _buildRoleBadge(user.role, user.isSuperuser, l10n),
                        ),
                        // 5. Status
                        DataCell(_buildStatusBadge(user.isActive, l10n)),
                        // 6. Last Login
                        DataCell(
                          Text(
                            user.lastLogin != null
                                ? user.lastLogin!.split('T')[0]
                                : l10n.never,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        // 7. Actions
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.grey,
                                ),
                                onPressed: () =>
                                    _showEditDialog(context, user, l10n),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () =>
                                    _confirmDelete(context, user, l10n),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // --- MOBILE LIST ---
  Widget _buildMobileList(List<User> users, AppLocalizations l10n) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue.shade50,
                      child: Text(
                        user.fullName.isNotEmpty
                            ? user.fullName[0].toUpperCase()
                            : 'U',
                        style: TextStyle(color: _primaryColor),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Row(
                            children: [
                              _buildRoleBadge(
                                user.role,
                                user.isSuperuser,
                                l10n,
                              ),
                              const SizedBox(width: 8),
                              _buildStatusBadge(user.isActive, l10n),
                            ],
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton(
                      icon: Icon(Icons.more_vert, color: Colors.grey.shade400),
                      onSelected: (val) {
                        if (val == 'edit') _showEditDialog(context, user, l10n);
                        if (val == 'delete') {
                          _confirmDelete(context, user, l10n);
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(Icons.edit, size: 18),
                              const SizedBox(width: 8),
                              Text(l10n.editUser),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.delete,
                                size: 18,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.delete,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 24),
                _buildInfoRow(Icons.email_outlined, l10n.email, user.email),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.phone_outlined,
                  l10n.phone,
                  user.phoneNumber.isEmpty ? "N/A" : user.phoneNumber,
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.badge_outlined,
                  l10n.employee,
                  user.employeeName ?? l10n.notLinked,
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.access_time,
                  l10n.lastLogin,
                  user.lastLogin != null
                      ? user.lastLogin!.replaceAll('T', ' ').split('.')[0]
                      : l10n.never,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleBadge(String role, bool isSuper, AppLocalizations l10n) {
    Color color = Colors.blue;
    if (role == 'admin' || isSuper) color = Colors.purple;
    if (role == 'manager') color = Colors.orange;
    if (role == 'worker') color = Colors.teal;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isSuper ? l10n.superuser : role.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isActive ? l10n.active.toUpperCase() : l10n.inactive.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          color: isActive ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // --- DIALOG ---
  void _showEditDialog(
    BuildContext context,
    User? user,
    AppLocalizations l10n,
  ) {
    final isEdit = user != null;
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    final nameCtrl = TextEditingController(text: user?.fullName ?? '');
    final phoneCtrl = TextEditingController(text: user?.phoneNumber ?? '');
    final passCtrl = TextEditingController();

    String selectedRole = user?.role ?? 'staff';
    bool isActive = user?.isActive ?? true;
    bool isSuperuser = user?.isSuperuser ?? false;

    // Biến để lưu ID nhân viên được chọn
    int? selectedEmployeeId = user?.employeeId;

    final formKey = GlobalKey<FormState>();

    // Refresh lại list employee để đảm bảo có data mới nhất
    context.read<EmployeeCubit>().loadEmployees();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(isEdit ? l10n.editUser : l10n.addNewUser),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Basic Info
                      TextFormField(
                        controller: emailCtrl,
                        decoration: InputDecoration(labelText: l10n.email),
                        validator: (v) =>
                            v!.isEmpty ? l10n.errorRequired : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nameCtrl,
                        decoration: InputDecoration(labelText: l10n.fullName),
                        validator: (v) =>
                            v!.isEmpty ? l10n.errorRequired : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneCtrl,
                        decoration: InputDecoration(labelText: l10n.phone),
                      ),
                      const SizedBox(height: 12),

                      // EMPLOYEE DROPDOWN
                      BlocBuilder<EmployeeCubit, EmployeeState>(
                        builder: (context, empState) {
                          if (empState is EmployeeLoading) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: LinearProgressIndicator(),
                              ),
                            );
                          }

                          List<Employee> employees = [];
                          if (empState is EmployeeLoaded) {
                            employees = empState.employees;
                          }

                          return DropdownButtonFormField<int?>(
                            value: selectedEmployeeId,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: l10n.linkToEmployee,
                              helperText: l10n.linkEmployeeHelper,
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                            ),
                            items: [
                              DropdownMenuItem<int?>(
                                value: null,
                                child: Text(
                                  l10n.noEmployeeLinkedOption,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ),
                              ...employees.map((emp) {
                                return DropdownMenuItem<int?>(
                                  value: emp.id,
                                  child: Text(
                                    "${emp.fullName} (ID: ${emp.id})",
                                  ),
                                );
                              }),
                            ],
                            onChanged: (val) {
                              setState(() {
                                selectedEmployeeId = val;
                                // Tự động điền Tên nếu người dùng chưa nhập gì
                                if (val != null && nameCtrl.text.isEmpty) {
                                  final selectedEmp = employees.firstWhere(
                                    (e) => e.id == val,
                                  );
                                  nameCtrl.text = selectedEmp.fullName;
                                  emailCtrl.text = selectedEmp.email;
                                  phoneCtrl.text = selectedEmp.phone;
                                }
                              });
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 12),

                      // Password Logic
                      if (!isEdit) ...[
                        TextFormField(
                          controller: passCtrl,
                          decoration: InputDecoration(labelText: l10n.password),
                          obscureText: true,
                          validator: (v) =>
                              v!.isEmpty ? l10n.passwordRequiredNew : null,
                        ),
                        const SizedBox(height: 12),
                      ] else ...[
                        TextFormField(
                          controller: passCtrl,
                          decoration: InputDecoration(
                            labelText: l10n.newPasswordPlaceholder,
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Role & Settings
                      DropdownButtonFormField<String>(
                        value: selectedRole.toLowerCase(),
                        decoration: InputDecoration(labelText: l10n.role),
                        items: ['staff', 'manager', 'admin', 'worker']
                            .map(
                              (r) => DropdownMenuItem(
                                value: r,
                                child: Text(r.toUpperCase()),
                              ),
                            )
                            .toList(),
                        onChanged: (val) => setState(() => selectedRole = val!),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: Text(l10n.isActiveSwitch),
                        value: isActive,
                        onChanged: (v) => setState(() => isActive = v),
                      ),
                      SwitchListTile(
                        title: Text(l10n.isSuperuserSwitch),
                        value: isSuperuser,
                        onChanged: (v) => setState(() => isSuperuser = v),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    final newUser = User(
                      id: user?.id ?? 0,
                      email: emailCtrl.text,
                      fullName: nameCtrl.text,
                      phoneNumber: phoneCtrl.text,
                      role: selectedRole,
                      isActive: isActive,
                      isSuperuser: isSuperuser,
                      employeeId: selectedEmployeeId,
                    );

                    if (isEdit) {
                      context.read<UserCubit>().updateUser(
                        newUser,
                        newPassword: passCtrl.text.isEmpty
                            ? null
                            : passCtrl.text,
                      );
                    } else {
                      context.read<UserCubit>().createUser(
                        newUser,
                        passCtrl.text,
                      );
                    }
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          user == null
                              ? l10n.successAdded
                              : l10n.successUpdated,
                        ),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                child: Text(l10n.save),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, User user, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.confirmDeleteTitle),
        content: Text(l10n.confirmDeleteUserMsg(user.fullName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              context.read<UserCubit>().deleteUser(user.id);
              Navigator.pop(ctx);
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}
