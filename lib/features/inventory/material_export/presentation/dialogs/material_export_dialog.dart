import 'package:flutter/material.dart' hide MaterialState;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:owvds/features/inventory/material_export/domain/material_export_model.dart';

// --- Imports Export ---
import '../bloc/material_export_cubit.dart';

// --- Imports Machine/Loom ---
import 'package:owvds/features/production/machine/machine_assignment/data/machine_assignment_repository.dart';
import 'package:owvds/features/production/machine/machine_assignment/domain/machine_assignment_model.dart';

// --- Imports Auth, Employee, Warehouse, Inventory, Material ---
import 'package:owvds/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:owvds/features/hr/employee/presentation/bloc/employee_cubit.dart';
import 'package:owvds/features/hr/employee/domain/employee_model.dart';
import 'package:owvds/features/inventory/warehouse/presentation/bloc/warehouse_cubit.dart';
import 'package:owvds/features/inventory/warehouse/domain/warehouse_model.dart';
import 'package:owvds/features/inventory/material_inventory/presentation/bloc/material_inventory_cubit.dart';
import 'package:owvds/features/inventory/material_inventory/domain/material_inventory_model.dart';
import 'package:owvds/features/inventory/material/presentation/bloc/material_cubit.dart';
import 'package:owvds/features/inventory/material/domain/material_model.dart';

class MaterialExportDialog extends StatefulWidget {
  final MaterialExport? exportData; // Nếu có => Chế độ Sửa

  const MaterialExportDialog({super.key, this.exportData});

  @override
  State<MaterialExportDialog> createState() => _MaterialExportDialogState();
}

class _MaterialExportDialogState extends State<MaterialExportDialog> {
  final _formKey = GlobalKey<FormState>();

  // Header controllers
  final TextEditingController _codeController = TextEditingController(
    text: "AUTO",
  );
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  int? _selectedWarehouseId;
  int? _selectedExporterId;
  int? _selectedReceiverId;
  String _exporterName = "Không xác định";

  // Details List
  List<Map<String, dynamic>> _details = [];

  // Looms
  List<MachineProductHistory> _activeLooms = [];

  bool get isEdit => widget.exportData != null;

  @override
  void initState() {
    super.initState();
    _loadActiveLooms();

    // 1. Tải các danh sách cơ sở
    context.read<EmployeeCubit>().loadEmployees();
    context.read<WarehouseCubit>().loadWarehouses();
    // Tải danh sách vật tư (để map ID sang Mã code)
    context.read<MaterialCubit>().loadMaterials(limit: 1000);

    // 2. Lấy thông tin người đăng nhập (Người xuất)
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      _selectedExporterId = authState.user.employeeId;
      _exporterName = authState.user.employeeName ?? authState.user.fullName;
    }

