import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:owvds/features/area/domain/area_model.dart';
import 'package:owvds/features/area/presentation/bloc/area_cubit.dart';

class AreaDialog extends StatefulWidget {
  final Area? area;
  const AreaDialog({super.key, this.area});

  @override
  State<AreaDialog> createState() => _AreaDialogState();
}

class _AreaDialogState extends State<AreaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.area != null) {
      _nameController.text = widget.area!.areaName;
      _descController.text = widget.area!.description ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.area != null;
    return AlertDialog(
      title: Text(
        isEdit ? 'Cập nhật khu vực' : 'Thêm khu vực mới',
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
                labelText: 'Tên khu vực (*)',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Vui lòng nhập tên' : null,
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
              final newArea = Area(
                id: isEdit ? widget.area!.id : 0,
                areaName: _nameController.text.trim(),
                description: _descController.text.trim(),
              );
              context.read<AreaCubit>().saveArea(area: newArea, isEdit: isEdit);
              Navigator.pop(context);
            }
          },
          child: Text(isEdit ? 'Lưu' : 'Thêm'),
        ),
      ],
    );
  }
}
