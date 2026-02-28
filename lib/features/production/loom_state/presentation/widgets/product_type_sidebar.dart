import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:owvds/features/production/loom_state/product/domain/product_model.dart';
import 'package:owvds/features/production/loom_state/product/presentation/bloc/product_cubit.dart';
import 'package:owvds/features/production/loom_state/product_type/presentation/bloc/product_type_cubit.dart';
import '../dialogs/product_type_dialog.dart';

class ProductTypeSidebar extends StatelessWidget {
  final int? selectedTypeId;
  final Function(int?) onTypeSelected;

  const ProductTypeSidebar({
    super.key,
    required this.selectedTypeId,
    required this.onTypeSelected,
  });

  final Color _primaryColor = const Color(0xFF003366);

  Color _getColorForType(int? id) {
    if (id == null) return Colors.blueGrey;
    return Colors.primaries[id % Colors.primaries.length];
  }

  void _confirmDelete(BuildContext context, int id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa loại "$name" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<ProductTypeCubit>().deleteProductType(id);
              if (selectedTypeId == id) onTypeSelected(null);
              Navigator.pop(ctx);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          // [SỬA] Đổi nút Thêm Loại sang dạng có text rõ ràng
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Phân loại",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor.withOpacity(
                      0.1,
                    ), // Nền màu xanh nhạt
                    foregroundColor: _primaryColor, // Chữ màu xanh đậm
                    elevation: 0, // Bỏ bóng để nhìn phẳng, hiện đại
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 0,
                    ),
                    minimumSize: const Size(0, 32), // Thu nhỏ chiều cao nút
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text(
                    'Thêm loại',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => const ProductTypeDialog(),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm loại...',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (val) {
                if (val.trim().isEmpty) {
                  context.read<ProductTypeCubit>().loadProductTypes();
                } else {
                  context.read<ProductTypeCubit>().searchProductTypes(val);
                }
              },
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: BlocBuilder<ProductCubit, ProductState>(
              builder: (context, productState) {
                int totalProducts = 0;
                List<Product> allProducts = [];

                if (productState is ProductLoaded) {
                  allProducts = productState.allProducts;
                  totalProducts = allProducts.length;
                }

                return BlocBuilder<ProductTypeCubit, ProductTypeState>(
                  builder: (context, typeState) {
                    if (typeState is ProductTypeLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (typeState is ProductTypeLoaded) {
                      final types = typeState.productTypes;
                      return ListView(
                        children: [
                          _buildTypeItem(
                            context,
                            id: null,
                            name: "Tất cả sản phẩm",
                            count: totalProducts,
                            color: Colors.blueGrey,
                          ),
                          ...types.map((t) {
                            int typeCount = allProducts
                                .where((p) => p.productTypeId == t.id)
                                .length;
                            return _buildTypeItem(
                              context,
                              id: t.id,
                              name: t.typeName,
                              count: typeCount,
                              color: _getColorForType(t.id),
                              onEdit: () => showDialog(
                                context: context,
                                builder: (_) =>
                                    ProductTypeDialog(productType: t),
                              ),
                              onDelete: () =>
                                  _confirmDelete(context, t.id, t.typeName),
                            );
                          }),
                        ],
                      );
                    }
                    return const SizedBox();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeItem(
    BuildContext context, {
    required int? id,
    required String name,
    required int count,
    required Color color,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    final isSelected = selectedTypeId == id;

    return Container(
      color: isSelected ? _primaryColor.withOpacity(0.08) : Colors.transparent,
      child: ListTile(
        selected: isSelected,
        contentPadding: const EdgeInsets.only(left: 16, right: 8),
        leading: CircleAvatar(
          radius: 14,
          backgroundColor: color.withOpacity(0.2),
          child: Icon(
            id == null ? Icons.grid_view : Icons.label,
            size: 16,
            color: color,
          ),
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
        subtitle: Text(
          "$count sản phẩm",
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        trailing: id == null
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 16),
                    onPressed: onEdit,
                    splashRadius: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: Colors.redAccent,
                    ),
                    onPressed: onDelete,
                    splashRadius: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
        onTap: () => onTypeSelected(id),
      ),
    );
  }
}