    if (isEdit) {
      final data = widget.exportData!;
      _codeController.text = data.exportCode;
      _dateController.text = DateFormat('yyyy-MM-dd').format(data.exportDate);
      _noteController.text = data.note ?? '';
      _selectedWarehouseId = data.warehouseId;
      _selectedExporterId = data.exporterId;
      _selectedReceiverId = data.receiverId;
      _exporterName = data.exporter?.fullName ?? _exporterName;

      // Tải tồn kho cho kho đã chọn
      context.read<MaterialInventoryCubit>().loadInventories(
        warehouseId: _selectedWarehouseId,
      );

      _details = data.details.map((d) {
        String? loomDisplayName;
        if (d.loomInfo != null) {
          loomDisplayName =
              "${d.loomInfo?.machineName ?? 'Máy'} - L${d.loomInfo?.lineNumber} (${d.loomInfo?.productCode ?? ''})";
        }

        return {
          'inventory_id': null,
          'material_id': d.materialId,
          'material_code': d.material?.materialCode,
          'batch_id': d.batchId,
          'batch_code': d.batch?.batchCode,
          'max_kg': d.quantityKg,
          'max_cones': d.quantityCones,
          'max_pallets': d.numberOfPallets,
          'quantity_kg': d.quantityKg,
          'quantity_cones': d.quantityCones,
          'number_of_pallets': d.numberOfPallets,
          'loom_id': d.loomId,
          'loom_name': loomDisplayName,
        };
      }).toList();
    } else {
      _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _addDetailRow();

      context.read<MaterialExportCubit>().getNextCode().then((code) {
        if (mounted) setState(() => _codeController.text = code);
      });
    }
  }

  Future<void> _loadActiveLooms() async {
    try {
      final repo = MachineAssignmentRepository();
      final looms = await repo.getAllActiveAssignments();
      if (mounted) {
        setState(() {
          _activeLooms = looms.where((loom) => loom.endTime == null).toList();
        });
      }
    } catch (e) {
      debugPrint("Lỗi tải danh sách Loom: $e");
    }
  }

  // Hàm Helper để map material_id -> material_code
  String _getMaterialCode(int matId, List<MaterialItem> materials) {
    try {
      return materials.firstWhere((m) => m.materialId == matId).materialCode;
    } catch (e) {
      return 'ID:$matId';
    }
  }

  void _addDetailRow() {
    setState(() {
      _details.add({
        'inventory_id': null,
        'material_id': null,
        'material_code': null,
        'batch_id': null,
        'batch_code': null,
        'max_kg': 0.0,
        'max_cones': 0,
        'max_pallets': 0,
        'quantity_kg': 0.0,
        'quantity_cones': 0,
        'number_of_pallets': 0,
        'loom_id': null,
        'loom_name': null,
      });
    });
  }

  void _removeDetailRow(int index) {
    setState(() {
      _details.removeAt(index);
    });
  }

  void _onWarehouseChanged(int? newWarehouseId) {
    if (newWarehouseId == null || newWarehouseId == _selectedWarehouseId) {
      return;
    }

    setState(() {
      _selectedWarehouseId = newWarehouseId;
      if (!isEdit) {
        _details.clear();
        _addDetailRow();
      }
    });

    context.read<MaterialInventoryCubit>().loadInventories(
      warehouseId: newWarehouseId,
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedWarehouseId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Vui lòng chọn Kho xuất")));
      return;
    }

    if (!isEdit) {
      if (_details.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Phải có ít nhất 1 dòng vật tư xuất")),
        );
        return;
      }
      for (var d in _details) {
        if (d['material_id'] == null ||
            d['batch_id'] == null ||
            d['quantity_kg'] <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Vui lòng chọn đầy đủ Lô tồn kho và nhập Số Kg > 0",
              ),
            ),
          );
          return;
        }
        if (d['quantity_kg'] > d['max_kg']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Lỗi: Xuất quá tồn kho (Tồn: ${d['max_kg']}kg)"),
            ),
          );
          return;
        }
      }

      final request = MaterialExportRequest(
        exportCode: _codeController.text,
        exportDate: _dateController.text,
        warehouseId: _selectedWarehouseId!,
        exporterId: _selectedExporterId,
        receiverId: _selectedReceiverId,
        note: _noteController.text,
        details: _details
            .map(
              (d) => MaterialExportDetailRequest(
                materialId: d['material_id'],
                batchId: d['batch_id'],
                quantityKg: double.parse(d['quantity_kg'].toString()),
                quantityCones: int.parse(d['quantity_cones'].toString()),
                numberOfPallets: int.parse(d['number_of_pallets'].toString()),
                loomId: d['loom_id'],
              ),
            )
            .toList(),
      );

      context.read<MaterialExportCubit>().createExport(request);
    } else {
      final updateData = {
        'export_date': _dateController.text,
        'exporter_id': _selectedExporterId,
        'receiver_id': _selectedReceiverId,
        'note': _noteController.text,
      };
      context.read<MaterialExportCubit>().updateExport(
        widget.exportData!.id,
        updateData,
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 800;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: isMobile
          ? const EdgeInsets.all(16)
          : const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Container(
        width: isMobile ? double.infinity : 1350,
        height: isMobile ? size.height * 0.8 : 800,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEdit ? "Sửa Phiếu Xuất" : "Tạo Phiếu Xuất Mới",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003366),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),

              // --- FORM HEADER INFO ---
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: 180,
                    child: TextFormField(
                      controller: _codeController,
                      decoration: const InputDecoration(
                        labelText: "Mã Phiếu",
                        border: OutlineInputBorder(),
                        isDense: true,
                        filled: true,
                        fillColor: Color(0xFFF5F5F5),
                      ),
                      readOnly: true,
                    ),
                  ),

                  SizedBox(
                    width: 180,
                    child: TextFormField(
                      controller: _dateController,
                      decoration: const InputDecoration(
                        labelText: "Ngày xuất (YYYY-MM-DD)",
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (v) => v!.isEmpty ? "Bắt buộc" : null,
                    ),
                  ),

                  BlocBuilder<WarehouseCubit, WarehouseState>(
                    builder: (context, state) {
                      List<Warehouse> whList = [];
                      if (state is WarehouseLoaded) whList = state.warehouses;

                      return SizedBox(
                        width: 200,
                        child: DropdownButtonFormField<int>(
                          value: _selectedWarehouseId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: "Kho xuất (*)",
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: whList
                              .map(
                                (w) => DropdownMenuItem(
                                  value: w.warehouseId,
                                  child: Text(
                                    w.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: isEdit ? null : _onWarehouseChanged,
                          validator: (v) => v == null ? "Chọn kho" : null,
                        ),
                      );
                    },
                  ),

                  SizedBox(
                    width: 200,
                    child: TextFormField(
                      initialValue: _exporterName,
                      decoration: const InputDecoration(
                        labelText: "Người xuất",
                        border: OutlineInputBorder(),
                        isDense: true,
                        filled: true,
                        fillColor: Color(0xFFF5F5F5),
                      ),
                      readOnly: true,
                    ),
                  ),

                  BlocBuilder<EmployeeCubit, EmployeeState>(
                    builder: (context, state) {
                      List<Employee> empList = [];
                      if (state is EmployeeLoaded) empList = state.employees;

                      return SizedBox(
                        width: 250,
                        child: DropdownButtonFormField<int>(
                          value: _selectedReceiverId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: "Người nhận (Đứng máy)",
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: [
                            const DropdownMenuItem<int>(
                              value: null,
                              child: Text("Không chọn"),
                            ),
                            ...empList.map(
                              (e) => DropdownMenuItem(
                                value: e.id,
                                child: Text(
                                  "${e.fullName} - ${e.position}",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (val) =>
                              setState(() => _selectedReceiverId = val),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: "Ghi chú phiếu",
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),

              const SizedBox(height: 24),

              // --- FORM DETAILS ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Chi tiết vật tư xuất",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  if (!isEdit)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text("Thêm dòng"),
                      onPressed: () {
                        if (_selectedWarehouseId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Vui lòng chọn Kho xuất trước"),
                            ),
                          );
                          return;
                        }
                        _addDetailRow();
                      },
                    ),
                ],
              ),
              if (isEdit)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    "⚠ Ở chế độ sửa, bạn chỉ có thể sửa thông tin chung, không thể sửa danh sách vật tư.",
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              const SizedBox(height: 8),

              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: BlocBuilder<MaterialCubit, MaterialState>(
                    builder: (context, matState) {
                      List<MaterialItem> materials = [];
                      if (matState is MaterialLoaded) {
                        materials = matState.materials;
                      }

                      return BlocBuilder<
                        MaterialInventoryCubit,
                        MaterialInventoryState
                      >(
                        builder: (context, invState) {
                          List<MaterialInventory> invList = [];
                          if (invState is MaterialInventoryLoaded) {
                            invList = invState.inventories;
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.all(8),
                            itemCount: _details.length,
                            separatorBuilder: (context, index) =>
                                const Divider(thickness: 2),
                            itemBuilder: (context, index) {
                              final item = _details[index];

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: CircleAvatar(
                                      radius: 12,
                                      backgroundColor: Colors.blue.shade100,
                                      child: Text(
                                        "${index + 1}",
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Wrap(
                                      spacing: 12,
                                      runSpacing: 12,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        // ==========================================
                                        // DROPDOWN CHỌN LÔ (LÀM MỜ LÔ HẾT HÀNG)
                                        // ==========================================
                                        if (!isEdit)
                                          SizedBox(
                                            width: 550,
                                            child: DropdownButtonFormField<int>(
                                              value: item['inventory_id'],
                                              isExpanded: true,
                                              itemHeight: null,
                                              decoration: const InputDecoration(
                                                labelText:
                                                    "Chọn Mã Vật tư - Lô tồn kho",
                                                border: OutlineInputBorder(),
                                                isDense: true,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 12,
                                                    ),
                                              ),
                                              items: invList.map((inv) {
                                                final matCode =
                                                    _getMaterialCode(
                                                      inv.materialId,
                                                      materials,
                                                    );
                                                final batchCode =
                                                    inv.batchCode ??
                                                    '${inv.batchId}';
                                                final bool outOfStock =
                                                    inv.quantityKg <=
                                                    0; // [MỚI] Kiểm tra hết hàng

                                                return DropdownMenuItem<int>(
                                                  value: outOfStock
                                                      ? null
                                                      : inv.id, // [MỚI] Nếu hết hàng thì vô hiệu hóa value
                                                  enabled:
                                                      !outOfStock, // [MỚI] Tắt khả năng click
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 4,
                                                        ),
                                                    // [MỚI] Thêm opacity nếu hết hàng để làm mờ
                                                    foregroundDecoration:
                                                        outOfStock
                                                        ? const BoxDecoration(
                                                            color:
                                                                Colors.white60,
                                                            backgroundBlendMode:
                                                                BlendMode
                                                                    .lighten,
                                                          )
                                                        : null,
                                                    child: Row(
                                                      children: [
                                                        Flexible(
                                                          flex: 2,
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal: 6,
                                                                  vertical: 4,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color: Colors
                                                                  .indigo
                                                                  .shade50,
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    6,
                                                                  ),
                                                              border: Border.all(
                                                                color: Colors
                                                                    .indigo
                                                                    .shade100,
                                                              ),
                                                            ),
                                                            child: Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Icon(
                                                                  Icons
                                                                      .category,
                                                                  size: 12,
                                                                  color: Colors
                                                                      .indigo
                                                                      .shade700,
                                                                ),
                                                                const SizedBox(
                                                                  width: 4,
                                                                ),
                                                                Flexible(
                                                                  child: Text(
                                                                    matCode,
                                                                    style: TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: Colors
                                                                          .indigo
                                                                          .shade800,
                                                                      fontSize:
                                                                          12,
                                                                    ),
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Flexible(
                                                          flex: 2,
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal: 6,
                                                                  vertical: 4,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color: Colors
                                                                  .green
                                                                  .shade50,
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    6,
                                                                  ),
                                                              border: Border.all(
                                                                color: Colors
                                                                    .green
                                                                    .shade100,
                                                              ),
                                                            ),
                                                            child: Text(
                                                              "Lô: $batchCode",
                                                              style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .green
                                                                    .shade800,
                                                                fontSize: 12,
                                                              ),
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Expanded(
                                                          flex: 3,
                                                          child: outOfStock
                                                              ? const Text(
                                                                  "Đã hết hàng",
                                                                  style: TextStyle(
                                                                    color: Colors
                                                                        .red,
                                                                    fontSize:
                                                                        12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontStyle:
                                                                        FontStyle
                                                                            .italic,
                                                                  ),
                                                                )
                                                              : Text(
                                                                  "📍 ${inv.location} | 📦 ${inv.quantityKg}kg - ${inv.quantityCones}c",
                                                                  style: TextStyle(
                                                                    color: Colors
                                                                        .grey
                                                                        .shade700,
                                                                    fontSize:
                                                                        12,
                                                                  ),
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                              selectedItemBuilder:
                                                  (BuildContext context) {
                                                    return invList.map<Widget>((
                                                      inv,
                                                    ) {
                                                      final matCode =
                                                          _getMaterialCode(
                                                            inv.materialId,
                                                            materials,
                                                          );
                                                      final batchCode =
                                                          inv.batchCode ??
                                                          '${inv.batchId}';
                                                      return Container(
                                                        alignment: Alignment
                                                            .centerLeft,
                                                        child: Text(
                                                          "$matCode | Lô: $batchCode | 📦 ${inv.quantityKg}kg - ${inv.quantityCones} cuộn",
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: Colors
                                                                    .black87,
                                                              ),
                                                        ),
                                                      );
                                                    }).toList();
                                                  },
                                              onChanged: (val) {
                                                if (val == null) {
                                                  return;
                                                }
                                                final selectedInv = invList
                                                    .firstWhere(
                                                      (e) => e.id == val,
                                                    );
                                                setState(() {
                                                  item['inventory_id'] = val;
                                                  item['material_id'] =
                                                      selectedInv.materialId;
                                                  item['material_code'] =
                                                      _getMaterialCode(
                                                        selectedInv.materialId,
                                                        materials,
                                                      );
                                                  item['batch_id'] =
                                                      selectedInv.batchId;
                                                  item['batch_code'] =
                                                      selectedInv.batchCode;
                                                  item['max_kg'] =
                                                      selectedInv.quantityKg;
                                                  item['max_cones'] =
                                                      selectedInv.quantityCones;
                                                  item['max_pallets'] =
                                                      selectedInv
                                                          .numberOfPallets ??
                                                      0;

                                                  item['quantity_kg'] =
                                                      selectedInv.quantityKg;
                                                  item['quantity_cones'] =
                                                      selectedInv.quantityCones;
                                                  item['number_of_pallets'] =
                                                      selectedInv
                                                          .numberOfPallets ??
                                                      0;
                                                });
                                              },
                                            ),
                                          )
                                        else
                                          SizedBox(
                                            width: 550,
                                            child: TextFormField(
                                              initialValue:
                                                  "${item['material_code'] ?? 'Mã ID: ${item['material_id']}'} | Lô: ${item['batch_code'] ?? item['batch_id']}",
                                              decoration: const InputDecoration(
                                                labelText:
                                                    "Vật tư - Lô đã xuất",
                                                border: OutlineInputBorder(),
                                                isDense: true,
                                                filled: true,
                                                fillColor: Color(0xFFF5F5F5),
                                              ),
                                              readOnly: true,
                                            ),
                                          ),

                                        // SỐ KG
                                        SizedBox(
                                          width: 120,
                                          child: TextFormField(
                                            key: ValueKey(
                                              "kg_${index}_${item['inventory_id']}",
                                            ),
                                            initialValue: item['quantity_kg']
                                                .toString(),
                                            decoration: InputDecoration(
                                              labelText: "Xuất Kg",
                                              hintText:
                                                  "Tồn: ${item['max_kg']}",
                                              border:
                                                  const OutlineInputBorder(),
                                              isDense: true,
                                              labelStyle: TextStyle(
                                                color:
                                                    item['quantity_kg'] >
                                                        item['max_kg']
                                                    ? Colors.red
                                                    : null,
                                              ),
                                            ),
                                            readOnly: isEdit,
                                            keyboardType:
                                                const TextInputType.numberWithOptions(
                                                  decimal: true,
                                                ),
                                            onChanged: (v) {
                                              final val =
                                                  double.tryParse(v) ?? 0.0;
                                              item['quantity_kg'] = val;
                                              setState(() {});
                                            },
                                          ),
                                        ),

                                        // SỐ CUỘN
                                        SizedBox(
                                          width: 100,
                                          child: TextFormField(
                                            key: ValueKey(
                                              "cone_${index}_${item['inventory_id']}",
                                            ),
                                            initialValue: item['quantity_cones']
                                                .toString(),
                                            decoration: InputDecoration(
                                              labelText: "Cuộn",
                                              hintText:
                                                  "Tồn: ${item['max_cones']}",
                                              border:
                                                  const OutlineInputBorder(),
                                              isDense: true,
                                            ),
                                            readOnly: isEdit,
                                            keyboardType: TextInputType.number,
                                            onChanged: (v) =>
                                                item['quantity_cones'] =
                                                    int.tryParse(v) ?? 0,
                                          ),
                                        ),

                                        // SỐ PALLET
                                        SizedBox(
                                          width: 100,
                                          child: TextFormField(
                                            key: ValueKey(
                                              "pallet_${index}_${item['inventory_id']}",
                                            ),
                                            initialValue:
                                                item['number_of_pallets']
                                                    .toString(),
                                            decoration: InputDecoration(
                                              labelText: "Pallet",
                                              hintText:
                                                  "Tồn: ${item['max_pallets']}",
                                              border:
                                                  const OutlineInputBorder(),
                                              isDense: true,
                                            ),
                                            readOnly: isEdit,
                                            keyboardType: TextInputType.number,
                                            onChanged: (v) =>
                                                item['number_of_pallets'] =
                                                    int.tryParse(v) ?? 0,
                                          ),
                                        ),

                                        // ==========================================
                                        // GÁN MÁY LOOM
                                        // ==========================================
                                        if (!isEdit)
                                          SizedBox(
                                            width: 250,
                                            child: DropdownButtonFormField<int>(
                                              value: item['loom_id'],
                                              decoration: const InputDecoration(
                                                labelText: "Gán cho Máy/Line",
                                                border: OutlineInputBorder(),
                                                isDense: true,
                                              ),
                                              isExpanded: true,
                                              items: [
                                                const DropdownMenuItem(
                                                  value: null,
                                                  child: Text(
                                                    "Không gán (Dự phòng)",
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                ..._activeLooms.map(
                                                  (loom) => DropdownMenuItem(
                                                    value: loom.id,
                                                    child: Text(
                                                      "${loom.machine?.machineName ?? 'Máy'} - L${loom.lineNumber} (${loom.product?.itemCode ?? ''})",
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                              onChanged: (val) => setState(
                                                () => item['loom_id'] = val,
                                              ),
                                            ),
                                          )
                                        else
                                          SizedBox(
                                            width: 250,
                                            child: TextFormField(
                                              initialValue:
                                                  item['loom_name'] ??
                                                  (item['loom_id'] != null
                                                      ? "Loom ID: ${item['loom_id']}"
                                                      : "Không gán"),
                                              decoration: const InputDecoration(
                                                labelText: "Máy/Line đã gán",
                                                border: OutlineInputBorder(),
                                                isDense: true,
                                                filled: true,
                                                fillColor: Color(0xFFF5F5F5),
                                              ),
                                              readOnly: true,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (!isEdit)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                        ),
                                        onPressed: () =>
                                            _removeDetailRow(index),
                                      ),
                                    ),
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Hủy"),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003366),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _submit,
                      child: Text(isEdit ? "Lưu Thay Đổi" : "Tạo Phiếu Xuất"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
