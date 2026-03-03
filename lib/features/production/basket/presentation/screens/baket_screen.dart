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

    // Hủy lắng nghe WebSocket khi đóng màn hình
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
              // --- HEADER SECTION ---
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.shopping_basket,
                            color: Colors.orange.shade800,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            "Quản lý Rổ / Trục",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                        if (isDesktop) ...[
                          OutlinedButton.icon(
                            onPressed: _onImportExcelPressed,
                            icon: const Icon(Icons.upload_file, size: 18),
                            label: const Text('IMPORT EXCEL'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _primaryColor,
                              side: BorderSide(color: _primaryColor),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () => _showEditDialog(context, null),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text("THÊM RỔ"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),
                    // --- SEARCH BAR ---
                    Row(
                      children: [
                        if (isDesktop) ...[
                          _buildStatBadge(
                            Icons.grid_view,
                            "Tổng rổ",
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
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: TextField(
                              controller: _searchController,
                              textInputAction: TextInputAction.search,
                              onChanged: _onSearchChanged,
                              decoration: InputDecoration(
                                hintText: "Tìm mã rổ...",
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
                                size: 60,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Chưa có rổ nào",
                                style: TextStyle(color: Colors.grey.shade500),
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
              backgroundColor: _accentColor,
              onPressed: () => _showEditDialog(context, null),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  // --- DESKTOP TABLE ---
  Widget _buildDesktopTable(BuildContext context, List<Basket> items) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(
                      const Color(0xFFF9FAFB),
                    ),
                    horizontalMargin: 24,
                    columnSpacing: 30,
                    dataRowMinHeight: 60,
                    columns: [
                      DataColumn(label: Text("MÃ RỔ", style: _headerStyle)),
                      DataColumn(
                        label: Text("TRỌNG LƯỢNG (kg)", style: _headerStyle),
                        numeric: true,
                      ),
                      DataColumn(
                        label: Text("TRẠNG THÁI", style: _headerStyle),
                      ),
                      DataColumn(label: Text("GHI CHÚ", style: _headerStyle)),
                      DataColumn(label: Text("HÀNH ĐỘNG", style: _headerStyle)),
                    ],
                    rows: items.map((item) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              item.code,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataCell(Text(item.tareWeight.toStringAsFixed(1))),
                          DataCell(_buildStatusBadge(item.status)),
                          DataCell(
                            Text(
                              item.note,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      _showEditDialog(context, item),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      _confirmDelete(context, item),
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
            },
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
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.code,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                _buildStatusBadge(item.status),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  "TL: ${item.tareWeight.toStringAsFixed(1)} kg",
                  style: TextStyle(color: Colors.grey.shade800),
                ),
                if (item.note.isNotEmpty)
                  Text(
                    "Note: ${item.note}",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
            trailing: PopupMenuButton(
              onSelected: (val) {
                if (val == 'edit') _showEditDialog(context, item);
                if (val == 'delete') _confirmDelete(context, item);
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 'edit', child: Text("Sửa")),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text("Xóa", style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg, text;
    switch (status) {
      case 'READY':
        bg = Colors.green.shade50;
        text = Colors.green;
        break;
      case 'IN_USE':
        bg = Colors.blue.shade50;
        text = Colors.blue;
        break;
      case 'HOLDING':
        bg = Colors.orange.shade50;
        text = Colors.orange;
        break;
      case 'DAMAGED':
        bg = Colors.red.shade50;
        text = Colors.red;
        break;
      default:
        bg = Colors.grey.shade100;
        text = Colors.grey;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: text.withOpacity(0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: text,
          fontSize: 10,
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
          item == null ? "Thêm Rổ mới" : "Sửa Rổ",
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
                  decoration: const InputDecoration(
                    labelText: "Mã Rổ *",
                    border: OutlineInputBorder(),
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
                  decoration: const InputDecoration(
                    labelText: "Trọng lượng (kg) *",
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return "Bắt buộc nhập";
                    if (double.tryParse(v) == null) {
                      return "Vui lòng nhập số hợp lệ";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: "Trạng thái",
                    border: OutlineInputBorder(),
                  ),
                  items: ['READY', 'IN_USE', 'HOLDING', 'DAMAGED']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => selectedStatus = val!,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(
                    labelText: "Ghi chú",
                    border: OutlineInputBorder(),
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
            ),
            child: const Text("Lưu"),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              ),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  TextStyle get _headerStyle => TextStyle(
    color: Colors.grey.shade600,
    fontWeight: FontWeight.bold,
    fontSize: 12,
    letterSpacing: 0.5,
  );
}
