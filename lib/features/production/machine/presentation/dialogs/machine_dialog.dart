import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:owvds/features/area/presentation/bloc/area_cubit.dart';
import 'package:owvds/features/production/machine/machine/domain/machine_model.dart';
import 'package:owvds/features/production/machine/machine/presentation/bloc/machine_cubit.dart';
import 'package:owvds/features/production/machine/machine_status/presentation/bloc/machine_status_cubit.dart';
import 'package:owvds/features/production/machine/machine_type/presentation/bloc/machine_type_cubit.dart';

class MachineDialog extends StatefulWidget {
  final Machine? machine;
  final int? initialAreaId;
  final int? initialTypeId;

  const MachineDialog({
    super.key,
    this.machine,
    this.initialAreaId,
    this.initialTypeId,
  });

  @override
  State<MachineDialog> createState() => _MachineDialogState();
}

class _MachineDialogState extends State<MachineDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _serialController = TextEditingController();

  final Map<String, String> _supportedPolyTypes = {
    'base_machine': 'Máy Cơ Bản (Chung)',
    'weaving_machine': 'Hệ Máy Dệt',
    'dyeing_machine': 'Hệ Máy Nhuộm',
  };

  String _polyType = 'base_machine';

  final _linesController = TextEditingController();
  final _speedController = TextEditingController();
  final _capacityController = TextEditingController();
  final _tempController = TextEditingController();

  int? _selectedAreaId;
  int? _selectedTypeId;
  int? _selectedStatusId;

  @override
  void initState() {
    super.initState();

    // [ĐÃ XÓA]: Xóa 3 dòng load data ở đây vì màn hình cha đã load sẵn.
    // Nếu gọi lại sẽ làm Cubit chuyển sang Loading, khiến thuật toán bên dưới thất bại.

    if (widget.machine != null) {
      _initEditMode();
    } else {
      _initCreateMode();
    }
  }

  // =========================================================
  // THUẬT TOÁN NHẬN DIỆN HỆ MÁY THÔNG MINH KÉP (SMART DETECT V3)
  // =========================================================
  void _autoSelectSystemStructure(int? typeId) {
    if (typeId == null) return;

    // 1. Quét tìm trong danh sách máy đã tạo
    try {
      final machineState = context.read<MachineCubit>().state;
      if (machineState is MachineLoaded) {
        final sample = machineState.allMachines.firstWhere(
          (m) => m.machineTypeId == typeId,
        );
        setState(() => _polyType = sample.polymorphicType);
        return;
      }
    } catch (_) {}

    // 2. Nội suy tên danh mục (Bao gồm cả CÓ DẤU và KHÔNG DẤU)
    final typeState = context.read<MachineTypeCubit>().state;
    if (typeState is MachineTypeLoaded) {
      try {
        final typeObj = typeState.types.firstWhere((t) => t.id == typeId);
        final name = typeObj.typeName.toLowerCase();

        if (name.contains('nhuộm') || name.contains('nhuom')) {
          setState(() => _polyType = 'dyeing_machine');
        } else if (name.contains('dệt') ||
            name.contains('det') ||
            name.contains('kim') ||
            name.contains('thoi')) {
          setState(() => _polyType = 'weaving_machine');
        } else {
          setState(() => _polyType = 'base_machine');
        }
      } catch (_) {}
    }
  }

  void _initEditMode() {
    final m = widget.machine!;
    _nameController.text = m.machineName;
    _serialController.text = m.serialNumber ?? '';
    _selectedAreaId = m.areaId;
    _selectedTypeId = m.machineTypeId;
    _selectedStatusId = m.statusId;
    _polyType = _supportedPolyTypes.containsKey(m.polymorphicType)
        ? m.polymorphicType
        : 'base_machine';

    if (_polyType == 'weaving_machine') {
      _linesController.text = m.totalLines?.toString() ?? '';
      _speedController.text = m.speed?.toString() ?? '';
    } else if (_polyType == 'dyeing_machine') {
      _capacityController.text = m.capacityKg?.toString() ?? '';
      _tempController.text = m.maxTemperature?.toString() ?? '';
    }
  }

  void _initCreateMode() {
    _selectedAreaId = widget.initialAreaId;
    _selectedTypeId = widget.initialTypeId;
    _autoSelectSystemStructure(_selectedTypeId);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.machine != null;

    return AlertDialog(
      title: Text(
        isEdit ? 'Cập nhật thiết bị' : 'Thêm thiết bị mới',
        style: const TextStyle(
          color: Color(0xFF003366),
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _polyType,
                  decoration: InputDecoration(
                    labelText: 'Cấu trúc hệ thống máy',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.blue.shade50,
                  ),
                  items: _supportedPolyTypes.entries.map((e) {
                    return DropdownMenuItem(
                      value: e.key,
                      child: Text(
                        e.value,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003366),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _polyType = val!);
                  },
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên máy (*)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Vui lòng nhập tên máy' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _serialController,
                  decoration: const InputDecoration(
                    labelText: 'Số Seri',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(child: _buildAreaDropdown()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTypeDropdown()),
                  ],
                ),
                const SizedBox(height: 16),
                _buildStatusDropdown(),
                const SizedBox(height: 16),
                const Divider(),

                _buildSpecificFields(),
              ],
            ),
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
          onPressed: _submitForm,
          child: Text(isEdit ? 'Lưu thay đổi' : 'Thêm mới'),
        ),
      ],
    );
  }

  Widget _buildSpecificFields() {
    switch (_polyType) {
      case 'weaving_machine':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Thông số Máy Dệt",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _linesController,
                    decoration: const InputDecoration(
                      labelText: 'Tổng số line',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _speedController,
                    decoration: const InputDecoration(
                      labelText: 'Tốc độ (RPM)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        );
      case 'dyeing_machine':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Thông số Máy Nhuộm",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _capacityController,
                    decoration: const InputDecoration(
                      labelText: 'Công suất (Kg)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _tempController,
                    decoration: const InputDecoration(
                      labelText: 'Nhiệt độ tối đa (°C)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        );
      case 'base_machine':
      default:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Center(
            child: Text(
              "Hệ máy cơ bản không có thông số kỹ thuật đặc thù.",
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ),
        );
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final isEdit = widget.machine != null;

      final newMachine = Machine(
        id: isEdit ? widget.machine!.id : 0,
        machineName: _nameController.text.trim(),
        serialNumber: _serialController.text.trim(),
        areaId: _selectedAreaId,
        machineTypeId: _selectedTypeId,
        statusId: _selectedStatusId,
        polymorphicType: _polyType,
        totalLines: _polyType == 'weaving_machine'
            ? int.tryParse(_linesController.text)
            : null,
        speed: _polyType == 'weaving_machine'
            ? int.tryParse(_speedController.text)
            : null,
        capacityKg: _polyType == 'dyeing_machine'
            ? double.tryParse(_capacityController.text)
            : null,
        maxTemperature: _polyType == 'dyeing_machine'
            ? double.tryParse(_tempController.text)
            : null,
      );

      context.read<MachineCubit>().saveMachine(
        machine: newMachine,
        isEdit: isEdit,
      );
      Navigator.pop(context);
    }
  }

  Widget _buildAreaDropdown() {
    return BlocBuilder<AreaCubit, AreaState>(
      builder: (context, state) {
        if (state is AreaLoaded) {
          bool exists =
              _selectedAreaId == null ||
              state.areas.any((a) => a.id == _selectedAreaId);
          return DropdownButtonFormField<int>(
            initialValue: exists ? _selectedAreaId : null,
            decoration: const InputDecoration(
              labelText: 'Khu vực',
              border: OutlineInputBorder(),
            ),
            items: state.areas
                .map(
                  (a) => DropdownMenuItem(value: a.id, child: Text(a.areaName)),
                )
                .toList(),
            onChanged: (v) => setState(() => _selectedAreaId = v),
          );
        }
        return const CircularProgressIndicator();
      },
    );
  }

  Widget _buildTypeDropdown() {
    return BlocBuilder<MachineTypeCubit, MachineTypeState>(
      builder: (context, state) {
        if (state is MachineTypeLoaded) {
          bool exists =
              _selectedTypeId == null ||
              state.types.any((t) => t.id == _selectedTypeId);
          return DropdownButtonFormField<int>(
            initialValue: exists ? _selectedTypeId : null,
            decoration: const InputDecoration(
              labelText: 'Danh mục Loại (*)',
              border: OutlineInputBorder(),
            ),
            items: state.types
                .map(
                  (t) => DropdownMenuItem(value: t.id, child: Text(t.typeName)),
                )
                .toList(),
            validator: (v) => v == null
                ? 'Vui lòng chọn Loại máy'
                : null, // Thêm validate bắt buộc chọn Loại Máy
            onChanged: (v) {
              setState(() => _selectedTypeId = v);
              _autoSelectSystemStructure(v);
            },
          );
        }
        return const CircularProgressIndicator();
      },
    );
  }

  Widget _buildStatusDropdown() {
    return BlocBuilder<MachineStatusCubit, MachineStatusState>(
      builder: (context, state) {
        if (state is MachineStatusLoaded) {
          bool exists =
              _selectedStatusId == null ||
              state.statuses.any((s) => s.id == _selectedStatusId);
          return DropdownButtonFormField<int>(
            initialValue: exists ? _selectedStatusId : null,
            decoration: const InputDecoration(
              labelText: 'Trạng thái',
              border: OutlineInputBorder(),
            ),
            items: state.statuses
                .map(
                  (s) =>
                      DropdownMenuItem(value: s.id, child: Text(s.statusName)),
                )
                .toList(),
            onChanged: (v) => setState(() => _selectedStatusId = v),
          );
        }
        return const CircularProgressIndicator();
      },
    );
  }
}
