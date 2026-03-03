import 'dart:async';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

// --- IMPORTS ---
import '../../../../../core/widgets/responsive_layout.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/constants/api_endpoints.dart';
import '../../../../../core/network/websocket_service.dart';
import '../../../department/presentation/bloc/department_cubit.dart';
import '../../domain/employee_model.dart';
import '../bloc/employee_cubit.dart';

class EmployeeDepartmentScreen extends StatefulWidget {
  final int departmentId;

  const EmployeeDepartmentScreen({super.key, required this.departmentId});

  @override
  State<EmployeeDepartmentScreen> createState() =>
      _EmployeeDepartmentScreenState();
}

class _EmployeeDepartmentScreenState extends State<EmployeeDepartmentScreen> {
  final _searchController = TextEditingController();
  final Color _primaryColor = const Color(0xFF003366);
  final Color _bgLight = const Color(0xFFF5F7FA);

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // 1. Load nhân viên theo ID phòng ban (Cubit đã xử lý loadPage(1) bên trong)
    context.read<EmployeeCubit>().loadEmployeesByDepartment(
      widget.departmentId,
    );
    // 2. Load danh sách phòng ban để hiển thị tên
    context.read<DepartmentCubit>().loadDepartments();

    // 3. Kết nối và lắng nghe WebSocket
    WebSocketService().connect();
    WebSocketService().addListener(_onWebSocketMessage);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    WebSocketService().removeListener(_onWebSocketMessage);
    super.dispose();
  }

  // --- WEBSOCKET HANDLER ---
  void _onWebSocketMessage(String message) {
    if (message == "REFRESH_EMPLOYEES") {
      if (mounted) {
        final state = context.read<EmployeeCubit>().state;
        int page = (state is EmployeeLoaded) ? state.currentPage : 1;
        context.read<EmployeeCubit>().loadPage(page);
      }
    }
  }

  // --- SEARCH HANDLER ---
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().isEmpty) {
        context.read<EmployeeCubit>().loadEmployeesByDepartment(
          widget.departmentId,
        );
      } else {
        context.read<EmployeeCubit>().searchEmployees(query);
      }
    });
  }

  Future<void> _launchAction(String scheme, String path) async {
    if (path.isEmpty) return;
    final Uri launchUri = Uri(scheme: scheme, path: path);
    try {
      await launchUrl(launchUri);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Cannot launch action')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        title: BlocBuilder<DepartmentCubit, DepartmentState>(
          builder: (context, state) {
            String deptName = "Department Employees";
            if (state is DepartmentLoaded) {
              final dept = state.departments
                  .where((d) => d.id == widget.departmentId)
                  .firstOrNull;
              if (dept != null) deptName = dept.name;
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deptName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (deptName != "Department Employees")
                  const Text(
                    "Employee List",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
              ],
            );
          },
        ),
        backgroundColor: _primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              context.pop();
            } else {
              context.go('/departments');
            }
          },
        ),
        actions: [
          if (!isDesktop)
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: () => _showEditDialog(context, null, l10n),
            ),
        ],
      ),
      body: Column(
        children: [
          // --- SEARCH BAR ---
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                if (isDesktop) ...[
                  BlocBuilder<EmployeeCubit, EmployeeState>(
                    builder: (context, state) {
                      int count = (state is EmployeeLoaded)
                          ? state.employees.length
                          : 0;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Total: $count",
                          style: TextStyle(
                            color: Colors.blue.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: _bgLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: l10n.searchEmployee,
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 13,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey.shade400,
                          size: 18,
                        ),
                        contentPadding: const EdgeInsets.only(top: 2),
                        border: InputBorder.none,
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                  setState(() {});
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                if (isDesktop) ...[
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showEditDialog(context, null, l10n),
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(l10n.addEmployee.toUpperCase()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(height: 1, color: Colors.grey.shade200),

          // --- LIST CONTENT & PAGINATION ---
          Expanded(
            child: BlocBuilder<EmployeeCubit, EmployeeState>(
              builder: (context, state) {
                if (state is EmployeeLoading) {
                  return Center(
                    child: CircularProgressIndicator(color: _primaryColor),
                  );
                } else if (state is EmployeeError) {
                  return Center(
                    child: Text(
                      "Error: ${state.message}",
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                } else if (state is EmployeeLoaded) {
                  if (state.employees.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.group_off,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No employees found",
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: isDesktop
                            ? _buildDesktopGrid(context, state.employees, l10n)
                            : _buildMobileList(context, state.employees, l10n),
                      ),
                      _buildPagination(
                        context,
                        state.currentPage,
                        state.hasMore,
                      ),
                    ],
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(BuildContext context, int currentPage, bool hasMore) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            "Trang $currentPage",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 16),
          OutlinedButton(
            onPressed: currentPage > 1
                ? () => context.read<EmployeeCubit>().loadPage(currentPage - 1)
                : null,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(12),
              minimumSize: Size.zero,
            ),
            child: const Icon(Icons.chevron_left, size: 20),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: hasMore
                ? () => context.read<EmployeeCubit>().loadPage(currentPage + 1)
                : null,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(12),
              minimumSize: Size.zero,
            ),
            child: const Icon(Icons.chevron_right, size: 20),
          ),
        ],
      ),
    );
  }

  // --- DESKTOP GRID ---
  Widget _buildDesktopGrid(
    BuildContext context,
    List<Employee> employees,
    AppLocalizations l10n,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      const Color(0xFFF9FAFB),
                    ),
                    horizontalMargin: 24,
                    columnSpacing: 30,
                    dataRowMinHeight: 72,
                    dataRowMaxHeight: 72,
                    columns: [
                      DataColumn(
                        label: Text(
                          l10n.fullName.toUpperCase(),
                          style: _headerStyle,
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          l10n.position.toUpperCase(),
                          style: _headerStyle,
                        ),
                      ),
                      DataColumn(
                        label: Text("LIÊN HỆ", style: _headerStyle),
                      ), // [CẬP NHẬT]
                      DataColumn(
                        label: Text(
                          l10n.actions.toUpperCase(),
                          style: _headerStyle,
                        ),
                      ),
                    ],
                    rows: employees.map((emp) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Row(
                              children: [
                                _buildAvatar(emp.avatarUrl, emp.fullName, 20),
                                const SizedBox(width: 16),
                                Text(
                                  emp.fullName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            Text(
                              emp.position,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          // [MỚI] Hiển thị rõ cả text và icon
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                InkWell(
                                  onTap: () =>
                                      _launchAction('mailto', emp.email),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.email_outlined,
                                        size: 14,
                                        color: Colors.blue.shade600,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        emp.email.isNotEmpty
                                            ? emp.email
                                            : 'Chưa có Email',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: emp.email.isNotEmpty
                                              ? Colors.blue.shade700
                                              : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: () => _launchAction('tel', emp.phone),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.phone_outlined,
                                        size: 14,
                                        color: Colors.green.shade600,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        emp.phone.isNotEmpty
                                            ? emp.phone
                                            : 'Chưa có SĐT',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: emp.phone.isNotEmpty
                                              ? Colors.green.shade700
                                              : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_note,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () =>
                                      _showEditDialog(context, emp, l10n),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () =>
                                      _confirmDelete(context, emp, l10n),
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
      ),
    );
  }

  TextStyle get _headerStyle => TextStyle(
    color: Colors.grey.shade600,
    fontWeight: FontWeight.bold,
    fontSize: 12,
    letterSpacing: 0.5,
  );

  // --- MOBILE LIST ---
  Widget _buildMobileList(
    BuildContext context,
    List<Employee> employees,
    AppLocalizations l10n,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: employees.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final emp = employees[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAvatar(emp.avatarUrl, emp.fullName, 24),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            emp.fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            emp.position,
                            style: TextStyle(
                              color: _primaryColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton(
                      icon: Icon(Icons.more_vert, color: Colors.grey.shade400),
                      onSelected: (val) {
                        if (val == 'edit') _showEditDialog(context, emp, l10n);
                        if (val == 'delete') _confirmDelete(context, emp, l10n);
                      },
                      itemBuilder: (ctx) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(Icons.edit, size: 18),
                              const SizedBox(width: 8),
                              Text(l10n.editEmployee),
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
                              Text(l10n.deleteEmployee),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(height: 1, color: Colors.grey.shade100),
              ),
              // [MỚI] Hiển thị liên hệ dạng cột trên Mobile
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => _launchAction('mailto', emp.email),
                      child: _buildContactRow(
                        Icons.email,
                        emp.email,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _launchAction('tel', emp.phone),
                      child: _buildContactRow(
                        Icons.phone,
                        emp.phone,
                        Colors.green,
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
  }

  // --- HELPER WIDGETS ---
  Widget _buildAvatar(String url, String name, double radius) {
    final fullUrl = ApiEndpoints.getImageUrl(url);
    String initials = "?";
    if (fullUrl.isEmpty && name.isNotEmpty) {
      List<String> parts = name.trim().split(' ');
      if (parts.length >= 2) {
        initials = "${parts.first[0]}${parts.last[0]}".toUpperCase();
      } else if (parts.isNotEmpty) {
        initials = parts[0][0].toUpperCase();
      }
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: _primaryColor.withOpacity(0.1),
      backgroundImage: fullUrl.isNotEmpty ? NetworkImage(fullUrl) : null,
      child: fullUrl.isEmpty
          ? Text(
              initials,
              style: TextStyle(
                color: _primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.8,
              ),
            )
          : null,
    );
  }

  Widget _buildContactRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color.withOpacity(0.7)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text.isNotEmpty ? text : "Chưa cập nhật",
            style: TextStyle(
              fontSize: 13,
              color: text.isNotEmpty ? color : Colors.grey,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // --- DIALOG THÊM / SỬA (AUTO SELECT DEPT) ---
  void _showEditDialog(
    BuildContext context,
    Employee? emp,
    AppLocalizations l10n,
  ) {
    final fullNameCtrl = TextEditingController(text: emp?.fullName ?? '');
    final emailCtrl = TextEditingController(text: emp?.email ?? '');
    final phoneCtrl = TextEditingController(text: emp?.phone ?? '');
    final positionCtrl = TextEditingController(text: emp?.position ?? '');
    final noteCtrl = TextEditingController(text: emp?.note ?? '');

    int? selectedDeptId = emp?.departmentId ?? widget.departmentId;

    PlatformFile? pickedFile;
    Uint8List? pickedBytes;

    final employeeCubit = context.read<EmployeeCubit>();
    final departmentCubit = context.read<DepartmentCubit>();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: employeeCubit),
          BlocProvider.value(value: departmentCubit),
        ],
        child: StatefulBuilder(
          builder: (context, setStateDialog) {
            Future<void> pickImage() async {
              try {
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  type: FileType.image,
                  withData: true,
                );
                if (result != null) {
                  setStateDialog(() {
                    pickedFile = result.files.first;
                    pickedBytes = result.files.first.bytes;
                  });
                }
              } catch (e) {
                debugPrint("Error picking file: $e");
              }
            }

            ImageProvider? imageProvider;
            if (pickedBytes != null) {
              imageProvider = MemoryImage(pickedBytes!);
            } else if (emp != null && emp.avatarUrl.isNotEmpty) {
              imageProvider = NetworkImage(
                ApiEndpoints.getImageUrl(emp.avatarUrl),
              );
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 10,
              ),
              title: Text(
                emp == null ? l10n.addEmployee : l10n.editEmployee,
                style: TextStyle(
                  color: _primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Form(
                key: formKey,
                child: SizedBox(
                  width: 500,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: pickImage,
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: imageProvider,
                            child: imageProvider == null
                                ? const Icon(
                                    Icons.camera_alt,
                                    color: Colors.grey,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: fullNameCtrl,
                          decoration: _inputDeco(l10n.fullName),
                          validator: (v) => v!.isEmpty ? "Required" : null,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: emailCtrl,
                          decoration: _inputDeco("${l10n.email} *"),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return "Required";
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: phoneCtrl,
                          decoration: _inputDeco(l10n.phone),
                          keyboardType: TextInputType.phone,
                        ),

                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          value: selectedDeptId,
                          decoration: _inputDeco(l10n.department),
                          items: (departmentCubit.state is DepartmentLoaded)
                              ? (departmentCubit.state as DepartmentLoaded)
                                    .departments
                                    .map(
                                      (d) => DropdownMenuItem(
                                        value: d.id,
                                        child: Text(d.name),
                                      ),
                                    )
                                    .toList()
                              : [],
                          onChanged: (val) =>
                              setStateDialog(() => selectedDeptId = val),
                          validator: (v) => v == null ? "Required" : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: positionCtrl,
                          decoration: _inputDeco(l10n.position),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: noteCtrl,
                          decoration: _inputDeco(l10n.note),
                          maxLines: 2,
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
                    if (formKey.currentState!.validate() &&
                        selectedDeptId != null) {
                      final newEmp = Employee(
                        id: emp?.id ?? 0,
                        fullName: fullNameCtrl.text,
                        email: emailCtrl.text,
                        phone: phoneCtrl.text,
                        address: emp?.address ?? '',
                        position: positionCtrl.text,
                        departmentId: selectedDeptId!,
                        note: noteCtrl.text,
                        avatarUrl: emp?.avatarUrl ?? '',
                      );

                      context.read<EmployeeCubit>().saveEmployee(
                        employee: newEmp,
                        imageFile: pickedFile,
                        isEdit: emp != null,
                      );
                      Navigator.pop(ctx);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(l10n.save),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  void _confirmDelete(
    BuildContext context,
    Employee emp,
    AppLocalizations l10n,
  ) {
    final employeeCubit = context.read<EmployeeCubit>();

    showDialog(
      context: context,
      builder: (ctx) => BlocProvider.value(
        value: employeeCubit,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.red),
              const SizedBox(width: 8),
              Text(l10n.deleteEmployee),
            ],
          ),
          content: Text(l10n.confirmDeleteEmployee(emp.fullName)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<EmployeeCubit>().deleteEmployee(emp.id);
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(l10n.deleteEmployee),
            ),
          ],
        ),
      ),
    );
  }
}
