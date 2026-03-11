import 'dart:async';
import 'package:flutter/material.dart' hide MaterialState;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:owvds/features/inventory/material_export/domain/material_export_model.dart';
import 'package:owvds/features/inventory/material_export/presentation/dialogs/material_export_dialog.dart';
import '../bloc/material_export_cubit.dart';

import 'package:owvds/features/inventory/warehouse/presentation/bloc/warehouse_cubit.dart';
import 'package:owvds/features/inventory/material/presentation/bloc/material_cubit.dart';
import 'package:owvds/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:owvds/features/hr/employee/presentation/bloc/employee_cubit.dart';
import 'package:owvds/features/production/machine/machine_assignment/data/machine_assignment_repository.dart';
import 'package:owvds/features/production/machine/machine_assignment/domain/machine_assignment_model.dart';

class MaterialExportScreen extends StatefulWidget {
  const MaterialExportScreen({super.key});

  @override
  State<MaterialExportScreen> createState() => _MaterialExportScreenState();
}

class _MaterialExportScreenState extends State<MaterialExportScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedDateFilter = 'Tất cả';
  Timer? _debounce;
  List<MachineProductHistory> _activeLooms = [];

  final Color _primaryColor = const Color(0xFF003366);

  @override
  void initState() {
    super.initState();
    context.read<MaterialExportCubit>().loadExports(isRefresh: true);
    context.read<WarehouseCubit>().loadWarehouses();
    context.read<MaterialCubit>().loadMaterials(limit: 1000);
    context.read<EmployeeCubit>().loadEmployees();
    _loadActiveLooms();
  }

  Future<void> _loadActiveLooms() async {
    try {
      final repo = MachineAssignmentRepository();
      final looms = await repo.getAllActiveAssignments();
      if (mounted) {
        setState(() {
          _activeLooms = looms.where((l) => l.endTime == null).toList();
        });
      }
    } catch (e) {
      debugPrint("Lỗi tải danh sách Loom: $e");
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<MaterialExportCubit>().setFilters(search: query);
    });
  }

  void _applyDateFilter(String filter) {
    setState(() => _selectedDateFilter = filter);
    final now = DateTime.now();
    DateTime? start, end;

    if (filter == 'Hôm nay') {
      start = DateTime(now.year, now.month, now.day);
      end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    } else if (filter == 'Tuần này') {
      start = now.subtract(Duration(days: now.weekday - 1));
      start = DateTime(start.year, start.month, start.day);
      end = now;
    } else if (filter == 'Tháng này') {
      start = DateTime(now.year, now.month, 1);
      end = now;
    } else if (filter == 'Năm nay') {
      start = DateTime(now.year, 1, 1);
      end = now;
    }

    context.read<MaterialExportCubit>().setFilters(
      fromDate: start,
      toDate: end,
      search: _searchController.text,
    );
  }

  void _showExportDialog({MaterialExport? export}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: context.read<MaterialExportCubit>(),
        child: MaterialExportDialog(exportData: export),
      ),
    );
  }

  void _confirmDelete(MaterialExport export) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận Hủy phiếu"),
        content: Text(
          "Bạn có chắc chắn muốn hủy phiếu xuất ${export.exportCode}?\nSố lượng vật tư sẽ được hoàn trả lại vào kho.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Đóng"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<MaterialExportCubit>().deleteExport(export.id);
            },
            child: const Text(
              "Hủy phiếu",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    final whState = context.watch<WarehouseCubit>().state;
    final matState = context.watch<MaterialCubit>().state;
    final empState = context.watch<EmployeeCubit>().state;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          "Phiếu Xuất Kho",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: _primaryColor,
        elevation: 0.5,
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.download, size: 18),
            label: const Text("Xuất Excel"),
            onPressed: () =>
                context.read<MaterialExportCubit>().downloadExcel(),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text("Tạo Phiếu Xuất"),
            onPressed: () => _showExportDialog(),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: BlocConsumer<MaterialExportCubit, MaterialExportState>(
        listener: (context, state) {
          if (state is MaterialExportActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is MaterialExportError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          bool isLoading = state is MaterialExportLoading;
          List<MaterialExport> records = [];
          int currentPage = 1;
          bool hasMore = false;

          if (state is MaterialExportLoaded) {
            records = state.exports;
            currentPage = state.currentPage;
            hasMore = state.hasMore;
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // --- BỘ LỌC ---
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          decoration: const InputDecoration(
                            hintText: 'Tìm theo mã phiếu, ghi chú...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          value: _selectedDateFilter,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            isDense: true,
                            labelText: "Thời gian",
                          ),
                          items:
                              [
                                    'Tất cả',
                                    'Hôm nay',
                                    'Tuần này',
                                    'Tháng này',
                                    'Năm nay',
                                  ]
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (val) => _applyDateFilter(val!),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // --- DANH SÁCH DỮ LIỆU ---
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: isLoading && records.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : records.isEmpty
                        ? const Center(
                            child: Text("Không có dữ liệu phiếu xuất."),
                          )
                        : Column(
                            children: [
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(12),
                                  itemCount: records.length,
                                  itemBuilder: (context, index) {
                                    final export = records[index];
                                    return _buildExportCard(
                                      export,
                                      isMobile,
                                      whState,
                                      matState,
                                      empState,
                                    );
                                  },
                                ),
                              ),
                              // Phân trang
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.chevron_left),
                                      onPressed: currentPage > 1
                                          ? () => context
                                                .read<MaterialExportCubit>()
                                                .loadExports()
                                          : null,
                                    ),
                                    Text(
                                      "Trang $currentPage",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.chevron_right),
                                      onPressed: hasMore
                                          ? () => context
                                                .read<MaterialExportCubit>()
                                                .loadExports()
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildExportCard(
    MaterialExport export,
    bool isMobile,
    WarehouseState whState,
    MaterialState matState,
    EmployeeState empState,
  ) {
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(export.createdAt);
    final totalKg = export.details.fold(0.0, (sum, d) => sum + d.quantityKg);

    // --- Resolve tên kho ---
    String warehouseName = export.warehouse?.name ?? '';
    if (warehouseName.isEmpty || warehouseName == 'null') {
      if (whState is WarehouseLoaded) {
        final whList = whState.warehouses.where(
          (w) => w.warehouseId == export.warehouseId,
        );
        warehouseName = whList.isNotEmpty
            ? whList.first.name
            : 'Kho: ${export.warehouseId}';
      } else {
        warehouseName = 'Kho: ${export.warehouseId}';
      }
    }

    // --- Resolve tên người xuất ---
    // Ưu tiên: dữ liệu populate sẵn trên model → EmployeeCubit → AuthCubit
    String exporterName = export.exporter?.fullName ?? '';
    if (exporterName.isEmpty || exporterName == 'null') {
      if (empState is EmployeeLoaded && export.exporterId != null) {
        try {
          exporterName = empState.employees
              .firstWhere((e) => e.id == export.exporterId)
              .fullName;
        } catch (_) {
          exporterName = 'ID:${export.exporterId}';
        }
      } else {
        // Fallback: lấy tên người đang đăng nhập nếu phiếu là của mình
        final authState = context.read<AuthCubit>().state;
        if (authState is AuthAuthenticated &&
            authState.user.employeeId == export.exporterId) {
          exporterName = authState.user.employeeName ?? authState.user.fullName;
        } else {
          exporterName = 'N/A';
        }
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER PHIẾU ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: _primaryColor.withOpacity(0.1),
                      child: Icon(Icons.output, color: _primaryColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      export.exportCode,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Text(
                        "Tổng: ${totalKg.toStringAsFixed(2)} kg",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.edit,
                        color: Colors.blue,
                        size: 20,
                      ),
                      tooltip: "Sửa phiếu",
                      onPressed: () => _showExportDialog(export: export),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.red,
                        size: 20,
                      ),
                      tooltip: "Hủy phiếu",
                      onPressed: () => _confirmDelete(export),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),

            // --- THÔNG TIN CHUNG PHIẾU ---
            Wrap(
              spacing: 24,
              runSpacing: 8,
              children: [
                _buildInfoItem(Icons.calendar_today, "Ngày", dateStr),
                _buildInfoItem(Icons.warehouse, "Kho", warehouseName),
                _buildInfoItem(
                  Icons.person_outline,
                  "Người xuất",
                  exporterName,
                ),
                _buildInfoItem(
                  Icons.precision_manufacturing,
                  "Người nhận",
                  export.receiver?.fullName ?? 'Không có',
                ),
                if (export.note != null && export.note!.isNotEmpty)
                  _buildInfoItem(Icons.note, "Ghi chú", export.note!),
              ],
            ),
            const SizedBox(height: 16),

            // --- CHI TIẾT VẬT TƯ ĐÃ XUẤT ---
            const Text(
              "Chi tiết vật tư xuất:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: export.details.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final d = export.details[index];

                  String matCode = d.material?.materialCode ?? '';
                  if (matCode.isEmpty || matCode == 'null') {
                    if (matState is MaterialLoaded) {
                      final mList = matState.materials.where(
                        (m) => m.materialId == d.materialId,
                      );
                      matCode = mList.isNotEmpty
                          ? mList.first.materialCode
                          : 'ID:${d.materialId}';
                    } else {
                      matCode = 'ID:${d.materialId}';
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- DÒNG 1: VẬT TƯ, LÔ, SỐ LƯỢNG ---
                        Row(
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.indigo.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.indigo.shade100,
                                  ),
                                ),
                                child: Text(
                                  matCode,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo.shade800,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.green.shade100,
                                  ),
                                ),
                                child: Text(
                                  "Lô: ${d.batch?.batchCode ?? d.batchId}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade800,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              "${d.quantityKg} kg  •  ${d.quantityCones} cuộn  •  ${d.numberOfPallets} pallet",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // --- DÒNG 2: THÔNG TIN LOOM (Đã thiết kế lại Badge) ---
                        Row(
                          children: [
                            if (d.loomId == null)
                              Text(
                                "Không gán máy (Xuất dự phòng)",
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontStyle: FontStyle.italic,
                                  fontSize: 12,
                                ),
                              )
                            else if (d.loomInfo != null)
                              Expanded(
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: Colors.blue.shade100,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.precision_manufacturing,
                                            size: 12,
                                            color: Colors.blue.shade700,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            d.loomInfo!.machineName ?? 'Máy',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue.shade800,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: Colors.orange.shade100,
                                        ),
                                      ),
                                      child: Text(
                                        "Line ${d.loomInfo!.lineNumber}",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange.shade800,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      "SP: ${d.loomInfo!.productCode ?? 'N/A'}",
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Builder(
                                builder: (_) {
                                  // Tra cứu loom từ danh sách đang hoạt động
                                  MachineProductHistory? loom;
                                  try {
                                    loom = _activeLooms.firstWhere(
                                      (l) => l.id == d.loomId,
                                    );
                                  } catch (_) {
                                    loom = null;
                                  }

                                  if (loom != null) {
                                    return Expanded(
                                      child: Wrap(
                                        spacing: 8,
                                        runSpacing: 6,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          // Badge Tên máy
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border: Border.all(
                                                color: Colors.blue.shade100,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.precision_manufacturing,
                                                  size: 12,
                                                  color: Colors.blue.shade700,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  loom.machine?.machineName ??
                                                      'Máy',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.blue.shade800,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Badge Line
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border: Border.all(
                                                color: Colors.orange.shade100,
                                              ),
                                            ),
                                            child: Text(
                                              "Line ${loom.lineNumber}",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.orange.shade800,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          // Mã sản phẩm
                                          Text(
                                            "SP: ${loom.product?.itemCode ?? 'N/A'}",
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  // Chưa tải xong _activeLooms
                                  return Text(
                                    "Loom ID: ${d.loomId} (Đang tải...)",
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontStyle: FontStyle.italic,
                                      fontSize: 12,
                                    ),
                                  );
                                },
                              ),

                            if (d.componentType != null &&
                                d.componentType!.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blueGrey.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  "Loại: ${d.componentType}",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.blueGrey.shade800,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        RichText(
          text: TextSpan(
            text: "$label: ",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            children: [
              TextSpan(
                text: value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
