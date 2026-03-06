import 'package:flutter/material.dart' hide MaterialType;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dropdown_search/dropdown_search.dart';

// Sử dụng Absolute Import để đảm bảo không bao giờ sai đường dẫn
import 'package:owvds/features/inventory/material/domain/material_model.dart';
import 'package:owvds/features/inventory/material/presentation/bloc/material_cubit.dart';

import 'package:owvds/features/inventory/material_type/domain/material_type_model.dart'
    as custom_model;
import 'package:owvds/features/inventory/material_type/presentation/bloc/material_type_cubit.dart';

import 'package:owvds/features/inventory/supplier/domain/supplier_model.dart';
import 'package:owvds/features/inventory/supplier/presentation/bloc/supplier_cubit.dart';

class MaterialDialogHelper {
  static final Color _primaryColor = const Color(0xFF003366);

  static InputDecoration _inputDeco(String label, {Color? fillColor}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13),
      filled: fillColor != null,
      fillColor: fillColor,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      isDense: true,
    );
  }

  // =========================================================
  // DIALOG: THÊM / SỬA LOẠI NGUYÊN VẬT LIỆU
  // =========================================================
  static void showTypeDialog(
    BuildContext context,
    custom_model.MaterialType? type, {
    Function(custom_model.MaterialType)? onSaved,
  }) {
    final isEdit = type != null;
    final nameCtrl = TextEditingController(text: type?.typeName ?? '');
    final descCtrl = TextEditingController(text: type?.description ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(
          isEdit ? "Sửa Phân Loại" : "Thêm Phân Loại",
          style: TextStyle(
            color: _primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: _inputDeco("Tên loại NVL (*)"),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? "Bắt buộc nhập" : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descCtrl,
                  decoration: _inputDeco("Mô tả chi tiết"),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final newType = custom_model.MaterialType(
                  typeId: type?.typeId ?? 0,
                  typeName: nameCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                );

                if (isEdit) {
                  context.read<MaterialTypeCubit>().updateType(newType);
                } else {
                  context.read<MaterialTypeCubit>().addType(newType);
                }

                if (onSaved != null) onSaved(newType);
                Navigator.pop(ctx);
              }
            },
            child: Text(isEdit ? "Cập nhật" : "Tạo mới"),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // DIALOG: THÊM / SỬA NGUYÊN VẬT LIỆU CHI TIẾT
  // =========================================================
  static void showMaterialDialog(
    BuildContext context,
    MaterialItem? material, {
    int? currentTypeId,
    int? currentSupplierId,
  }) {
    final isEdit = material != null;

    final codeCtrl = TextEditingController(text: material?.materialCode ?? '');
    final nameCtrl = TextEditingController(text: material?.materialName ?? '');
    final colorCtrl = TextEditingController(text: material?.color ?? '');
    final dtexCtrl = TextEditingController(
      text: material?.dtex?.toString() ?? '',
    );
    final filCtrl = TextEditingController(text: material?.filament ?? '');
    final minStockCtrl = TextEditingController(
      text: material?.minStockLevel.toString() ?? '0.0',
    );
    final kgCtrl = TextEditingController(
      text: material?.kgPerBobbin?.toString() ?? '',
    );

    int? selectedTypeId = material?.typeId ?? currentTypeId;
    int? selectedSupplierId = material?.supplierId ?? currentSupplierId;

    final formKey = GlobalKey<FormState>();

    List<custom_model.MaterialType> types = [];
    final typeState = context.read<MaterialTypeCubit>().state;
    if (typeState is MaterialTypeLoaded) {
      types = typeState.types;
    }

    List<Supplier> suppliers = [];
    final supState = context.read<SupplierCubit>().state;
    if (supState is SupplierLoaded) {
      suppliers = supState.suppliers;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(
              isEdit ? "Cập Nhật Nguyên Vật Liệu" : "Thêm Nguyên Vật Liệu Mới",
              style: TextStyle(
                color: _primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            content: Form(
              key: formKey,
              child: SizedBox(
                width: 650,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- PHẦN 1 ---
                      const Text(
                        "1. Thông tin cơ bản",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            flex: 2, // ĐÃ ĐIỀU CHỈNH: Mã NVL chiếm 2 phần
                            child: TextFormField(
                              controller: codeCtrl,
                              decoration: _inputDeco("Mã NVL (*)"),
                              validator: (v) => v!.isEmpty ? "Bắt buộc" : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1, // ĐÃ ĐIỀU CHỈNH: Tên NVL chiếm 1 phần
                            child: TextFormField(
                              controller: nameCtrl,
                              decoration: _inputDeco("Tên Nguyên vật liệu (*)"),
                              validator: (v) => v!.isEmpty ? "Bắt buộc" : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          // DROPDOWN SEARCH: TÌM LOẠI NVL
                          Expanded(
                            child: DropdownSearch<custom_model.MaterialType>(
                              popupProps: PopupProps.menu(
                                showSearchBox: true,
                                searchFieldProps: TextFieldProps(
                                  decoration: InputDecoration(
                                    hintText: "Tìm phân loại...",
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              items: (filter, loadProps) => types
                                  .where(
                                    (t) => t.typeName.toLowerCase().contains(
                                      filter.toLowerCase(),
                                    ),
                                  )
                                  .toList(),
                              itemAsString: (custom_model.MaterialType t) =>
                                  t.typeName,
                              compareFn: (item, selectedItem) =>
                                  item.typeId == selectedItem.typeId,
                              selectedItem: types
                                  .where((t) => t.typeId == selectedTypeId)
                                  .firstOrNull,
                              decoratorProps: DropDownDecoratorProps(
                                decoration: _inputDeco("Phân loại (*)"),
                              ),
                              validator: (v) => v == null ? "Bắt buộc" : null,
                              onChanged: (val) => setStateDialog(
                                () => selectedTypeId = val?.typeId,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // DROPDOWN SEARCH: TÌM NHÀ CUNG CẤP
                          Expanded(
                            child: DropdownSearch<Supplier>(
                              popupProps: PopupProps.menu(
                                showSearchBox: true,
                                searchFieldProps: TextFieldProps(
                                  decoration: InputDecoration(
                                    hintText: "Tìm nhà cung cấp...",
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              items: (filter, loadProps) {
                                // Tìm kiếm linh hoạt: khớp cả tên viết tắt và tên đầy đủ
                                return suppliers.where((s) {
                                  final keyword = filter.toLowerCase();
                                  final shortMatch =
                                      s.shortName?.toLowerCase().contains(
                                        keyword,
                                      ) ??
                                      false;
                                  final fullMatch = s.supplierName
                                      .toLowerCase()
                                      .contains(keyword);
                                  return shortMatch || fullMatch;
                                }).toList();
                              },
                              // Ưu tiên hiển thị Tên Viết Tắt. Nếu null hoặc rỗng thì mới hiện tên Đầy Đủ
                              itemAsString: (Supplier s) {
                                if (s.shortName != null &&
                                    s.shortName!.trim().isNotEmpty) {
                                  return s.shortName!;
                                }
                                return s.supplierName;
                              },
                              compareFn: (item, selectedItem) =>
                                  item.supplierId == selectedItem.supplierId,
                              selectedItem: suppliers
                                  .where(
                                    (s) => s.supplierId == selectedSupplierId,
                                  )
                                  .firstOrNull,
                              decoratorProps: DropDownDecoratorProps(
                                decoration: _inputDeco("Nhà cung cấp (*)"),
                              ),
                              validator: (v) => v == null ? "Bắt buộc" : null,
                              onChanged: (val) => setStateDialog(
                                () => selectedSupplierId = val?.supplierId,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // --- PHẦN 2 ---
                      const Text(
                        "2. Thông số kỹ thuật & Quy cách",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: colorCtrl,
                              decoration: _inputDeco("Màu sắc"),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: dtexCtrl,
                              decoration: _inputDeco("Độ mảnh (Dtex)"),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: filCtrl,
                              decoration: _inputDeco("Sợi con (Filament)"),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: minStockCtrl,
                              decoration: _inputDeco(
                                "Tồn tối thiểu (Kg)",
                                fillColor: Colors.yellow.shade50,
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: kgCtrl,
                              decoration: _inputDeco("Quy cách (Kg/Cuộn)"),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  "Hủy bỏ",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.save, size: 18),
                label: const Text("Lưu Dữ Liệu"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    final newItem = MaterialItem(
                      materialId: material?.materialId ?? 0,
                      materialCode: codeCtrl.text.trim(),
                      materialName: nameCtrl.text.trim(),
                      typeId: selectedTypeId,
                      supplierId: selectedSupplierId,
                      color: colorCtrl.text.trim().isEmpty
                          ? null
                          : colorCtrl.text.trim(),
                      dtex: int.tryParse(dtexCtrl.text.trim()),
                      filament: filCtrl.text.trim().isEmpty
                          ? null
                          : filCtrl.text.trim(),
                      minStockLevel:
                          double.tryParse(minStockCtrl.text.trim()) ?? 0.0,
                      kgPerBobbin: double.tryParse(kgCtrl.text.trim()),
                    );

                    if (isEdit) {
                      context.read<MaterialCubit>().updateMaterial(newItem);
                    } else {
                      context.read<MaterialCubit>().addMaterial(newItem);
                    }
                    Navigator.pop(ctx);
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  static void confirmDelete(
    BuildContext context, {
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(content),
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
              onConfirm();
              Navigator.pop(ctx);
            },
            child: const Text("Xóa"),
          ),
        ],
      ),
    );
  }
}
