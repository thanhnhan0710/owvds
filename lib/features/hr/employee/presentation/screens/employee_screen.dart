import 'dart:async';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

// --- IMPORTS ---
import '../../../../../core/widgets/responsive_layout.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/constants/api_endpoints.dart';
import '../../../../../core/network/websocket_service.dart';
import '../../../department/presentation/bloc/department_cubit.dart';
import '../../../employee_group/presentation/bloc/employee_group_cubit.dart'; // [MỚI] Import Cubit Tổ
import '../../domain/employee_model.dart';
import '../bloc/employee_cubit.dart';

class EmployeeScreen extends StatefulWidget {
  const EmployeeScreen({super.key});

  @override
  State<EmployeeScreen> createState() => _EmployeeScreenState();
}

class _EmployeeScreenState extends State<EmployeeScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  final Color _primaryColor = const Color(0xFF003366);
  final Color _accentColor = const Color(0xFF0055AA);
  final Color _bgLight = const Color(0xFFF5F7FA);

  int? _selectedDepartmentId;

  @override
  void initState() {
    super.initState();
    context.read<EmployeeCubit>().loadPage(1);
    context.read<DepartmentCubit>().loadDepartments();
    context.read<EmployeeGroupCubit>().loadGroups(); // [MỚI] Tải danh sách tổ

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

  void _onWebSocketMessage(String message) {
    if (message == "REFRESH_EMPLOYEES" && mounted) {
      final state = context.read<EmployeeCubit>().state;
      int page = (state is EmployeeLoaded) ? state.currentPage : 1;
      context.read<EmployeeCubit>().loadPage(page);
    }
    if (message == "REFRESH_DEPARTMENTS" && mounted) {
      context.read<DepartmentCubit>().loadDepartments();
    }
    if (message == "REFRESH_EMPLOYEE_GROUPS" && mounted) {
      // [MỚI] Lắng nghe đổi Tổ
      context.read<EmployeeGroupCubit>().loadGroups();
    }
  }

  void _onDepartmentChanged(int? deptId) {
    setState(() {
      _selectedDepartmentId = deptId;
      _searchController.clear();
    });

    if (deptId == null) {
      context.read<EmployeeCubit>().loadEmployees();
    } else {
      context.read<EmployeeCubit>().loadEmployeesByDepartment(deptId);
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().isNotEmpty) {
        setState(() => _selectedDepartmentId = null);
        context.read<EmployeeCubit>().searchEmployees(query);
      } else {
        if (_selectedDepartmentId != null) {
          context.read<EmployeeCubit>().loadEmployeesByDepartment(
            _selectedDepartmentId!,
          );
        } else {
          context.read<EmployeeCubit>().loadEmployees();
        }
      }
    });
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) return;
    try {
      await launchUrl(Uri(scheme: 'tel', path: phoneNumber));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Cannot make phone call')));
      }
    }
  }

  Future<void> _sendEmail(String email) async {
    if (email.isEmpty) return;
    try {
      await launchUrl(Uri(scheme: 'mailto', path: email));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Cannot open email app')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: _bgLight,
      body: BlocBuilder<EmployeeCubit, EmployeeState>(
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- HEADER SECTION ---
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.people_alt,
                            color: _primaryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.employeeTitle,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Manage your team members",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        if (isDesktop) ...[
                          OutlinedButton.icon(
                            onPressed: () =>
                                context.read<EmployeeCubit>().exportExcel(),
                            icon: const Icon(Icons.download, size: 18),
                            label: const Text('EXPORT EXCEL'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green.shade700,
                              side: BorderSide(color: Colors.green.shade700),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final result = await FilePicker.platform
                                  .pickFiles(
                                    type: FileType.custom,
                                    allowedExtensions: ['xls', 'xlsx'],
                                    withData: true,
                                  );
                              if (result != null && result.files.isNotEmpty) {
                                context.read<EmployeeCubit>().importExcel(
                                  result.files.first,
                                );
                              }
                            },
                            icon: const Icon(Icons.upload_file, size: 18),
                            label: const Text('IMPORT EXCEL'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _primaryColor,
                              side: BorderSide(color: _primaryColor),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () =>
                                _showEditDialog(context, null, l10n),
                            icon: const Icon(Icons.add, size: 18),
                            label: Text(l10n.addEmployee.toUpperCase()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),

                    // --- BỘ LỌC TÌM KIẾM & PHÒNG BAN ---
                    isDesktop
                        ? Row(
                            children: [
                              Expanded(flex: 2, child: _buildSearchBar(l10n)),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 1,
                                child: _buildDepartmentFilter(),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              _buildSearchBar(l10n),
                              const SizedBox(height: 12),
                              _buildDepartmentFilter(),
                            ],
                          ),
                  ],
                ),
              ),
              Container(height: 1, color: Colors.grey.shade200),

              // --- MAIN CONTENT & PAGINATION ---
              Expanded(
                child: Builder(
                  builder: (context) {
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
                                Icons.person_off_outlined,
                                size: 60,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Không tìm thấy nhân viên nào",
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        );
                      }

                      return Column(
                        children: [
                          Expanded(
                            child: isDesktop
                                ? _buildDesktopGrid(
                                    context,
                                    state.employees,
                                    l10n,
                                  )
                                : _buildMobileList(
                                    context,
                                    state.employees,
                                    l10n,
                                  ),
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
          );
        },
      ),
      floatingActionButton: !isDesktop
          ? FloatingActionButton(
              backgroundColor: _accentColor,
              onPressed: () => _showEditDialog(context, null, l10n),
              child: const Icon(Icons.person_add, color: Colors.white),
            )
          : null,
    );
  }

  // --- WIDGET TÌM KIẾM ---
  Widget _buildSearchBar(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: _bgLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: l10n.searchEmployee,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
        ),
        onSubmitted: (value) => _onSearchChanged(value),
      ),
    );
  }

  // --- WIDGET LỌC THEO BỘ PHẬN ---
  Widget _buildDepartmentFilter() {
    return BlocBuilder<DepartmentCubit, DepartmentState>(
      builder: (context, state) {
        List<DropdownMenuItem<int?>> items = [
          const DropdownMenuItem(
            value: null,
            child: Text(
              "Tất cả phòng ban",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ];

        if (state is DepartmentLoaded) {
          items.addAll(
            state.departments
                .map((d) => DropdownMenuItem(value: d.id, child: Text(d.name)))
                .toList(),
          );
        }

        return Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int?>(
              value: _selectedDepartmentId,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              style: const TextStyle(color: Colors.black87, fontSize: 14),
              items: items,
              onChanged: _onDepartmentChanged,
            ),
          ),
        );
      },
    );
  }

  // --- WIDGET PHÂN TRANG ---
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
          clipBehavior: Clip.antiAlias,
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
                          l10n.department.toUpperCase(),
                          style: _headerStyle,
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          "TỔ",
                          style: _headerStyle,
                        ), // [MỚI] Thêm cột Tổ
                      ),
                      DataColumn(
                        label: Text(
                          l10n.position.toUpperCase(),
                          style: _headerStyle,
                        ),
                      ),
                      DataColumn(label: Text("LIÊN HỆ", style: _headerStyle)),
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
                            _DepartmentBadge(
                              deptId: emp.departmentId,
                              isChip: true,
                            ),
                          ),
                          DataCell(
                            _GroupBadge(
                              // [MỚI] Data Cell cho Tổ
                              groupId: emp.groupId,
                              isChip: true,
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
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                InkWell(
                                  onTap: () => _sendEmail(emp.email),
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
                                  onTap: () => _makePhoneCall(emp.phone),
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
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final emp = employees[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
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
                    _buildAvatar(emp.avatarUrl, emp.fullName, 28),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            emp.fullName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            emp.position,
                            style: TextStyle(
                              color: _primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _DepartmentBadge(
                            deptId: emp.departmentId,
                            isChip: false,
                          ),
                          const SizedBox(height: 4),
                          _GroupBadge(
                            // [MỚI] Hiển thị Tổ trên Mobile
                            groupId: emp.groupId,
                            isChip: false,
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
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => _sendEmail(emp.email),
                      child: _buildContactRow(
                        Icons.email,
                        emp.email,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _makePhoneCall(emp.phone),
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

  // --- AVATAR LOGIC ---
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

  // --- DIALOG THÊM / SỬA ---
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

    int? selectedDeptId = emp?.departmentId ?? _selectedDepartmentId;
    int? selectedGroupId = emp?.groupId;

    PlatformFile? pickedFile;
    Uint8List? pickedBytes;

    final employeeCubit = context.read<EmployeeCubit>();
    final departmentCubit = context.read<DepartmentCubit>();
    final employeeGroupCubit = context.read<EmployeeGroupCubit>(); // [MỚI]

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: employeeCubit),
          BlocProvider.value(value: departmentCubit),
          BlocProvider.value(
            value: employeeGroupCubit,
          ), // [MỚI] Provide Group Cubit
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
              titlePadding: const EdgeInsets.all(24),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
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
                        Center(
                          child: Stack(
                            children: [
                              GestureDetector(
                                onTap: pickImage,
                                child: CircleAvatar(
                                  radius: 40,
                                  backgroundColor: Colors.grey.shade200,
                                  backgroundImage: imageProvider,
                                  child: imageProvider == null
                                      ? const Icon(
                                          Icons.person,
                                          size: 40,
                                          color: Colors.grey,
                                        )
                                      : null,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: InkWell(
                                  onTap: pickImage,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: _primaryColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
                            if (v == null || v.trim().isEmpty) {
                              return "Required";
                            }
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(v)) {
                              return "Invalid email address";
                            }
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
                        // Dropdown Phòng Ban
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
                          onChanged: (val) {
                            setStateDialog(() {
                              selectedDeptId = val;
                              selectedGroupId =
                                  null; // Reset tổ khi đổi phòng ban
                            });
                          },
                          validator: (v) => v == null ? "Required" : null,
                        ),
                        const SizedBox(height: 16),
                        // [MỚI] Dropdown Tổ Nhân Viên
                        BlocBuilder<EmployeeGroupCubit, EmployeeGroupState>(
                          builder: (context, groupState) {
                            List<DropdownMenuItem<int?>> groupItems = [
                              const DropdownMenuItem(
                                value: null,
                                child: Text("Không thuộc tổ nào"),
                              ),
                            ];

                            if (groupState is EmployeeGroupLoaded) {
                              // Lọc tổ thuộc về bộ phận đang chọn
                              final filteredGroups = groupState.groups
                                  .where(
                                    (g) => g.departmentId == selectedDeptId,
                                  )
                                  .toList();

                              // Xác thực lại selectedGroupId tránh lỗi khi dropdown load danh sách mới
                              if (selectedGroupId != null &&
                                  !filteredGroups.any(
                                    (g) => g.id == selectedGroupId,
                                  )) {
                                selectedGroupId = null;
                              }

                              groupItems.addAll(
                                filteredGroups.map(
                                  (g) => DropdownMenuItem(
                                    value: g.id,
                                    child: Text(g.name),
                                  ),
                                ),
                              );
                            }

                            return DropdownButtonFormField<int?>(
                              value: selectedGroupId,
                              decoration: _inputDeco("Thuộc Tổ (Tùy chọn)"),
                              items: groupItems,
                              onChanged: (val) =>
                                  setStateDialog(() => selectedGroupId = val),
                            );
                          },
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
              actionsPadding: const EdgeInsets.all(24),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    l10n.cancel,
                    style: const TextStyle(color: Colors.grey),
                  ),
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
                        groupId: selectedGroupId, // [MỚI] Thêm ID Tổ
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
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

// Badge Phòng ban
class _DepartmentBadge extends StatelessWidget {
  final int deptId;
  final bool isChip;
  const _DepartmentBadge({required this.deptId, required this.isChip});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DepartmentCubit, DepartmentState>(
      builder: (context, state) {
        String deptName = "Unknown";
        Color color = Colors.grey;

        if (state is DepartmentLoaded) {
          final dept = state.departments
              .where((d) => d.id == deptId)
              .firstOrNull;
          if (dept != null) {
            deptName = dept.name;
            final colors = [
              Colors.blue,
              Colors.purple,
              Colors.orange,
              Colors.teal,
              Colors.redAccent,
              Colors.green,
              Colors.indigo,
              Colors.pinkAccent,
            ];
            color = colors[dept.id % colors.length];
          }
        }

        if (!isChip) {
          return Row(
            children: [
              Icon(Icons.circle, size: 8, color: color),
              const SizedBox(width: 6),
              Text(
                deptName,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            deptName,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}

// [MỚI] Badge Tổ Nhân Viên
class _GroupBadge extends StatelessWidget {
  final int? groupId;
  final bool isChip;
  const _GroupBadge({required this.groupId, required this.isChip});

  @override
  Widget build(BuildContext context) {
    if (groupId == null) {
      if (isChip) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            "Chưa phân tổ",
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }
      return Row(
        children: [
          Icon(Icons.circle, size: 8, color: Colors.grey.shade400),
          const SizedBox(width: 6),
          Text(
            "Chưa phân tổ",
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return BlocBuilder<EmployeeGroupCubit, EmployeeGroupState>(
      builder: (context, state) {
        String groupName = "Loading...";
        Color color = Colors.teal;

        if (state is EmployeeGroupLoaded) {
          final group = state.groups.where((g) => g.id == groupId).firstOrNull;
          if (group != null) {
            groupName = group.name;
          } else {
            groupName = "Không xác định";
            color = Colors.grey;
          }
        }

        if (!isChip) {
          return Row(
            children: [
              Icon(Icons.circle, size: 8, color: color),
              const SizedBox(width: 6),
              Text(
                groupName,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            groupName,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}
