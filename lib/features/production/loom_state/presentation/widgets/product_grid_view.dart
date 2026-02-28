import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:owvds/features/production/loom_state/product/domain/product_model.dart';
import 'package:owvds/features/production/loom_state/product/presentation/bloc/product_cubit.dart';

import '../dialogs/product_dialog.dart';

class ProductGridView extends StatelessWidget {
  final int? selectedTypeId;

  const ProductGridView({super.key, this.selectedTypeId});
  final Color _primaryColor = const Color(0xFF003366);

  Color _getColorForType(int? id) {
    if (id == null) return Colors.blueGrey;
    return Colors.primaries[id % Colors.primaries.length];
  }

  void _confirmDelete(BuildContext context, int id, String code) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa mã SP "$code" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<ProductCubit>().deleteProduct(id);
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
    // Kiểm tra xem có phải màn hình điện thoại không
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm theo mã, ghi chú...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) {
                    if (val.trim().isEmpty) {
                      context.read<ProductCubit>().loadProducts(
                        typeId: selectedTypeId,
                      );
                    } else {
                      context.read<ProductCubit>().searchProducts(val);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),

              // [SỬA]: Nút Thêm sản phẩm có chứa Text rõ ràng
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
                ),
                icon: const Icon(Icons.add, size: 20),
                // Responsive: Hiện "Thêm" trên mobile để chống tràn, "Thêm sản phẩm" trên màn hình to
                label: Text(
                  isMobile ? 'Thêm' : 'Thêm sản phẩm',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => ProductDialog(initialTypeId: selectedTypeId),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: BlocBuilder<ProductCubit, ProductState>(
            builder: (context, state) {
              if (state is ProductLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is ProductError) {
                return Center(
                  child: Text(
                    state.message,
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              } else if (state is ProductLoaded) {
                final products = state.displayedProducts;

                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Không có sản phẩm nào",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount = 2;
                    if (constraints.maxWidth >= 1000)
                      crossAxisCount = 4;
                    else if (constraints.maxWidth >= 600)
                      crossAxisCount = 3;

                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        return _buildProductCard(context, products[index]);
                      },
                    );
                  },
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(BuildContext context, Product p) {
    final typeColor = _getColorForType(p.productTypeId);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.grey.shade100,
              child: p.imageUrl.isNotEmpty
                  ? Image.network(
                      p.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => const Icon(
                        Icons.broken_image,
                        size: 50,
                        color: Colors.grey,
                      ),
                    )
                  : Icon(
                      Icons.image_not_supported,
                      size: 50,
                      color: Colors.grey.shade300,
                    ),
            ),
          ),
          Container(height: 4, width: double.infinity, color: typeColor),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.itemCode,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    p.productType?.typeName ?? "Chưa phân loại",
                    style: TextStyle(
                      color: typeColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  p.note.isEmpty ? 'Không có ghi chú' : p.note,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => ProductDialog(product: p),
                  ),
                  child: const Text('Sửa', style: TextStyle(fontSize: 12)),
                ),
              ),
              Container(width: 1, height: 20, color: Colors.grey.shade300),
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () => _confirmDelete(context, p.id, p.itemCode),
                  child: const Text('Xóa', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
