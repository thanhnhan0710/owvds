import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  late TextEditingController _qtyKgCtrl;
  late TextEditingController _qtyConesCtrl;

  @override
  void initState() {
    super.initState();
    _locationCtrl = TextEditingController(text: widget.inventory.location);
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
    _qtyKgCtrl.dispose();
    _qtyConesCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final updatedInventory = widget.inventory.copyWith(
        location: _locationCtrl.text,
        quantityKg: double.tryParse(_qtyKgCtrl.text) ?? 0.0,
        quantityCones: int.tryParse(_qtyConesCtrl.text) ?? 0,
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
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.edit_note, color: Color(0xFF003366)),
          SizedBox(width: 8),
          Text(
            "Điều chỉnh Tồn Kho",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Vật tư: NVL-${widget.inventory.materialId}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Lô: Batch-${widget.inventory.batchId}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
              ),
              TextFormField(
                controller: _locationCtrl,
                decoration: const InputDecoration(
                  labelText: "Vị trí trong kho (Bin/Kệ)",
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (val) => val!.isEmpty ? "Không được để trống" : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _qtyKgCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: "Khả dụng (Kg)",
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _qtyConesCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Khả dụng (Cuộn)",
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                "* Lưu ý: Thao tác này ghi đè số lượng tồn kho thực tế. Chỉ sử dụng khi chuyển vị trí hoặc có biên bản kiểm kê chênh lệch.",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange,
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
          child: const Text("Hủy"),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF003366),
            foregroundColor: Colors.white,
          ),
          child: const Text("Cập nhật"),
        ),
      ],
    );
  }
}
