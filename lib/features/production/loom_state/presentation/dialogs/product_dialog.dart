import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';

import 'package:owvds/features/production/loom_state/product/domain/product_model.dart';
import 'package:owvds/features/production/loom_state/product/presentation/bloc/product_cubit.dart';
import 'package:owvds/features/production/loom_state/product_type/domain/product_type_model.dart';
import 'package:owvds/features/production/loom_state/product_type/presentation/bloc/product_type_cubit.dart';

class ProductDialog extends StatefulWidget {
  final Product? product;
  final int? initialTypeId; // ID loại SP mặc định (nếu đang lọc theo 1 loại)

  const ProductDialog({super.key, this.product, this.initialTypeId});

  @override
  State<ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<ProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _noteController = TextEditingController();
  int? _selectedTypeId;
  final Color _primaryColor = const Color(0xFF003366);

  // Biến lưu trữ file ảnh được chọn
  PlatformFile? _pickedImageFile;
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _codeController.text = widget.product!.itemCode;
      _noteController.text = widget.product!.note;
      _selectedTypeId = widget.product!.productTypeId;
    } else {
      _selectedTypeId = widget.initialTypeId;
    }
    // Load danh sách loại SP nếu chưa có
    if (context.read<ProductTypeCubit>().state is! ProductTypeLoaded) {
      context.read<ProductTypeCubit>().loadProductTypes();
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // Hàm xử lý chọn ảnh
  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true, // Cần thiết để lấy mảng bytes hiển thị trên Web/Desktop
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _pickedImageFile = result.files.first;
          _imageBytes = result.files.first.bytes;
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  // Lấy ImageProvider để hiển thị (Ưu tiên ảnh vừa chọn, sau đó tới ảnh cũ từ API)
  ImageProvider? _getImageProvider() {
    if (_imageBytes != null) {
      return MemoryImage(_imageBytes!);
    }
    if (widget.product != null && widget.product!.imageUrl.isNotEmpty) {
      return NetworkImage(widget.product!.imageUrl);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;
    final imageProvider = _getImageProvider();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        isEdit ? 'Cập nhật sản phẩm' : 'Thêm sản phẩm',
        style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Khu vực chọn ảnh
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        style: BorderStyle.solid,
                      ),
                      image: imageProvider != null
                          ? DecorationImage(
                              image: imageProvider,
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: imageProvider == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                size: 40,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Nhấn để tải ảnh lên",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          )
                        : Align(
                            alignment: Alignment.topRight,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: CircleAvatar(
                                backgroundColor: Colors.white.withOpacity(0.8),
                                radius: 16,
                                child: Icon(
                                  Icons.edit,
                                  size: 16,
                                  color: _primaryColor,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Mã sản phẩm (*)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => (val == null || val.isEmpty)
                      ? 'Vui lòng nhập mã SP'
                      : null,
                ),
                const SizedBox(height: 16),

                // Dropdown Loại sản phẩm
                BlocBuilder<ProductTypeCubit, ProductTypeState>(
                  builder: (context, state) {
                    List<ProductType> types = [];
                    if (state is ProductTypeLoaded) types = state.productTypes;

                    return DropdownButtonFormField<int>(
                      value: _selectedTypeId,
                      decoration: const InputDecoration(
                        labelText: 'Loại sản phẩm',
                        border: OutlineInputBorder(),
                      ),
                      items: types.map((t) {
                        return DropdownMenuItem<int>(
                          value: t.id,
                          child: Text(t.typeName),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedTypeId = val),
                    );
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú',
                    border: OutlineInputBorder(),
                  ),
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
          child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final newProduct = Product(
                id: isEdit ? widget.product!.id : 0,
                itemCode: _codeController.text.trim(),
                productTypeId: _selectedTypeId,
                note: _noteController.text.trim(),
                imageUrl: isEdit
                    ? widget.product!.imageUrl
                    : '', // Giữ lại URL cũ hoặc rỗng
              );

              // Tích hợp FilePicker đẩy file thực tế xuống Cubit
              context.read<ProductCubit>().saveProduct(
                product: newProduct,
                isEdit: isEdit,
                imageFile: _pickedImageFile, // Truyền file vừa chọn
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
