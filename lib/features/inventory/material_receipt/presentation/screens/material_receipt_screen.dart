import 'dart:async';
import 'package:flutter/material.dart' hide MaterialState;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:owvds/features/inventory/material_receipt/domain/material_receipt_model.dart';

import '../../../../home/presentation/widgets/admin_sidebar.dart';
import '../../../../../core/widgets/responsive_layout.dart';
import '../bloc/material_receipt_cubit.dart';
// import 'material_receipt_dialog.dart'; // Bạn có thể tạo popup tạo phiếu sau

class MaterialReceiptScreen extends StatefulWidget {
  const MaterialReceiptScreen({super.key});

  @override
  State<MaterialReceiptScreen> createState() => _MaterialReceiptScreenState();
}

class _MaterialReceiptScreenState extends State<MaterialReceiptScreen> {
  final Color _primaryColor = const Color(0xFF003366);
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    context.read<MaterialReceiptCubit>().loadReceipts();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String keyword) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<MaterialReceiptCubit>().searchReceipts(keyword);
    });
  }

  void _onNavigate(String route) {
    if (ResponsiveLayout.isMobile(context) &&
        _scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.pop(context);
    }
    if (route != '#') context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isMobile = ResponsiveLayout.isMobile(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: isDesktop
          ? null
          : AppBar(
              title: const Text(
                "Nhập Kho NVL",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              backgroundColor: Colors.white,
              foregroundColor: _primaryColor,
              elevation: 0.5,
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
            ),
      drawer: isDesktop
          ? null
          : Drawer(
              child: AdminSidebar(
                currentPath: '/stock-in',
                isAdmin: true,
                onNavigate: _onNavigate,
              ),
            ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar cố định cho Desktop
          if (isDesktop)
            AdminSidebar(
              currentPath: '/stock-in',
              isAdmin: true,
              onNavigate: _onNavigate,
            ),

          // Khu vực nội dung chính
          Expanded(
            child: Column(
              children: [
                if (isDesktop)
                  Container(
                    height: 64,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          "Lịch Sử Nhập Kho NVL",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: _primaryColor,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(
                            Icons.refresh,
                            color: Colors.blueGrey,
                          ),
                          onPressed: () => context
                              .read<MaterialReceiptCubit>()
                              .loadReceipts(),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            // Mở Dialog tạo phiếu nhập mới
                            // showDialog(context: context, builder: (ctx) => const MaterialReceiptDialog());
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Tính năng tạo phiếu đang phát triển',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text("Tạo Phiếu Nhập"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Thanh tìm kiếm
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      SizedBox(
                        width: isMobile ? 300 : 400,
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: _onSearch,
                          decoration: InputDecoration(
                            hintText: "Tìm kiếm theo mã phiếu...",
                            prefixIcon: const Icon(Icons.search, size: 18),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 0,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bảng danh sách phiếu nhập
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 24,
                    ).copyWith(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child:
                        BlocBuilder<MaterialReceiptCubit, MaterialReceiptState>(
                          builder: (context, state) {
                            if (state is MaterialReceiptLoading) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (state is MaterialReceiptError) {
                              return Center(
                                child: Text(
                                  state.message,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              );
                            }
                            if (state is MaterialReceiptLoaded) {
                              if (state.receipts.isEmpty) {
                                return const Center(
                                  child: Text("Chưa có phiếu nhập kho nào."),
                                );
                              }

                              if (isMobile) {
                                return _buildMobileList(state.receipts);
                              }
                              return _buildDesktopTable(
                                state.receipts,
                                context,
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(
    List<MaterialReceipt> receipts,
    BuildContext context,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
          columns: const [
            DataColumn(
              label: Text(
                'Mã Phiếu',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Ngày nhập',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text('Kho', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text(
                'Trạng thái',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Thao tác',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: receipts.map((receipt) {
            bool isCompleted = receipt.status == 'Completed';
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    receipt.receiptNumber ?? '-',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                DataCell(Text(receipt.receiptDate ?? '-')),
                DataCell(Text("Kho ID: ${receipt.warehouseId}")),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Colors.green.shade50
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isCompleted
                            ? Colors.green.shade200
                            : Colors.orange.shade200,
                      ),
                    ),
                    child: Text(
                      isCompleted ? "HOÀN THÀNH" : "BẢN NHÁP",
                      style: TextStyle(
                        color: isCompleted
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.remove_red_eye,
                          color: Colors.blueGrey,
                          size: 20,
                        ),
                        tooltip: "Xem chi tiết",
                        onPressed: () {},
                      ),
                      if (!isCompleted)
                        IconButton(
                          icon: const Icon(
                            Icons.check_circle,
                            color: Colors.teal,
                            size: 20,
                          ),
                          tooltip: "Duyệt Phiếu",
                          onPressed: () =>
                              _confirmCompleteReceipt(context, receipt),
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

  Widget _buildMobileList(List<MaterialReceipt> receipts) {
    return ListView.separated(
      itemCount: receipts.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final r = receipts[index];
        bool isCompleted = r.status == 'Completed';
        return ListTile(
          contentPadding: const EdgeInsets.all(16),
          title: Text(
            r.receiptNumber ?? '-',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text("Ngày: ${r.receiptDate} | Kho: ${r.warehouseId}"),
              const SizedBox(height: 4),
              Text(
                isCompleted ? "HOÀN THÀNH" : "BẢN NHÁP",
                style: TextStyle(
                  color: isCompleted
                      ? Colors.green.shade700
                      : Colors.orange.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.grey),
            onPressed: () {},
          ),
        );
      },
    );
  }

  void _confirmCompleteReceipt(BuildContext context, MaterialReceipt receipt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận duyệt"),
        content: Text(
          "Duyệt phiếu ${receipt.receiptNumber}? Sau khi duyệt hệ thống sẽ tự động tạo Lô và cộng Tồn kho.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              context.read<MaterialReceiptCubit>().completeReceipt(receipt.id);
              Navigator.pop(ctx);
            },
            child: const Text("Duyệt"),
          ),
        ],
      ),
    );
  }
}
