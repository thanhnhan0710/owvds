import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:owvds/features/inventory/supplier_category/presentation/bloc/supplier_category_cubit.dart';

// ĐẢM BẢO IMPORT ĐÚNG ĐƯỜNG DẪN NÀY (Thoát ra 2 cấp thư mục, rồi vào supplier_category)
import '../../../supplier_category/domain/supplier_category_model.dart';

import '../../domain/supplier_model.dart';
import '../bloc/supplier_cubit.dart';

class SupplierDialogHelper {
  static final Color _primaryColor = const Color(0xFF003366);

  static InputDecoration _inputDeco(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  // =========================================================
  // DIALOG: LOẠI NHÀ CUNG CẤP (ADD / EDIT)
  // =========================================================
  static void showCategoryDialog(
    BuildContext context,
    SupplierCategory? category, {
    Function(SupplierCategory)? onCategorySaved,
  }) {
    final isEdit = category != null;
    final nameCtrl = TextEditingController(text: category?.categoryName ?? '');
    final descCtrl = TextEditingController(text: category?.description ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(
          isEdit ? "Sửa Loại NCC" : "Thêm Loại NCC",
          style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold),
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
                  decoration: _inputDeco("Tên loại (*)"),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? "Bắt buộc nhập" : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descCtrl,
                  decoration: _inputDeco("Mô tả"),
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
                final newCat = SupplierCategory(
                  categoryId: category?.categoryId ?? 0,
                  categoryName: nameCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                );

                if (isEdit) {
                  context.read<SupplierCategoryCubit>().updateCategory(newCat);
                } else {
                  context.read<SupplierCategoryCubit>().addCategory(newCat);
                }

                // Callback để cập nhật lại UI cha nếu cần
                if (onCategorySaved != null) onCategorySaved(newCat);

                Navigator.pop(ctx);
              }
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // DIALOG: NHÀ CUNG CẤP (ADD / EDIT)
  // =========================================================
  static void showSupplierDialog(
    BuildContext context,
    Supplier? supplier,
    int? currentCategoryId,
  ) {
    final isEdit = supplier != null;
    final nameCtrl = TextEditingController(text: supplier?.supplierName ?? '');
    final shortNameCtrl = TextEditingController(
      text: supplier?.shortName ?? '',
    );
    final addressCtrl = TextEditingController(text: supplier?.address ?? '');
    int? selectedCatId = supplier?.categoryId ?? currentCategoryId;
    final formKey = GlobalKey<FormState>();

    // ĐÃ SỬA LỖI CASTING LIST Ở ĐÂY
    final catState = context.read<SupplierCategoryCubit>().state;
    List<SupplierCategory> categories = [];
    if (catState is SupplierCategoryLoaded) {
      categories = List<SupplierCategory>.from(catState.categories);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(
              isEdit ? "Sửa Nhà Cung Cấp" : "Thêm Nhà Cung Cấp",
              style: TextStyle(
                color: _primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Form(
              key: formKey,
              child: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: _inputDeco("Tên nhà cung cấp (*)"),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? "Bắt buộc nhập"
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: shortNameCtrl,
                              decoration: _inputDeco("Tên viết tắt"),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: selectedCatId,
                              decoration: _inputDeco("Phân loại"),
                              items: categories
                                  .map(
                                    (cat) => DropdownMenuItem<int>(
                                      value: cat.categoryId,
                                      child: Text(cat.categoryName),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  setStateDialog(() => selectedCatId = val),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: addressCtrl,
                        decoration: _inputDeco("Địa chỉ"),
                        maxLines: 2,
                      ),
                    ],
                  ),
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
                    final newSup = Supplier(
                      supplierId: supplier?.supplierId ?? 0,
                      supplierName: nameCtrl.text.trim(),
                      shortName: shortNameCtrl.text.trim(),
                      address: addressCtrl.text.trim(),
                      categoryId: selectedCatId,
                      isActive: supplier?.isActive ?? true,
                    );

                    if (isEdit) {
                      context.read<SupplierCubit>().updateSupplier(newSup);
                    } else {
                      context.read<SupplierCubit>().addSupplier(newSup);
                    }

                    Navigator.pop(ctx);
                  }
                },
                child: const Text("Lưu"),
              ),
            ],
          );
        },
      ),
    );
  }

  // =========================================================
  // DIALOG: XÁC NHẬN XÓA CHUNG
  // =========================================================
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
            Text(title, style: const TextStyle(color: Colors.red)),
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
