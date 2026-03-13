import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../../core/widgets/responsive_layout.dart';
import '../../../../../core/network/websocket_service.dart';

import '../../doamain/basket_model.dart';
import '../bloc/baket_cubit.dart';

class BasketScreen extends StatefulWidget {
  const BasketScreen({super.key});

  @override
  State<BasketScreen> createState() => _BasketScreenState();
}

class _BasketScreenState extends State<BasketScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  final Color _primaryColor = const Color(0xFF003366);
  final Color _accentColor = const Color(0xFF5D4037);
  final Color _bgLight = const Color(0xFFF5F7FA);

  int _rowsPerPage = 20; // [MỚI] Khai báo biến state để quản lý phân trang

  @override
  void initState() {
    super.initState();
    context.read<BasketCubit>().loadBaskets();

    // Đăng ký lắng nghe sự kiện WebSocket để cập nhật Real-time
    WebSocketService().connect();
    WebSocketService().addListener(_onWebSocketMessage);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    WebSocketService().removeListener(_onWebSocketMessage);
    super.dispose();
  }

  // Xử lý khi nhận được tín hiệu từ Backend
  void _onWebSocketMessage(String message) {
    if (message == "REFRESH_BASKETS") {
      debugPrint("WebSocket: Cập nhật lại danh sách Rổ.");
      if (mounted) {
        context.read<BasketCubit>().loadBaskets();
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().isEmpty) {
        context.read<BasketCubit>().loadBaskets();
      } else {
        context.read<BasketCubit>().searchBaskets(query);
      }
    });
  }

  // Hàm chọn file Excel và gửi lên Cubit
  void _onImportExcelPressed() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xls', 'xlsx'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty && mounted) {
      context.read<BasketCubit>().importExcel(result.files.first);
    }
  }

  // Hàm hiển thị Dialog thông báo chi tiết kết quả Import
  void _showImportResultDialog(String title, String message, Color color) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              color == Colors.green
                  ? Icons.check_circle
                  : Icons.warning_amber_rounded,
              color: color,
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Text(
              message,
              style: const TextStyle(height: 1.5, fontSize: 14),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Đóng"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: _bgLight,
      body: BlocConsumer<BasketCubit, BasketState>(
        listener: (context, state) {
          if (state is BasketError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is BasketErrorMsg) {
            // Lỗi Import (cảnh báo)
            _showImportResultDialog(
              "Kết quả Import (Có cảnh báo)",
              state.message,
              Colors.orange,
            );
          } else if (state is BasketSuccessMsg) {
            // Import thành công hoàn toàn
            _showImportResultDialog("Thành công", state.message, Colors.green);
          }
        },
        builder: (context, state) {
          int total = 0;
          if (state is BasketLoaded) total = state.baskets.length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- HEADER SECTION MỚI LÀM ĐẸP ---
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.shopping_basket_rounded,
                            color: Colors.orange.shade800,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Quản lý Rổ",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              Text(
                                "Quản lý danh sách, khối lượng và trạng thái rổ",
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isDesktop) ...[
                          OutlinedButton.icon(
                            onPressed: _onImportExcelPressed,
                            icon: Icon(
                              Icons.upload_file,
                              size: 18,
                              color: Colors.green.shade700,
                            ),
                            label: Text(
                              'Nhập Excel',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.green.shade300),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () => _showEditDialog(context, null),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text("Thêm Rổ Mới"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),
                    // --- SEARCH BAR & STATS ---
                    Row(
                      children: [
                        if (isDesktop) ...[
                          _buildStatBadge(
                            Icons.grid_view_rounded,
                            "Tổng số rổ",
                            "$total",
                            Colors.blue,
                          ),
                          const SizedBox(width: 16),
                          const Spacer(),
                        ],
                        Expanded(
                          flex: isDesktop ? 0 : 1,
                          child: Container(
                            width: isDesktop ? 350 : double.infinity,
                            decoration: BoxDecoration(
                              color: _bgLight,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: TextField(
                              controller: _searchController,
                              textInputAction: TextInputAction.search,
                              onChanged: _onSearchChanged,
                              decoration: InputDecoration(
                                hintText: "Tìm mã rổ, ghi chú...",
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: Colors.grey.shade500,
                                  size: 20,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.clear,
                                          color: Colors.grey,
                                          size: 18,
                                        ),
                                        onPressed: () {
                                          _searchController.clear();
                                          _onSearchChanged('');
                                        },
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: Colors.grey.shade200),

              // --- CONTENT SECTION ---
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (state is BasketLoading) {
                      return Center(
                        child: CircularProgressIndicator(color: _primaryColor),
                      );
                    }
                    if (state is BasketLoaded) {
                      if (state.baskets.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shopping_basket_outlined,
                                size: 80,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Không tìm thấy dữ liệu rổ nào.",
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return isDesktop
                          ? _buildDesktopTable(context, state.baskets)
                          : _buildMobileList(context, state.baskets);
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: !isDesktop
          ? FloatingActionButton(
              backgroundColor: _primaryColor,
              onPressed: () => _showEditDialog(context, null),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  // --- DESKTOP TABLE (PAGINATED) ---
  Widget _buildDesktopTable(BuildContext context, List<Basket> items) {
    final dataSource = BasketDataSource(
      baskets: items,
      onEdit: (item) => _showEditDialog(context, item),
      onDelete: (item) => _confirmDelete(context, item),
      buildStatusBadge: _buildStatusBadge,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: Theme.of(context).copyWith(
            cardColor: Colors.white,
            dividerColor: Colors.grey.shade200,
          ),
          child: PaginatedDataTable(
            header: const Text(
              "Danh sách Rổ/Trục",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            columns: [
              DataColumn(label: Text("MÃ RỔ", style: _headerStyle)),
              DataColumn(label: Text("TRỌNG LƯỢNG TỊNH", style: _headerStyle)),
              DataColumn(label: Text("TRẠNG THÁI", style: _headerStyle)),
              DataColumn(label: Text("GHI CHÚ", style: _headerStyle)),
              DataColumn(label: Text("HÀNH ĐỘNG", style: _headerStyle)),
            ],
            source: dataSource,
            // [ĐÃ SỬA LỖI ASSERTION FAILED TẠI ĐÂY]
            rowsPerPage: _rowsPerPage,
            availableRowsPerPage: const [10, 20, 50, 100],
            onRowsPerPageChanged: (value) {
              if (value != null) {
                setState(() {
                  _rowsPerPage = value;
                });
              }
            },
            showCheckboxColumn: false,
            dataRowMinHeight: 60,
            dataRowMaxHeight: 60,
            columnSpacing: 40,
            horizontalMargin: 24,
          ),
        ),
      ),
    );
  }

  // --- MOBILE LIST ---
  Widget _buildMobileList(BuildContext context, List<Basket> items) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.shopping_basket_rounded,
                          color: Colors.orange.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.code,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    _buildStatusBadge(item.status),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Trọng lượng tĩnh",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${item.tareWeight.toStringAsFixed(1)} kg",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit_note_rounded,
                            color: Colors.blue,
                          ),
                          onPressed: () => _showEditDialog(context, item),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.red,
                          ),
                          onPressed: () => _confirmDelete(context, item),
                        ),
                      ],
                    ),
                  ],
                ),
                if (item.note.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Ghi chú: ${item.note}",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // Widget Badge trạng thái
  Widget _buildStatusBadge(String status) {
    Color bg, text;
    switch (status) {
      case 'READY':
        bg = Colors.green.shade50;
        text = Colors.green.shade700;
        break;
      case 'IN_USE':
        bg = Colors.blue.shade50;
        text = Colors.blue.shade700;
        break;
      case 'HOLDING':
        bg = Colors.orange.shade50;
        text = Colors.orange.shade700;
        break;
      case 'DAMAGED':
        bg = Colors.red.shade50;
        text = Colors.red.shade700;
        break;
      default:
        bg = Colors.grey.shade100;
        text = Colors.grey.shade700;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: text.withOpacity(0.2)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: text,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // --- DIALOG THÊM / SỬA ---
  void _showEditDialog(BuildContext context, Basket? item) {
    final codeCtrl = TextEditingController(text: item?.code ?? '');
    final weightCtrl = TextEditingController(
      text: item != null ? item.tareWeight.toString() : '',
    );
    final noteCtrl = TextEditingController(text: item?.note ?? '');
    String selectedStatus = item?.status ?? 'READY';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          item == null ? "Thêm Rổ mới" : "Sửa thông tin Rổ",
          style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: codeCtrl,
                  decoration: InputDecoration(
                    labelText: "Mã Rổ *",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    isDense: true,
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? "Bắt buộc nhập" : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: weightCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: "Trọng lượng (kg) *",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    isDense: true,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return "Bắt buộc nhập";
                    if (double.tryParse(v) == null)
                      return "Vui lòng nhập số hợp lệ";
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: InputDecoration(
                    labelText: "Trạng thái",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    isDense: true,
                  ),
                  items: ['READY', 'IN_USE', 'HOLDING', 'DAMAGED']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => selectedStatus = val!,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: noteCtrl,
                  decoration: InputDecoration(
                    labelText: "Ghi chú",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    isDense: true,
                  ),
                  maxLines: 2,
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
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final newItem = Basket(
                  id: item?.id ?? 0,
                  code: codeCtrl.text.trim(),
                  tareWeight: double.parse(weightCtrl.text.trim()),
                  status: selectedStatus,
                  note: noteCtrl.text.trim(),
                );
                context.read<BasketCubit>().saveBasket(
                  basket: newItem,
                  isEdit: item != null,
                );
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(item == null ? "Tạo mới" : "Lưu thay đổi"),
          ),
        ],
      ),
    );
  }

  // --- DIALOG XÓA ---
  void _confirmDelete(BuildContext context, Basket item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Xóa rổ",
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Bạn có chắc chắn muốn xóa rổ '${item.code}' không?\nHành động này không thể hoàn tác.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<BasketCubit>().deleteBasket(item.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Xóa"),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  TextStyle get _headerStyle => TextStyle(
    color: Colors.grey.shade500,
    fontWeight: FontWeight.bold,
    fontSize: 12,
    letterSpacing: 0.5,
  );
}

// =========================================================================
// DATASOURCE CHO PAGINATED DATA TABLE
// =========================================================================
class BasketDataSource extends DataTableSource {
  final List<Basket> baskets;
  final Function(Basket) onEdit;
  final Function(Basket) onDelete;
  final Widget Function(String) buildStatusBadge;

  BasketDataSource({
    required this.baskets,
    required this.onEdit,
    required this.onDelete,
    required this.buildStatusBadge,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= baskets.length) return null;
    final item = baskets[index];

    return DataRow(
      cells: [
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Text(
              item.code,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade900,
              ),
            ),
          ),
        ),
        DataCell(
          Text(
            "${item.tareWeight.toStringAsFixed(1)} kg",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        DataCell(buildStatusBadge(item.status)),
        DataCell(
          Text(
            item.note.isEmpty ? "-" : item.note,
            style: TextStyle(
              color: item.note.isEmpty ? Colors.grey : Colors.black87,
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.edit_note_rounded,
                  color: Colors.blue,
                  size: 22,
                ),
                tooltip: "Sửa",
                onPressed: () => onEdit(item),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                  size: 22,
                ),
                tooltip: "Xóa",
                onPressed: () => onDelete(item),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => baskets.length;

  @override
  int get selectedRowCount => 0;
}
