import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:owvds/features/production/loom_state/product_type/domain/product_type_model.dart';
import 'package:owvds/features/production/loom_state/product_type/presentation/bloc/product_type_cubit.dart';

class ProductTypeDialog extends StatefulWidget {
  final ProductType? productType;

  const ProductTypeDialog({super.key, this.productType});

  @override
  State<ProductTypeDialog> createState() => _ProductTypeDialogState();
}

class _ProductTypeDialogState extends State<ProductTypeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final Color _primaryColor = const Color(0xFF003366);

  @override
  void initState() {
    super.initState();
    if (widget.productType != null) {
      _nameController.text = widget.productType!.typeName;
      _descController.text = widget.productType!.description ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.productType != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        isEdit ? 'Cập nhật loại sản phẩm' : 'Thêm loại sản phẩm',
        style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên loại (*)',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => (val == null || val.isEmpty)
                    ? 'Vui lòng nhập tên loại'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Mô tả',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final newType = ProductType(
                id: isEdit ? widget.productType!.id : 0,
                typeName: _nameController.text.trim(),
                description: _descController.text.trim(),
              );
              context.read<ProductTypeCubit>().saveProductType(
                productType: newType,
                isEdit: isEdit,
              );
              Navigator.pop(context);
            }
          },
          child: Text(isEdit ? 'Lưu thay đổi' : 'Thêm mới'),
        ),
      ],
    );
  }
}
