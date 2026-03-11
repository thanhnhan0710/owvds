import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dropdown_search/dropdown_search.dart';

import 'package:owvds/features/qc/loom_state_standard/domain/loom_state_standard_model.dart';
import 'package:owvds/features/qc/loom_state_standard/presentation/bloc/loom_state_standard_cubit.dart';

import 'package:owvds/features/production/loom_state/product/presentation/bloc/product_cubit.dart';
import 'package:owvds/features/production/loom_state/product/domain/product_model.dart';

class StandardDialog extends StatefulWidget {
  final Standard? standard; // Nếu có -> Chế độ Sửa

  const StandardDialog({super.key, this.standard});

  @override
  State<StandardDialog> createState() => _StandardDialogState();
}

class _StandardDialogState extends State<StandardDialog> {
  final _formKey = GlobalKey<FormState>();

  int? _selectedProductId;
  final TextEditingController _widthCtrl = TextEditingController();
  final TextEditingController _thickCtrl = TextEditingController();
  final TextEditingController _strengthCtrl = TextEditingController();
  final TextEditingController _elongationCtrl = TextEditingController();
  final TextEditingController _curvedCtrl = TextEditingController();
  final TextEditingController _densityCtrl = TextEditingController();
  final TextEditingController _weightCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();

  bool get isEdit => widget.standard != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      final s = widget.standard!;
      _selectedProductId = s.productId;
      _widthCtrl.text = s.widthMm;
      _thickCtrl.text = s.thicknessMm;
      _strengthCtrl.text = s.breakingStrengthDan;
      _elongationCtrl.text = s.elongationAtLoadPercent;
      _curvedCtrl.text = s.curved ?? '';
      _densityCtrl.text = s.weftDensity;
      _weightCtrl.text = s.weightGm;
      _noteCtrl.text = s.note ?? '';
    }
  }

  @override
  void dispose() {
    _widthCtrl.dispose();
    _thickCtrl.dispose();
    _strengthCtrl.dispose();
    _elongationCtrl.dispose();
    _curvedCtrl.dispose();
    _densityCtrl.dispose();
    _weightCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProductId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Vui lòng chọn Sản phẩm")));
      return;
    }

    final std = Standard(
      standardId: isEdit ? widget.standard!.standardId : 0,
      productId: _selectedProductId!,
      widthMm: _widthCtrl.text.trim(),
      thicknessMm: _thickCtrl.text.trim(),
      breakingStrengthDan: _strengthCtrl.text.trim(),
      elongationAtLoadPercent: _elongationCtrl.text.trim(),
      curved: _curvedCtrl.text.trim(),
      weftDensity: _densityCtrl.text.trim(),
      weightGm: _weightCtrl.text.trim(),
      note: _noteCtrl.text.trim(),
    );

    context.read<StandardCubit>().saveStandard(standard: std, isEdit: isEdit);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: isMobile ? double.infinity : 700,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEdit ? "Sửa Tiêu Chuẩn" : "Thêm Tiêu Chuẩn Mới",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003366),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Sử dụng DropdownSearch phiên bản 6.0.0
                BlocBuilder<ProductCubit, ProductState>(
                  builder: (context, state) {
                    List<Product> products = [];
                    if (state is ProductLoaded) {
                      products = state.allProducts;
                    }

                    // Tìm sản phẩm đã chọn (nếu có) để hiển thị ban đầu
                    Product? selectedProduct;
                    if (_selectedProductId != null) {
                      try {
                        selectedProduct = products.firstWhere(
                          (p) => p.id == _selectedProductId,
                        );
                      } catch (e) {
                        selectedProduct = null;
                      }
                    }

                    return DropdownSearch<Product>(
                      // [V6 UPDATE] items giờ nhận một function thay vì List
                      items: (String filter, dynamic loadProps) {
                        if (filter.isEmpty) {
                          return products;
                        }
                        return products
                            .where(
                              (p) => p.itemCode.toLowerCase().contains(
                                filter.toLowerCase(),
                              ),
                            )
                            .toList();
                      },
                      itemAsString: (Product p) => p.itemCode,
                      compareFn: (p1, p2) => p1.id == p2.id,
                      selectedItem: selectedProduct,
                      enabled:
                          !isEdit, // Sửa thì khóa lại không cho chọn mã khác
                      popupProps: const PopupProps.menu(
                        showSearchBox: true,
                        searchFieldProps: TextFieldProps(
                          decoration: InputDecoration(
                            hintText: "Tìm kiếm mã sản phẩm...",
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      // [V6 UPDATE] Đổi từ dropdownDecoratorProps sang decoratorProps
                      decoratorProps: const DropDownDecoratorProps(
                        decoration: InputDecoration(
                          labelText: "Mã Sản phẩm (*)",
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                        ),
                      ),
                      onChanged: (Product? data) {
                        if (data != null) {
                          setState(() {
                            _selectedProductId = data.id;
                          });
                        }
                      },
                      validator: (Product? item) {
                        if (item == null) return "Bắt buộc chọn";
                        return null;
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),

                const Text(
                  "Thông số Vật lý",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _widthCtrl,
                        decoration: const InputDecoration(
                          labelText: "Chiều rộng (mm)",
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (v) => v!.isEmpty ? "*" : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _thickCtrl,
                        decoration: const InputDecoration(
                          labelText: "Độ dày (mm)",
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (v) => v!.isEmpty ? "*" : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _strengthCtrl,
                        decoration: const InputDecoration(
                          labelText: "Lực đứt (daN)",
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (v) => v!.isEmpty ? "*" : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _elongationCtrl,
                        decoration: const InputDecoration(
                          labelText: "Giãn dài (%)",
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (v) => v!.isEmpty ? "*" : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                const Text(
                  "Ngoại quan & Mật độ",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _densityCtrl,
                        decoration: const InputDecoration(
                          labelText: "Mật độ ngang",
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (v) => v!.isEmpty ? "*" : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _weightCtrl,
                        decoration: const InputDecoration(
                          labelText: "Trọng lượng (g/m)",
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (v) => v!.isEmpty ? "*" : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _curvedCtrl,
                        decoration: const InputDecoration(
                          labelText: "Độ cong",
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _noteCtrl,
                  decoration: const InputDecoration(
                    labelText: "Ghi chú",
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  maxLines: 2,
                ),

                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Hủy"),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF003366),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _submit,
                        child: Text(isEdit ? "Lưu Thay Đổi" : "Tạo Mới"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
