import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:owvds/features/inventory/warehouse/domain/warehouse_model.dart';
import 'package:owvds/features/inventory/warehouse/presentation/bloc/warehouse_cubit.dart';

class WarehouseManagementDialog extends StatelessWidget {
  const WarehouseManagementDialog({super.key});

  @override
  Widget build(BuildContext context) {
    // Gọi load data mỗi khi mở dialog
    context.read<WarehouseCubit>().loadWarehouses();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warehouse, color: Color(0xFF003366), size: 28),
                    SizedBox(width: 12),
                    Text(
                      "Quản Lý Danh Sách Kho",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003366),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Danh sách kho hiện tại",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showWarehouseForm(context, null),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Thêm Kho Mới"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003366),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BlocBuilder<WarehouseCubit, WarehouseState>(
                builder: (context, state) {
                  if (state is WarehouseLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is WarehouseError) {
                    return Center(
                      child: Text(
                        state.message,
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }
                  if (state is WarehouseLoaded) {
                    if (state.warehouses.isEmpty) {
                      return const Center(child: Text("Chưa có dữ liệu Kho."));
                    }
                    return ListView.separated(
                      itemCount: state.warehouses.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final warehouse = state.warehouses[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade50,
                            child: const Icon(
                              Icons.apartment,
                              color: Colors.blue,
                            ),
                          ),
                          title: Text(
                            warehouse.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "Vị trí: ${warehouse.location}\nMT: ${warehouse.description}",
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blueGrey,
                                ),
                                onPressed: () =>
                                    _showWarehouseForm(context, warehouse),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () =>
                                    _confirmDelete(context, warehouse),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWarehouseForm(BuildContext context, Warehouse? warehouse) {
    showDialog(
      context: context,
      builder: (ctx) =>
          _WarehouseFormDialog(warehouse: warehouse, cubitContext: context),
    );
  }

  void _confirmDelete(BuildContext context, Warehouse warehouse) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: Text(
          "Bạn có chắc chắn muốn xóa kho '${warehouse.name}' không?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              context.read<WarehouseCubit>().deleteWarehouse(
                warehouse.warehouseId,
              );
              Navigator.pop(ctx);
            },
            child: const Text("Xóa"),
          ),
        ],
      ),
    );
  }
}

// Dialog Nội bộ: Form Điền thông tin Kho
class _WarehouseFormDialog extends StatefulWidget {
  final Warehouse? warehouse;
  final BuildContext cubitContext;

  const _WarehouseFormDialog({this.warehouse, required this.cubitContext});

  @override
  State<_WarehouseFormDialog> createState() => _WarehouseFormDialogState();
}

class _WarehouseFormDialogState extends State<_WarehouseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _locCtrl;
  late TextEditingController _descCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.warehouse?.name ?? '');
    _locCtrl = TextEditingController(text: widget.warehouse?.location ?? '');
    _descCtrl = TextEditingController(
      text: widget.warehouse?.description ?? '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final warehouse = Warehouse(
        warehouseId: widget.warehouse?.warehouseId ?? 0,
        name: _nameCtrl.text,
        location: _locCtrl.text,
        description: _descCtrl.text,
      );

      widget.cubitContext.read<WarehouseCubit>().saveWarehouse(
        warehouse: warehouse,
        isEdit: widget.warehouse != null,
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.warehouse == null ? "Thêm Kho Mới" : "Sửa Thông Tin Kho",
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: "Tên Kho (*)",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? "Bắt buộc nhập" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locCtrl,
                decoration: const InputDecoration(
                  labelText: "Vị trí / Tòa nhà",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: "Mô tả",
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
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
          child: const Text("Lưu"),
        ),
      ],
    );
  }
}
