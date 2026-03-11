// C:\Users\nhan_\Documents\production_app_frontend\lib\features\inventory\bom\presentation\screens\material_detail_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dropdown_search/dropdown_search.dart';

// Domain
import '../../domain/bom_model.dart';
import '../../../../inventory/material/domain/material_model.dart';

// Cubit - Sử dụng alias mat_bloc
import '../../../../inventory/material/presentation/bloc/material_cubit.dart'
    as mat_bloc;

class MaterialDetailDialog extends StatefulWidget {
  final BOMDetail? detail;
  final int bomId;

  const MaterialDetailDialog({super.key, this.detail, required this.bomId});

  @override
  State<MaterialDetailDialog> createState() => _MaterialDetailDialogState();
}

class _MaterialDetailDialogState extends State<MaterialDetailDialog> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _threadsCtrl = TextEditingController();
  final _yarnTypeCtrl = TextEditingController();
  final _twistCtrl = TextEditingController();
  final _crossweaveCtrl = TextEditingController();
  final _actualLenCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  BOMComponentType _selectedType = BOMComponentType.ground;
  int? _selectedMaterialId;

  // [NEW] Biến lưu Dtex để đồng bộ logic với màn hình Create
  double _currentDtex = 0.0;

  @override
  void initState() {
    super.initState();
    context.read<mat_bloc.MaterialCubit>().loadMaterials();

    if (widget.detail != null) {
      final d = widget.detail!;
      _selectedType = d.componentType;
      _selectedMaterialId = d.materialId;
      _threadsCtrl.text = d.threads.toString();
      _yarnTypeCtrl.text = d.yarnTypeName;
      _twistCtrl.text = d.twisted.toString();
      _crossweaveCtrl.text = d.crossweaveRate.toString();
      _actualLenCtrl.text = d.actualLengthCm.toString();
      _noteCtrl.text = d.note;

      // Load Dtex hiện tại
      _currentDtex = d.yarnDtex;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Helper tạo style input giống màn hình CreateBOMScreen
    InputDecoration inputDeco(String label, {IconData? icon}) {
      return InputDecoration(
        labelText: label,
        prefixIcon: icon != null
            ? Icon(icon, size: 18, color: Colors.grey)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        isDense: true,
      );
    }

    return AlertDialog(
      title: Text(widget.detail == null ? "Add Component" : "Edit Component"),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Component Type
                DropdownButtonFormField<BOMComponentType>(
                  value: _selectedType,
                  decoration: inputDeco("Type"),
                  items: BOMComponentType.values
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          // [STYLE] Đồng bộ style chữ đậm
                          child: Text(
                            e.name.toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _selectedType = val!),
                ),
                const SizedBox(height: 12),

                // 2. Material Select (DropdownSearch)
                BlocBuilder<mat_bloc.MaterialCubit, mat_bloc.MaterialState>(
                  builder: (context, state) {
                    List<MaterialItem> materials = [];
                    if (state is mat_bloc.MaterialLoaded) {
                      materials = state.materials;
                    }

                    return DropdownSearch<MaterialItem>(
                      items: (filter, props) {
                        if (filter.isEmpty) return materials;
                        return materials
                            .where(
                              (m) => m.materialCode.toLowerCase().contains(
                                filter.toLowerCase(),
                              ),
                            )
                            .toList();
                      },
                      itemAsString: (m) => m.materialCode,
                      selectedItem: materials
                          .where((m) => m.materialId == _selectedMaterialId)
                          .firstOrNull,
                      compareFn: (i, s) => i.materialId == s.materialId,

                      // [STYLE] Decorator giống màn hình Create
                      decoratorProps: DropDownDecoratorProps(
                        decoration: inputDeco("Material", icon: Icons.search),
                      ),

                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        itemBuilder: (ctx, item, isDisabled, isSelected) =>
                            ListTile(
                              title: Text(
                                item.materialCode,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                "${item.materialType ?? '-'} | ${item.dtex ?? ''}",
                              ),
                              selected: isSelected,
                            ),
                      ),
                      onChanged: (m) {
                        if (m != null) {
                          setState(() {
                            _selectedMaterialId = m.materialId;

                            // Auto-fill tên sợi nếu chưa nhập
                            _yarnTypeCtrl.text =
                                "${m.materialCode} ${m.dtex ?? ''}";

                            // [LOGIC] Tự động cập nhật Dtex từ Material
                            if (m.dtex != null) {
                              _currentDtex =
                                  double.tryParse(m.dtex.toString()) ?? 0.0;
                            } else {
                              _currentDtex = 0.0;
                            }
                          });
                        }
                      },
                      validator: (m) => m == null ? "Required" : null,
                    );
                  },
                ),
                const SizedBox(height: 12),

                // 3. Yarn Name
                TextFormField(
                  controller: _yarnTypeCtrl,
                  decoration: inputDeco("Yarn Name / Code"),
                  validator: (v) => v!.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 12),

                // 4. Tech Specs
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _threadsCtrl,
                        decoration: inputDeco("Threads (Ends)"),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _twistCtrl,
                        decoration: inputDeco("Twist"),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 5. Length & Crossweave
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _actualLenCtrl,
                        decoration: inputDeco("Actual Len (cm)"),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _crossweaveCtrl,
                        decoration: inputDeco(
                          "Crossweave (%)",
                        ), // Sửa label cho rõ nghĩa giống màn create
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),

                // [Optional] Hiển thị Dtex để kiểm tra
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                  child: Text(
                    "Current Dtex: ${_currentDtex.toStringAsFixed(0)}",
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _noteCtrl,
                  decoration: inputDeco("Note"),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final newDetail = BOMDetail(
                detailId: widget.detail?.detailId ?? 0,
                bomId: widget.bomId,
                materialId: _selectedMaterialId ?? 1,
                componentType: _selectedType,
                threads: int.tryParse(_threadsCtrl.text) ?? 0,
                yarnTypeName: _yarnTypeCtrl.text,
                twisted: double.tryParse(_twistCtrl.text) ?? 1.0,
                crossweaveRate: double.tryParse(_crossweaveCtrl.text) ?? 0.0,
                actualLengthCm: double.tryParse(_actualLenCtrl.text) ?? 0.0,
                note: _noteCtrl.text,

                // [FIX] Sử dụng biến _currentDtex để lưu chính xác độ mảnh sợi
                yarnDtex: _currentDtex,

                // Các trường tính toán để 0 hoặc giữ nguyên từ bản ghi cũ, Backend sẽ tính lại
                weightPerYarnGm: widget.detail?.weightPerYarnGm ?? 0,
                actualWeightCal: widget.detail?.actualWeightCal ?? 0,
                weightPercentage: widget.detail?.weightPercentage ?? 0,
                bomGm: widget.detail?.bomGm ?? 0,
              );
              Navigator.pop(context, newDetail);
            }
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}
