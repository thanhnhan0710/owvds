// [SỬA LỖI 1]: Ẩn MaterialType của Flutter
import 'package:flutter/material.dart' hide MaterialType;
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:owvds/features/inventory/material/presentation/dialogs/material_dialog_helper.dart';

// [SỬA LỖI 1]: Import Model với tên "custom_model"
import 'package:owvds/features/inventory/material_type/domain/material_type_model.dart'
    as custom_model;
import 'package:owvds/features/inventory/material_type/presentation/bloc/material_type_cubit.dart';

class MaterialTypeSidebar extends StatelessWidget {
  final int? selectedTypeId;
  final Function(int?, String) onTypeSelected;

  const MaterialTypeSidebar({
    super.key,
    required this.selectedTypeId,
    required this.onTypeSelected,
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
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? _primaryColor : Colors.grey.shade400,
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? _primaryColor : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // [SỬA LỖI 3]: Cú pháp đúng để kiểm tra null trong List/Row
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
        color: Colors.white,
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
                Row(
                  children: [
                    // [SỬA LỖI 2]: Dùng Icons.layers thay vì layer_group (không tồn tại trong Flutter)
                    Icon(Icons.layers, color: Colors.blue.shade600, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      "Phân loại NVL",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.add_circle, color: Colors.blue.shade600),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: "Thêm loại",
                  onPressed: () =>
                      MaterialDialogHelper.showTypeDialog(context, null),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: BlocBuilder<MaterialTypeCubit, MaterialTypeState>(
              builder: (context, state) {
                if (state is MaterialTypeLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                // [SỬA LỖI 1]: Sử dụng custom_model.MaterialType
                List<custom_model.MaterialType> types = [];
                if (state is MaterialTypeLoaded) {
                  types = state.types;
                }

                return ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _buildSidebarItem(
                      title: "Tất cả Nguyên vật liệu",
                      icon: Icons.widgets,
                      isSelected: selectedTypeId == null,
                      onTap: () =>
                          onTypeSelected(null, "Tất cả Nguyên vật liệu"),
                    ),
                    ...types.map(
                      // Ép kiểu tường minh để báo cho Dart hiểu rõ
                      (custom_model.MaterialType t) => _buildSidebarItem(
                        title: t.typeName,
                        icon: Icons.local_offer_outlined,
                        isSelected: selectedTypeId == t.typeId,
                        onTap: () => onTypeSelected(t.typeId, t.typeName),
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
                              MaterialDialogHelper.showTypeDialog(
                                context,
                                t,
                                onSaved: (updatedType) {
                                  if (selectedTypeId == updatedType.typeId) {
                                    onTypeSelected(
                                      updatedType.typeId,
                                      updatedType.typeName,
                                    );
                                  }
                                },
                              );
                            }
                            if (val == 'delete') {
                              MaterialDialogHelper.confirmDelete(
                                context,
                                title: "Xóa Phân loại",
                                content:
                                    "Xóa '${t.typeName}'? Hành động này không thể hoàn tác.",
                                onConfirm: () {
                                  context.read<MaterialTypeCubit>().deleteType(
                                    t.typeId,
                                  );
                                  if (selectedTypeId == t.typeId) {
                                    onTypeSelected(
                                      null,
                                      "Tất cả Nguyên vật liệu",
                                    );
                                  }
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
