import 'package:flutter/material.dart' hide MaterialState;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:owvds/features/inventory/PO/po_header/presentation/bloc/po_header_cubit.dart';

// [CẬP NHẬT]: Thêm dart:convert để xử lý Base64 tải file
import 'dart:convert';
import 'dart:html' as html;

import 'package:owvds/features/inventory/material_receipt/domain/material_receipt_model.dart';
import 'package:owvds/features/inventory/material_receipt/presentation/dialogs/material_receipt_form_dialog.dart';

import '../../../../home/presentation/widgets/admin_sidebar.dart';
import '../../../../../core/widgets/responsive_layout.dart';
import '../../../../../core/network/websocket_service.dart';

import '../bloc/material_receipt_cubit.dart';
import '../../../warehouse/presentation/bloc/warehouse_cubit.dart';

import '../../../../inventory/material/presentation/bloc/material_cubit.dart';

class MaterialReceiptScreen extends StatefulWidget {
  const MaterialReceiptScreen({super.key});

  @override
  State<MaterialReceiptScreen> createState() => _MaterialReceiptScreenState();
}

class _MaterialReceiptScreenState extends State<MaterialReceiptScreen> {
  final Color _primaryColor = const Color(0xFF003366);
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    context.read<MaterialReceiptCubit>().loadInitial();
    context.read<WarehouseCubit>().loadWarehouses();
    context.read<POHeaderCubit>().loadPOs();
    context.read<MaterialCubit>().loadMaterials();
    WebSocketService().connect();
    WebSocketService().addListener(_onWebSocketMessage);
  }

  void _onWebSocketMessage(String message) {
    if (!mounted) return;
    if (message == "REFRESH_MATERIAL_RECEIPTS") {
      context.read<MaterialReceiptCubit>().refreshCurrentView();
    }
  }

  @override
  void dispose() {
    WebSocketService().removeListener(_onWebSocketMessage);
    super.dispose();
  }

  void _onNavigate(String route) {
    if (ResponsiveLayout.isMobile(context) &&
        _scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.pop(context);
    }
    if (route != '#') context.go(route);
  }

  void _openForm([MaterialReceipt? receipt]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MaterialReceiptFormDialog(receipt: receipt),
    );
  }

  // ==========================================================
  // [ĐÃ SỬA]: CƠ CHẾ DOWNLOAD FILE MẠNH MẼ HƠN CHO TRÌNH DUYỆT MOBILE
  // ==========================================================
  void _saveExcelFile(List<int> bytes, String fileName) {
    try {
      // Mã hóa mảng byte sang Base64 để ép trình duyệt tải xuống
      final base64data = base64Encode(bytes);

      // Khai báo thẻ a với chuỗi Base64
      final a =
          html.AnchorElement(
              href:
                  'data:application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;base64,$base64data',
            )
            ..setAttribute("download", "$fileName.xlsx")
            ..target = "blank";

      // Thêm vào DOM, tự động click rồi gỡ bỏ (Giúp vượt rào chặn Popup của Web)
      html.document.body?.append(a);
      a.click();
      a.remove();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Xuất file Excel thành công! Đang tải xuống...'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi tải file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isMobile = ResponsiveLayout.isMobile(context);
    final numFmt = NumberFormat("#,##0.##", "en_US");

    context.watch<WarehouseCubit>();
    context.watch<POHeaderCubit>();
    context.watch<MaterialCubit>();

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

      body: BlocListener<MaterialReceiptCubit, MaterialReceiptState>(
        listener: (context, state) {
          if (state is MaterialReceiptExportSuccess) {
            _saveExcelFile(state.bytes, state.fileName);
          } else if (state is MaterialReceiptError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isDesktop)
              AdminSidebar(
                currentPath: '/stock-in',
                isAdmin: true,
                onNavigate: _onNavigate,
              ),

            Expanded(
              child: Column(
                children: [
                  Container(
                    height: isMobile ? null : 64,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (!isMobile)
                          Text(
                            "Quản Lý Phiếu Nhập",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: _primaryColor,
                            ),
                          ),
                        const Spacer(),

                        TextButton.icon(
                          onPressed: () => context
                              .read<MaterialReceiptCubit>()
                              .exportExcel(),
                          icon: const Icon(Icons.download),
                          label: isMobile
                              ? const SizedBox()
                              : const Text("Xuất Excel"),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.green.shade700,
                          ),
                        ),
                        const SizedBox(width: 8),

                        IconButton(
                          icon: const Icon(
                            Icons.refresh,
                            color: Colors.blueGrey,
                          ),
                          onPressed: () => context
                              .read<MaterialReceiptCubit>()
                              .refreshCurrentView(),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _openForm(),
                          icon: const Icon(Icons.add, size: 16),
                          label: Text(
                            isMobile ? "Tạo Phiếu" : "Tạo Phiếu Nhập",
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: EdgeInsets.all(isMobile ? 16 : 24),
                    child:
                        BlocBuilder<MaterialReceiptCubit, MaterialReceiptState>(
                          builder: (context, state) {
                            String currentFilter = 'ALL';
                            if (state is MaterialReceiptLoaded)
                              currentFilter = state.currentFilter;
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildTimeFilterChip(
                                    'Tất cả',
                                    'ALL',
                                    currentFilter,
                                  ),
                                  _buildTimeFilterChip(
                                    'Hôm nay',
                                    'TODAY',
                                    currentFilter,
                                  ),
                                  _buildTimeFilterChip(
                                    'Tuần này',
                                    'WEEK',
                                    currentFilter,
                                  ),
                                  _buildTimeFilterChip(
                                    'Tháng này',
                                    'MONTH',
                                    currentFilter,
                                  ),
                                  _buildTimeFilterChip(
                                    'Quý này',
                                    'QUARTER',
                                    currentFilter,
                                  ),
                                  _buildTimeFilterChip(
                                    'Năm nay',
                                    'YEAR',
                                    currentFilter,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                  ),

                  Expanded(
                    child: Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: isMobile ? 12 : 24,
                      ).copyWith(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child:
                          BlocBuilder<
                            MaterialReceiptCubit,
                            MaterialReceiptState
                          >(
                            builder: (context, state) {
                              if (state is MaterialReceiptLoading)
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              if (state is MaterialReceiptLoaded) {
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: state.receipts.isEmpty
                                          ? const Center(
                                              child: Text(
                                                "Không phát sinh giao dịch trong khoảng thời gian này.",
                                              ),
                                            )
                                          : ListView.builder(
                                              padding: EdgeInsets.all(
                                                isMobile ? 12 : 24,
                                              ),
                                              itemCount: state.receipts.length,
                                              itemBuilder: (context, index) =>
                                                  _buildDetailedReceiptCard(
                                                    state.receipts[index],
                                                    numFmt,
                                                    isMobile,
                                                  ),
                                            ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          top: BorderSide(
                                            color: Colors.grey.shade200,
                                          ),
                                        ),
                                        color: Colors.grey.shade50,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            "Trang ${state.currentPage}",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          OutlinedButton(
                                            onPressed: state.currentPage > 1
                                                ? () => context
                                                      .read<
                                                        MaterialReceiptCubit
                                                      >()
                                                      .changePage(
                                                        state.currentPage - 1,
                                                      )
                                                : null,
                                            child: const Text("Trước"),
                                          ),
                                          const SizedBox(width: 8),
                                          OutlinedButton(
                                            onPressed: state.hasNextPage
                                                ? () => context
                                                      .read<
                                                        MaterialReceiptCubit
                                                      >()
                                                      .changePage(
                                                        state.currentPage + 1,
                                                      )
                                                : null,
                                            child: const Text("Sau"),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
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
      ),
    );
  }

  // ==========================================================
  // CÁC HÀM HELPER
  // ==========================================================
  String _getWarehouseName(int id) {
    final state = context.read<WarehouseCubit>().state;
    if (state is WarehouseLoaded) {
      return state.warehouses
              .where((x) => x.warehouseId == id)
              .firstOrNull
              ?.name ??
          'Kho ID: $id';
    }
    return 'Kho ID: $id';
  }

  String _getPONumber(int? id) {
    if (id == null) return 'Không có';
    final state = context.read<POHeaderCubit>().state;
    if (state is POHeaderLoaded) {
      return state.pos.where((x) => x.poId == id).firstOrNull?.poNumber ??
          'PO ID: $id';
    }
    return 'PO ID: $id';
  }

  String _getMaterialCode(int id) {
    final state = context.read<MaterialCubit>().state;
    if (state is MaterialLoaded) {
      return state.materials
              .where((x) => x.materialId == id)
              .firstOrNull
              ?.materialCode ??
          'ID: $id';
    }
    return 'ID: $id';
  }

  Widget _buildTimeFilterChip(
    String label,
    String filterValue,
    String currentFilter,
  ) {
    bool isSelected = filterValue == currentFilter;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: _primaryColor.withOpacity(0.1),
        checkmarkColor: _primaryColor,
        labelStyle: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? _primaryColor : Colors.black87,
        ),
        onSelected: (_) =>
            context.read<MaterialReceiptCubit>().applyFilter(filterValue),
      ),
    );
  }

  Widget _buildDetailedReceiptCard(
    MaterialReceipt r,
    NumberFormat numFmt,
    bool isMobile,
  ) {
    bool isCompleted = r.status == 'Completed';
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCompleted ? Colors.green.shade200 : Colors.orange.shade200,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 20,
                            color: _primaryColor,
                          ),
                          Text(
                            r.receiptNumber ?? 'Chưa có mã',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: _primaryColor,
                            ),
                          ),
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
                            ),
                            child: Text(
                              isCompleted ? "ĐÃ DUYỆT" : "BẢN NHÁP",
                              style: TextStyle(
                                color: isCompleted
                                    ? Colors.green.shade700
                                    : Colors.orange.shade700,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Ngày tạo: ${r.receiptDate ?? '-'}",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        isCompleted ? Icons.visibility : Icons.edit,
                        color: isCompleted ? Colors.blue : Colors.blueGrey,
                      ),
                      tooltip: isCompleted ? "Xem chi tiết" : "Chỉnh sửa",
                      onPressed: () => _openForm(r),
                    ),
                    if (!isCompleted)
                      IconButton(
                        icon: const Icon(
                          Icons.check_circle,
                          color: Colors.teal,
                        ),
                        tooltip: "Duyệt Phiếu",
                        onPressed: () => context
                            .read<MaterialReceiptCubit>()
                            .completeReceipt(r),
                      ),
                    if (!isCompleted)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: "Xóa",
                        onPressed: () => context
                            .read<MaterialReceiptCubit>()
                            .deleteReceipt(r.receiptId ?? 0),
                      ),
                  ],
                ),
              ],
            ),
            const Divider(),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildInfoItem(
                  Icons.shopping_cart_outlined,
                  "Đơn PO:",
                  _getPONumber(r.poHeaderId),
                ),
                _buildInfoItem(
                  Icons.warehouse_outlined,
                  "Kho nhận:",
                  _getWarehouseName(r.warehouseId),
                ),
                _buildInfoItem(
                  Icons.directions_boat_outlined,
                  "Container:",
                  r.containerNo != null && r.containerNo!.isNotEmpty
                      ? r.containerNo!
                      : "N/A",
                ),
                _buildInfoItem(
                  Icons.lock_outline,
                  "Seal:",
                  r.sealNo != null && r.sealNo!.isNotEmpty ? r.sealNo! : "N/A",
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Chi tiết hàng hóa (${r.details.length} loại):",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (r.details.isEmpty)
                    const Text(
                      "Chưa có hàng hóa nào.",
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    )
                  else
                    ...r.details.map((d) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.inventory_2,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: Text(
                                _getMaterialCode(d.materialId),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Wrap(
                                spacing: 8,
                                children: [
                                  Text(
                                    "${numFmt.format(d.receivedQuantityKg)} Kg",
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    "|  ${numFmt.format(d.receivedQuantityCones)} cuộn",
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    "|  ${d.numberOfPallets} Pallet",
                                    style: const TextStyle(
                                      color: Colors.blueGrey,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isMobile &&
                                d.location != null &&
                                d.location!.isNotEmpty)
                              Expanded(
                                flex: 1,
                                child: Text(
                                  "Vị trí: ${d.location}",
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
            if (r.note != null && r.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                "Ghi chú: ${r.note}",
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          "$label ",
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }
}
