import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:owvds/features/inventory/supplier/presentation/dialogs/supplier_dialog_helper.dart';
import 'package:owvds/features/inventory/supplier_category/presentation/bloc/supplier_category_cubit.dart';
import '../../../supplier_category/domain/supplier_category_model.dart';

class SupplierCategorySidebar extends StatelessWidget {
  final int? selectedCategoryId;
  final Function(int?, String) onCategorySelected;
  final Function(int) onCategoryDeleted;
  final Function(SupplierCategory) onCategoryUpdated;

  const SupplierCategorySidebar({
    super.key,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    required this.onCategoryDeleted,
    required this.onCategoryUpdated,
  });

  final Color _primaryColor = const Color(0xFF003366);

  Widget _buildSidebarItem({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? _primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? _primaryColor : Colors.grey.shade600,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? _primaryColor : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(right: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Phân loại NCC",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.blue),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: "Thêm loại NCC",
                  onPressed: () =>
                      SupplierDialogHelper.showCategoryDialog(context, null),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: BlocBuilder<SupplierCategoryCubit, SupplierCategoryState>(
              builder: (context, state) {
                if (state is SupplierCategoryLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<SupplierCategory> categories = [];
                if (state is SupplierCategoryLoaded) {
                  categories = state.categories;
                }

                return ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _buildSidebarItem(
                      title: "Tất cả Nhà cung cấp",
                      icon: Icons.storefront,
                      isSelected: selectedCategoryId == null,
                      onTap: () =>
                          onCategorySelected(null, "Tất cả Nhà cung cấp"),
                    ),
                    ...categories.map(
                      (cat) => _buildSidebarItem(
                        title: cat.categoryName,
                        icon: Icons.label_important_outline,
                        isSelected: selectedCategoryId == cat.categoryId,
                        onTap: () => onCategorySelected(
                          cat.categoryId,
                          cat.categoryName,
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_vert,
                            size: 16,
                            color: Colors.grey,
                          ),
                          padding: EdgeInsets.zero,
                          tooltip: "Tùy chọn",
                          onSelected: (val) {
                            if (val == 'edit') {
                              SupplierDialogHelper.showCategoryDialog(
                                context,
                                cat,
                                onCategorySaved: onCategoryUpdated,
                              );
                            }
                            if (val == 'delete') {
                              SupplierDialogHelper.confirmDelete(
                                context,
                                title: "Xóa Phân loại",
                                content:
                                    "Bạn có chắc muốn xóa loại '${cat.categoryName}'?",
                                onConfirm: () {
                                  context
                                      .read<SupplierCategoryCubit>()
                                      .deleteCategory(cat.categoryId);
                                  onCategoryDeleted(cat.categoryId);
                                },
                              );
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text(
                                "Sửa tên loại",
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text(
                                "Xóa loại này",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
