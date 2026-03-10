import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:owvds/features/inventory/material_inventory/domain/material_inventory_model.dart';
import '../bloc/material_inventory_cubit.dart';

class InventoryAdjustmentDialog extends StatefulWidget {
  final MaterialInventory inventory;
  const InventoryAdjustmentDialog({super.key, required this.inventory});

  @override
  State<InventoryAdjustmentDialog> createState() =>
      _InventoryAdjustmentDialogState();
}

class _InventoryAdjustmentDialogState extends State<InventoryAdjustmentDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _locationCtrl;
  late TextEditingController _palletsCtrl;
  late TextEditingController _qtyKgCtrl;
  late TextEditingController _qtyConesCtrl;

  @override
  void initState() {
    super.initState();
    _locationCtrl = TextEditingController(text: widget.inventory.location);
    _palletsCtrl = TextEditingController(
      text: (widget.inventory.numberOfPallets ?? 0).toString(),
    );

    // Điền sẵn số lượng cũ nhưng người dùng có thể xóa đi nhập lại số kiểm kê thực tế
    _qtyKgCtrl = TextEditingController(
      text: widget.inventory.quantityKg.toString(),
    );
    _qtyConesCtrl = TextEditingController(
      text: widget.inventory.quantityCones.toString(),
    );
  }

  @override
  void dispose() {
    _locationCtrl.dispose();
    _palletsCtrl.dispose();
    _qtyKgCtrl.dispose();
    _qtyConesCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // Khi kiểm kê, lưu lại mốc thời gian kiểm kê mới nhất
      final nowStr = DateTime.now().toIso8601String();

      final updatedInventory = widget.inventory.copyWith(
        location: _locationCtrl.text,
        numberOfPallets: int.tryParse(_palletsCtrl.text) ?? 0,
        quantityKg: double.tryParse(_qtyKgCtrl.text) ?? 0.0,
        quantityCones: int.tryParse(_qtyConesCtrl.text) ?? 0,
        lastCountedDate: nowStr,
      );

      context.read<MaterialInventoryCubit>().saveInventory(
        inventory: updatedInventory,
        isEdit: true,
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final numFmt = NumberFormat("#,##0.##", "en_US");

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.inventory_rounded, color: Color(0xFF003366)),
          SizedBox(width: 8),
          Text(
            "Kiểm Kê & Điều Chỉnh Kho",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SizedBox(
        width: 450,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thông tin Lô hiện tại
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blueGrey.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Mã NVL: ${widget.inventory.materialId}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        Text(
                          "Lô: ${widget.inventory.batchCode ?? widget.inventory.batchId}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Thuộc PO: ${widget.inventory.poNumber ?? 'Không xác định'}",
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const Text(
                "1. Vị trí & Đóng gói",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _locationCtrl,
                      decoration: const InputDecoration(
                        labelText: "Vị trí (Bin/Kệ)",
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (val) => val!.isEmpty ? "Trống" : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
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
              const Divider(height: 32),

              const Text(
                "2. Ghi nhận Kiểm đếm",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // [THÊM MỚI]: Bảng đối chiếu Cũ - Mới
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.history, size: 20, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Số lượng Tồn hệ thống (Cũ):",
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${numFmt.format(widget.inventory.quantityKg)} Kg - ${widget.inventory.quantityCones} Cuộn",
                            style: TextStyle(
                              color: Colors.orange.shade900,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _qtyKgCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: "Thực tế kiểm đếm (Kg)",
                        border: const OutlineInputBorder(),
                        isDense: true,
                        fillColor: Colors.green.shade50,
                        filled: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _qtyConesCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Thực tế (Cuộn)",
                        border: const OutlineInputBorder(),
                        isDense: true,
                        fillColor: Colors.green.shade50,
                        filled: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                "* Cập nhật số liệu mới sẽ ghi đè lên tồn kho hệ thống và làm thay đổi báo cáo Tài sản.",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Hủy bỏ"),
        ),
        ElevatedButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.save, size: 16),
          label: const Text("Xác nhận & Cập nhật"),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF003366),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
