import 'dart:async';
import 'package:flutter/material.dart' hide MaterialState;
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:owvds/features/inventory/material/domain/material_model.dart';
import 'package:owvds/features/inventory/material/presentation/bloc/material_cubit.dart';
import 'package:owvds/features/inventory/material/presentation/dialogs/material_dialog_helper.dart';
import '../../../supplier/domain/supplier_model.dart';
import '../../../supplier/presentation/bloc/supplier_cubit.dart';

class MaterialListView extends StatefulWidget {
  final int? selectedTypeId;
  final String selectedTypeName;
  final int? selectedSupplierId;
  final String searchQuery;
  final int currentPage;
  final int pageSize;

  // Callbacks để đẩy event lên Màn hình chính xử lý State chung
  final Function(int?) onSupplierChanged;
  final Function(String) onSearchChanged;
  final Function(int) onPageChanged;

  const MaterialListView({
    super.key,
    required this.selectedTypeId,
    required this.selectedTypeName,
    required this.selectedSupplierId,
    required this.searchQuery,
    required this.currentPage,
    required this.pageSize,
    required this.onSupplierChanged,
    required this.onSearchChanged,
    required this.onPageChanged,
  });

  @override
  State<MaterialListView> createState() => _MaterialListViewState();
}

class _MaterialListViewState extends State<MaterialListView> {
  final Color _primaryColor = const Color(0xFF003366);
  late TextEditingController _searchCtrl;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(text: widget.searchQuery);
  }

  @override
  void didUpdateWidget(covariant MaterialListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery &&
        _searchCtrl.text != widget.searchQuery) {
      _searchCtrl.text = widget.searchQuery;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _handleSearch(String val) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      widget.onSearchChanged(val);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Container(
      color: const Color(0xFFF5F7FA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ================== TOOLBAR ==================
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                // Hàng 1: Tiêu đề & Nút Thêm
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.selectedTypeName,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _primaryColor,
                            ),
                          ),
                          BlocBuilder<MaterialCubit, MaterialState>(
                            builder: (context, state) {
                              int total = (state is MaterialLoaded)
                                  ? state.totalCount
                                  : 0;
                              return Text(
                                "Tổng cộng: $total mã vật tư",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    Wrap(
                      spacing: 12,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () =>
                              context.read<MaterialCubit>().exportExcel(
                                typeId: widget.selectedTypeId,
                                supplierId: widget.selectedSupplierId,
                              ),
                          icon: const Icon(Icons.file_download, size: 18),
                          label: const Text("Xuất Excel"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green.shade700,
                            side: BorderSide(color: Colors.green.shade200),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () =>
                              MaterialDialogHelper.showMaterialDialog(
                                context,
                                null,
                                currentTypeId: widget.selectedTypeId,
                                currentSupplierId: widget.selectedSupplierId,
                              ),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text("Thêm NVL"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Hàng 2: Bộ Lọc
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 250,
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: "Tìm mã, tên NVL...",
                          prefixIcon: const Icon(Icons.search, size: 18),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: _handleSearch,
                      ),
                    ),

                    SizedBox(
                      width: 250,
                      child: BlocBuilder<SupplierCubit, SupplierState>(
                        builder: (context, state) {
                          List<Supplier> suppliers = (state is SupplierLoaded)
                              ? state.suppliers
                              : [];
                          return DropdownButtonFormField<int?>(
                            isExpanded:
                                true, // [SỬA LỖI Ở ĐÂY]: Ép Dropdown phải nằm gọn trong SizedBox 250
                            value: widget.selectedSupplierId,
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.business, size: 18),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text(
                                  "Tất cả Nhà Cung Cấp",
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              ...suppliers.map(
                                (s) => DropdownMenuItem(
                                  value: s.supplierId,
                                  child: Text(
                                    s.supplierName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: widget.onSupplierChanged,
                          );
                        },
                      ),
                    ),

                    if (widget.selectedSupplierId != null ||
                        widget.searchQuery.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          _searchCtrl.clear();
                          widget.onSearchChanged('');
                          widget.onSupplierChanged(null);
                        },
                        child: const Text(
                          "Xóa bộ lọc",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // ================== DANH SÁCH & PHÂN TRANG ==================
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: BlocBuilder<MaterialCubit, MaterialState>(
                        builder: (context, state) {
                          if (state is MaterialLoading) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (state is MaterialError) {
                            return Center(
                              child: Text(
                                "Lỗi: ${state.message}",
                                style: const TextStyle(color: Colors.red),
                              ),
                            );
                          }
                          if (state is MaterialLoaded) {
                            if (state.materials.isEmpty) {
                              return const Center(
                                child: Text("Không tìm thấy nguyên vật liệu."),
                              );
                            }
                            return isMobile
                                ? _buildMobileList(state.materials)
                                : _buildDesktopTable(state.materials);
                          }
                          return const SizedBox();
                        },
                      ),
                    ),

                    // Phân trang
                    BlocBuilder<MaterialCubit, MaterialState>(
                      builder: (context, state) {
                        if (state is MaterialLoaded && state.totalCount > 0) {
                          return _buildPagination(state.totalCount);
                        }
                        return const SizedBox();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // GIAO DIỆN DESKTOP (TABLE)
  // ----------------------------------------------------
  Widget _buildDesktopTable(List<MaterialItem> materials) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
          dataRowMinHeight: 50,
          dataRowMaxHeight: 60,
          columnSpacing: 24,
          columns: const [
            DataColumn(
              label: Text(
                'Mã NVL',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Tên NVL',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Thông số (Màu / Dtex / F)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Nhà cung cấp',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              numeric: true,
              label: Text(
                'Tồn Min',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              numeric: true,
              label: Text(
                'Kg/Cuộn',
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
          rows: materials.map((item) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    item.materialCode,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.materialName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        item.materialType?.typeName ?? "Không phân loại",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(
                  Wrap(
                    spacing: 4,
                    children: [
                      if (item.color != null) _buildBadge(item.color!),
                      if (item.dtex != null) _buildBadge('Dtex: ${item.dtex}'),
                      if (item.filament != null)
                        _buildBadge('F: ${item.filament}'),
                    ],
                  ),
                ),
                DataCell(
                  Text(
                    item.supplier?.supplierName ?? "-",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DataCell(
                  Text(
                    item.minStockLevel.toStringAsFixed(1),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: item.minStockLevel > 0
                          ? Colors.orange.shade700
                          : Colors.black87,
                    ),
                  ),
                ),
                DataCell(Text(item.kgPerBobbin?.toStringAsFixed(1) ?? "-")),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.blue,
                          size: 18,
                        ),
                        onPressed: () =>
                            MaterialDialogHelper.showMaterialDialog(
                              context,
                              item,
                              currentTypeId: widget.selectedTypeId,
                              currentSupplierId: widget.selectedSupplierId,
                            ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                          size: 18,
                        ),
                        onPressed: () => MaterialDialogHelper.confirmDelete(
                          context,
                          title: "Xóa NVL",
                          content:
                              "Bạn có chắc muốn xóa mã '${item.materialCode}'?",
                          onConfirm: () => context
                              .read<MaterialCubit>()
                              .deleteMaterial(item.materialId),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // GIAO DIỆN MOBILE (LIST)
  // ----------------------------------------------------
  Widget _buildMobileList(List<MaterialItem> materials) {
    return ListView.separated(
      itemCount: materials.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = materials[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          title: Text(
            "[${item.materialCode}] ${item.materialName}",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                "Loại: ${item.materialType?.typeName ?? "-"} | NCC: ${item.supplier?.shortName ?? "-"}",
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                children: [
                  if (item.color != null) _buildBadge(item.color!),
                  if (item.dtex != null) _buildBadge('Dtex: ${item.dtex}'),
                  if (item.filament != null) _buildBadge('F: ${item.filament}'),
                ],
              ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: () => MaterialDialogHelper.showMaterialDialog(
              context,
              item,
              currentTypeId: widget.selectedTypeId,
              currentSupplierId: widget.selectedSupplierId,
            ),
          ),
        );
      },
    );
  }

  // Helper tạo Badge xám
  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: Colors.grey.shade800),
      ),
    );
  }

  // ----------------------------------------------------
  // PHÂN TRANG (Pagination Footer)
  // ----------------------------------------------------
  Widget _buildPagination(int totalCount) {
    int totalPages = (totalCount / widget.pageSize).ceil();
    if (totalPages <= 1) {
      return const SizedBox(); // Chỉ có 1 trang thì ko hiện phân trang
    }

    int startRecord = ((widget.currentPage - 1) * widget.pageSize) + 1;
    int endRecord = (widget.currentPage * widget.pageSize);
    if (endRecord > totalCount) endRecord = totalCount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Đang xem $startRecord - $endRecord trên tổng $totalCount",
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: widget.currentPage > 1
                    ? () => widget.onPageChanged(widget.currentPage - 1)
                    : null,
              ),
              Text(
                "Trang ${widget.currentPage} / $totalPages",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: widget.currentPage < totalPages
                    ? () => widget.onPageChanged(widget.currentPage + 1)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
