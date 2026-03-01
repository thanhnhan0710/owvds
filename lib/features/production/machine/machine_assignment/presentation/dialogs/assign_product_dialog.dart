import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:owvds/features/production/loom_state/product/presentation/bloc/product_cubit.dart';
import 'package:owvds/features/production/machine/machine/domain/machine_model.dart';
import 'package:owvds/features/production/machine/machine_assignment/presentation/bloc/gobal_assignment_cubit.dart';

class AssignProductDialog extends StatefulWidget {
  final Machine machine;
  final bool isRunning;
  const AssignProductDialog({
    super.key,
    required this.machine,
    required this.isRunning,
  });

  @override
  State<AssignProductDialog> createState() => _AssignProductDialogState();
}

class _AssignProductDialogState extends State<AssignProductDialog> {
  int? _selectedProductId;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Gán Mã Hàng cho Máy ${widget.machine.machineName}',
        style: const TextStyle(
          color: Color(0xFF003366),
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SizedBox(
        width: 600,
        height: 500,
        child: Column(
          children: [
            if (widget.isRunning)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Máy này đang chạy một mã hàng khác. Việc gán mã mới sẽ tự động DỪNG mã cũ lại và chốt thời gian hiện tại.",
                      ),
                    ),
                  ],
                ),
              ),

            // Thanh tìm kiếm nhanh
            TextField(
              decoration: const InputDecoration(
                hintText: 'Tìm kiếm sản phẩm...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) =>
                  context.read<ProductCubit>().searchProducts(val),
            ),
            const SizedBox(height: 16),

            // Danh sách chọn
            Expanded(
              child: BlocBuilder<ProductCubit, ProductState>(
                builder: (context, state) {
                  if (state is ProductLoaded) {
                    return ListView.separated(
                      itemCount: state.displayedProducts.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final p = state.displayedProducts[index];
                        return RadioListTile<int>(
                          value: p.id,
                          // ignore: deprecated_member_use
                          groupValue: _selectedProductId,
                          // ignore: deprecated_member_use
                          onChanged: (val) =>
                              setState(() => _selectedProductId = val),
                          title: Text(
                            p.itemCode,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          // [ĐÃ SỬA]: Sử dụng p.note thay vì p.productName (Vì Product Model không có productName)
                          subtitle: Text(
                            p.note.isNotEmpty
                                ? p.note
                                : (p.productType?.typeName ??
                                      'Không có ghi chú'),
                          ),
                        );
                      },
                    );
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF003366),
            foregroundColor: Colors.white,
          ),
          onPressed: _selectedProductId == null
              ? null
              : () {
                  context.read<GlobalAssignmentCubit>().assignProduct(
                    widget.machine.id,
                    _selectedProductId!,
                  );
                  Navigator.pop(context);
                },
          child: const Text('Gán Máy'),
        ),
      ],
    );
  }
}
