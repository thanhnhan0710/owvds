import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:owvds/features/production/machine/machine_status/domain/machine_status_model.dart';
import 'package:owvds/features/production/machine/machine_status/presentation/bloc/machine_status_cubit.dart';

class MachineStatusDialog extends StatefulWidget {
  final MachineStatus? status;
  const MachineStatusDialog({super.key, this.status});

  @override
  State<MachineStatusDialog> createState() => _MachineStatusDialogState();
}

class _MachineStatusDialogState extends State<MachineStatusDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  // Biến lưu mã HEX được chọn
  String? _selectedColorHex;

  // Danh sách các màu cơ bản được định nghĩa sẵn
  final List<Map<String, dynamic>> _presetColors = [
    {'hex': '#F44336', 'color': Colors.red},
    {'hex': '#E91E63', 'color': Colors.pink},
    {'hex': '#9C27B0', 'color': Colors.purple},
    {'hex': '#2196F3', 'color': Colors.blue},
    {'hex': '#00BCD4', 'color': Colors.cyan},
    {'hex': '#4CAF50', 'color': Colors.green},
    {'hex': '#8BC34A', 'color': Colors.lightGreen},
    {'hex': '#FFEB3B', 'color': Colors.yellow},
    {'hex': '#FF9800', 'color': Colors.orange},
    {'hex': '#795548', 'color': Colors.brown},
    {'hex': '#9E9E9E', 'color': Colors.grey},
    {'hex': '#607D8B', 'color': Colors.blueGrey},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.status != null) {
      _nameController.text = widget.status!.statusName;
      _descController.text = widget.status!.description ?? '';
      _selectedColorHex = widget.status!.colorCode?.toUpperCase();
    } else {
      // Mặc định chọn màu Xám nếu thêm mới
      _selectedColorHex = '#9E9E9E';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.status != null;
    return AlertDialog(
      title: Text(
        isEdit ? 'Sửa trạng thái' : 'Thêm trạng thái',
        style: const TextStyle(
          color: Color(0xFF003366),
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên trạng thái (*)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Vui lòng nhập tên' : null,
              ),
              const SizedBox(height: 16),

              const Text(
                'Chọn màu sắc:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),

              // Bảng chọn màu
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _presetColors.map((colorMap) {
                  final hex = colorMap['hex'] as String;
                  final color = colorMap['color'] as Color;
                  final isSelected = _selectedColorHex == hex;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColorHex = hex;
                      });
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? Colors.black87
                              : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: color.withOpacity(0.4),
                              blurRadius: 6,
                              spreadRadius: 2,
                            ),
                        ],
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check,
                              color: color.computeLuminance() > 0.5
                                  ? Colors.black
                                  : Colors.white,
                              size: 20,
                            )
                          : null,
                    ),
                  );
                }).toList(),
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
              final newStatus = MachineStatus(
                id: isEdit ? widget.status!.id : 0,
                statusName: _nameController.text.trim(),
                colorCode: _selectedColorHex, // Lưu mã HEX đã chọn từ Palette
                description: _descController.text.trim(),
              );
              context.read<MachineStatusCubit>().saveStatus(
                status: newStatus,
                isEdit: isEdit,
              );
              Navigator.pop(context);
            }
          },
          child: Text(isEdit ? 'Lưu' : 'Thêm'),
        ),
      ],
    );
  }
}
