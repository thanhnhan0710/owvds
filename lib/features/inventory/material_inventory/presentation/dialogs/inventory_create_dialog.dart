import 'package:flutter/material.dart' hide MaterialState;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dropdown_search/dropdown_search.dart';

import '../bloc/material_inventory_cubit.dart';
import '../../../warehouse/presentation/bloc/warehouse_cubit.dart';
import '../../../warehouse/domain/warehouse_model.dart';
import '../../../../inventory/material/presentation/bloc/material_cubit.dart';
import '../../../../inventory/material/domain/material_model.dart';

class InventoryCreateDialog extends StatefulWidget {
  const InventoryCreateDialog({super.key});

  @override
  State<InventoryCreateDialog> createState() => _InventoryCreateDialogState();
}

class _InventoryCreateDialogState extends State<InventoryCreateDialog> {
  final _formKey = GlobalKey<FormState>();

  int? _selectedWarehouseId;
  int? _selectedMaterialId;

  final TextEditingController _supplierBatchCtrl = TextEditingController();
  final TextEditingController _locationCtrl = TextEditingController();
  final TextEditingController _palletsCtrl = TextEditingController();
  final TextEditingController _qtyKgCtrl = TextEditingController();
  final TextEditingController _qtyConesCtrl = TextEditingController();

  @override
  void dispose() {
    _supplierBatchCtrl.dispose();
    _locationCtrl.dispose();
    _palletsCtrl.dispose();
    _qtyKgCtrl.dispose();
    _qtyConesCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_selectedWarehouseId == null || _selectedMaterialId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng chọn Kho và Nguyên vật liệu!'),
          ),
        );
        return;
      }

      final data = {
        "warehouse_id": _selectedWarehouseId,
        "material_id": _selectedMaterialId,
        "supplier_batch_no": _supplierBatchCtrl.text.trim().isEmpty
            ? null
            : _supplierBatchCtrl.text.trim(),
        "location": _locationCtrl.text.trim().isEmpty
            ? "N/A"
            : _locationCtrl.text.trim(),
        "number_of_pallets": int.tryParse(_palletsCtrl.text) ?? 0,
        "quantity_kg": double.tryParse(_qtyKgCtrl.text) ?? 0.0,
        "quantity_cones": int.tryParse(_qtyConesCtrl.text) ?? 0,
      };

      context.read<MaterialInventoryCubit>().initStock(data);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_to_photos,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Thêm Tồn Kho Thủ Công",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003366),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  "Sử dụng chức năng này để nhập tồn kho đầu kỳ hoặc hàng cũ. Hệ thống sẽ tự động tạo Lô nội bộ mới.",
                  style: TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const Divider(height: 32),

                // 1. Chọn Kho & NVL
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: BlocBuilder<WarehouseCubit, WarehouseState>(
                        builder: (context, state) {
                          List<Warehouse> warehouses = [];
                          if (state is WarehouseLoaded) {
                            warehouses = state.warehouses;
                          }
                          return DropdownButtonFormField<int>(
                            decoration: const InputDecoration(
                              labelText: "Chọn Kho (*)",
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: warehouses
                                .map(
                                  (w) => DropdownMenuItem(
                                    value: w.warehouseId,
                                    child: Text(w.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _selectedWarehouseId = val),
                            validator: (v) => v == null ? "Bắt buộc" : null,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: BlocBuilder<MaterialCubit, MaterialState>(
                        builder: (context, state) {
                          List<MaterialItem> mats = [];
                          if (state is MaterialLoaded) mats = state.materials;
                          return DropdownSearch<MaterialItem>(
                            popupProps: PopupProps.menu(
                              showSearchBox: true,
                              searchFieldProps: TextFieldProps(
                                decoration: InputDecoration(
                                  hintText: "Tìm mã/tên...",
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                            ),
                            items: (filter, props) => mats
                                .where(
                                  (m) =>
                                      m.materialCode.toLowerCase().contains(
                                        filter.toLowerCase(),
                                      ) ||
                                      m.materialName.toLowerCase().contains(
                                        filter.toLowerCase(),
                                      ),
                                )
                                .toList(),
                            itemAsString: (m) =>
                                "[${m.materialCode}] ${m.materialName}",

                            // [ĐÃ SỬA LỖI]: Bổ sung compareFn để thư viện biết cách so sánh các object MaterialItem
                            compareFn: (item1, item2) =>
                                item1.materialId == item2.materialId,

                            onChanged: (val) => setState(
                              () => _selectedMaterialId = val?.materialId,
                            ),
                            decoratorProps: DropDownDecoratorProps(
                              decoration: InputDecoration(
                                labelText: "Chọn Nguyên Vật Liệu (*)",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                isDense: true,
                              ),
                            ),
                            validator: (v) => v == null ? "Bắt buộc" : null,
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 2. Chi tiết
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _locationCtrl,
                        decoration: const InputDecoration(
                          labelText: "Vị trí (Kệ/Bin)",
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _supplierBatchCtrl,
                        decoration: const InputDecoration(
                          labelText: "Mã Lô NCC (Tùy chọn)",
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 3. Số lượng
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _qtyKgCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: "Khối lượng (Kg) *",
                          border: OutlineInputBorder(),
                          isDense: true,
                          fillColor: Colors.greenAccent,
                          filled: false,
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty || double.parse(v) <= 0)
                            ? "Lớn hơn 0"
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _qtyConesCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Số Cuộn",
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _palletsCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Số Pallet",
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Hủy"),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text("Xác nhận Thêm"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
