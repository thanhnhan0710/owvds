import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:owvds/features/production/machine/machine_type/domain/machine_type_model.dart';
import 'package:owvds/features/production/machine/machine_type/presentation/bloc/machine_type_cubit.dart';

class MachineTypeDialog extends StatefulWidget {
  final MachineType? type;
  const MachineTypeDialog({super.key, this.type});

  @override
  State<MachineTypeDialog> createState() => _MachineTypeDialogState();
}

class _MachineTypeDialogState extends State<MachineTypeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.type != null) {
      _nameController.text = widget.type!.typeName;
      _descController.text = widget.type!.description ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.type != null;
    return AlertDialog(
      title: Text(
        isEdit ? 'Sửa loại máy' : 'Thêm loại máy',
        style: const TextStyle(
          color: Color(0xFF003366),
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên loại (*)',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Vui lòng nhập tên loại' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Mô tả',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
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
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final newType = MachineType(
                id: isEdit ? widget.type!.id : 0,
                typeName: _nameController.text.trim(),
                description: _descController.text.trim(),
              );
              context.read<MachineTypeCubit>().saveType(
                type: newType,
                isEdit: isEdit,
              );
              Navigator.pop(context); // Đóng form
            }
          },
          child: Text(isEdit ? 'Lưu' : 'Thêm'),
        ),
      ],
    );
  }
}
