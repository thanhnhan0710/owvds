import 'dart:async'; // Cần thiết cho Timer (Debounce)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/supplier_model.dart';
import '../bloc/supplier_cubit.dart';
import '../dialogs/supplier_dialog_helper.dart';

class SupplierListView extends StatefulWidget {
  final int? selectedCategoryId;
  final String selectedCategoryName;

  const SupplierListView({
    super.key,
    required this.selectedCategoryId,
    required this.selectedCategoryName,
  });

  @override
  State<SupplierListView> createState() => _SupplierListViewState();
}

class _SupplierListViewState extends State<SupplierListView> {
  final Color _primaryColor = const Color(0xFF003366);
  final TextEditingController _searchCtrl = TextEditingController();

  // Biến dùng để delay việc gọi tìm kiếm (Debounce)
  Timer? _debounce;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel(); // Hủy timer khi rời khỏi màn hình
    super.dispose();
  }

  // Hàm xử lý tìm kiếm có độ trễ
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      // Chỉ gọi tìm kiếm sau khi người dùng ngừng gõ 500ms
      if (mounted) {
        context.read<SupplierCubit>().searchSuppliers(
          query,
          categoryId: widget.selectedCategoryId,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Kiểm tra kích thước màn hình để quyết định giao diện
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ===============================================
        // Content Header Toolbar
        // ===============================================
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: [
              // Cột Tiêu đề
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.selectedCategoryName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                  BlocBuilder<SupplierCubit, SupplierState>(
                    builder: (context, state) {
                      int total = (state is SupplierLoaded)
                          ? state.totalCount
                          : 0;
                      return Text(
                        "Tổng cộng: $total đối tác",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      );
                    },
                  ),
                ],
              ),

              // Nhóm Tìm kiếm & Nút
              Container(
                constraints: BoxConstraints(
                  maxWidth: isMobile ? double.infinity : 400,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: "Tìm tên, viết tắt...",
                          prefixIcon: const Icon(Icons.search, size: 20),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged:
                            _onSearchChanged, // Kích hoạt Debounce Search
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => SupplierDialogHelper.showSupplierDialog(
                        context,
                        null,
                        widget.selectedCategoryId,
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text("Thêm"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ===============================================
        // Content List (Tự động thích ứng Mobile / Desktop)
        // ===============================================
        Expanded(
          child: BlocBuilder<SupplierCubit, SupplierState>(
            builder: (context, state) {
              if (state is SupplierLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is SupplierError) {
                return Center(
                  child: Text(
                    "Lỗi: ${state.message}",
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }
              if (state is SupplierLoaded) {
                if (state.suppliers.isEmpty) {
                  return const Center(
                    child: Text("Chưa có dữ liệu nhà cung cấp."),
                  );
                }

                // Trả về giao diện tương ứng với kích thước màn hình
                return isMobile
                    ? _buildMobileList(state.suppliers)
                    : _buildDesktopTable(state.suppliers);
              }
              return const SizedBox();
            },
          ),
        ),
      ],
    );
  }

  // ===============================================
  // GIAO DIỆN DÀNH CHO MOBILE (ListView)
  // ===============================================
  Widget _buildMobileList(List<Supplier> suppliers) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: suppliers.length,
      itemBuilder: (context, index) {
        final sup = suppliers[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: _primaryColor.withOpacity(0.1),
                      child: Text(
                        sup.supplierName.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          color: _primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sup.supplierName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          if (sup.shortName != null &&
                              sup.shortName!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.orange.shade200,
                                  ),
                                ),
                                child: Text(
                                  sup.shortName!,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.orange.shade900,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.category, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        sup.category?.categoryName ?? "Chưa phân loại",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        sup.address ?? "Chưa cập nhật địa chỉ",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(
                        Icons.edit_document,
                        color: Colors.blue,
                        size: 18,
                      ),
                      label: const Text(
                        "Sửa",
                        style: TextStyle(color: Colors.blue),
                      ),
                      onPressed: () => SupplierDialogHelper.showSupplierDialog(
                        context,
                        sup,
                        widget.selectedCategoryId,
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(
                        Icons.delete_forever,
                        color: Colors.red,
                        size: 18,
                      ),
                      label: const Text(
                        "Xóa",
                        style: TextStyle(color: Colors.red),
                      ),
                      onPressed: () => SupplierDialogHelper.confirmDelete(
                        context,
                        title: "Xóa Nhà cung cấp",
                        content:
                            "Bạn có chắc muốn xóa NCC '${sup.supplierName}'?",
                        onConfirm: () => context
                            .read<SupplierCubit>()
                            .deleteSupplier(sup.supplierId),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===============================================
  // GIAO DIỆN DÀNH CHO DESKTOP/TABLET (DataTable)
  // ===============================================
  Widget _buildDesktopTable(List<Supplier> suppliers) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
            dataRowMinHeight: 50,
            dataRowMaxHeight: 60,
            dividerThickness: 0.5,
            columns: const [
              DataColumn(
                label: Text(
                  'Tên nhà cung cấp',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Tên viết tắt',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Phân loại',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Địa chỉ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Hành động',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
            rows: suppliers.map((sup) {
              return DataRow(
                cells: [
                  // Tên NCC
                  DataCell(
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: _primaryColor.withOpacity(0.1),
                          child: Text(
                            sup.supplierName.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              color: _primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          sup.supplierName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  // Viết tắt
                  DataCell(
                    sup.shortName != null && sup.shortName!.isNotEmpty
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Text(
                              sup.shortName!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange.shade900,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : const Text('-'),
                  ),
                  // Phân loại
                  DataCell(
                    Row(
                      children: [
                        Icon(
                          Icons.category,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          sup.category?.categoryName ?? "Chưa phân loại",
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                  // Địa chỉ
                  DataCell(
                    Container(
                      constraints: const BoxConstraints(maxWidth: 250),
                      child: Text(
                        sup.address ?? "Chưa cập nhật",
                        style: TextStyle(color: Colors.grey.shade700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  // Hành động (Sửa, Xóa)
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit_document,
                            color: Colors.blue,
                            size: 20,
                          ),
                          onPressed: () =>
                              SupplierDialogHelper.showSupplierDialog(
                                context,
                                sup,
                                widget.selectedCategoryId,
                              ),
                          tooltip: "Sửa",
                          splashRadius: 20,
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_forever,
                            color: Colors.red,
                            size: 20,
                          ),
                          onPressed: () => SupplierDialogHelper.confirmDelete(
                            context,
                            title: "Xóa Nhà cung cấp",
                            content:
                                "Bạn có chắc muốn xóa NCC '${sup.supplierName}'?",
                            onConfirm: () => context
                                .read<SupplierCubit>()
                                .deleteSupplier(sup.supplierId),
                          ),
                          tooltip: "Xóa",
                          splashRadius: 20,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
