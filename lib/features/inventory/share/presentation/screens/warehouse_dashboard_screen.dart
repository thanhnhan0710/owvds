import 'package:flutter/material.dart' hide MaterialState;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

// Đảm bảo import đúng đường dẫn đến file AdminSidebar và ResponsiveLayout của bạn
import 'package:owvds/features/home/presentation/widgets/admin_sidebar.dart';
import 'package:owvds/core/widgets/responsive_layout.dart';
import 'package:owvds/core/network/websocket_service.dart';

import 'package:owvds/features/inventory/material/presentation/bloc/material_cubit.dart';
import 'package:owvds/features/inventory/material/domain/material_model.dart';
import 'package:owvds/features/inventory/material_receipt/presentation/bloc/material_receipt_cubit.dart';
import 'package:owvds/features/inventory/material_receipt/domain/material_receipt_model.dart';
// [MỚI]: Import Cubit Tồn kho để tính toán cảnh báo
import 'package:owvds/features/inventory/material_inventory/presentation/bloc/material_inventory_cubit.dart';
import 'package:owvds/features/inventory/material_inventory/domain/material_inventory_model.dart';
// [MỚI]: Import Cubit Xuất kho để lấy số phiếu xuất thực
import 'package:owvds/features/inventory/material_export/presentation/bloc/material_export_cubit.dart';
import 'package:owvds/features/inventory/material_export/domain/material_export_model.dart';

class WarehouseDashboardScreen extends StatefulWidget {
  const WarehouseDashboardScreen({super.key});

  @override
  State<WarehouseDashboardScreen> createState() =>
      _WarehouseDashboardScreenState();
}

class _WarehouseDashboardScreenState extends State<WarehouseDashboardScreen> {
  final Color _primaryColor = const Color(0xFF003366);
  final Color _bgColor = const Color(0xFFF5F7FA);

  // Khai báo key để mở Drawer trên Mobile
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Tải toàn bộ dữ liệu cần thiết cho Dashboard
    context.read<MaterialCubit>().loadMaterials();
    context.read<MaterialReceiptCubit>().loadInitial();
    context.read<MaterialInventoryCubit>().loadInventories();
    // [MỚI]: Tải phiếu xuất để lấy KPI thực
    context.read<MaterialExportCubit>().loadExports(isRefresh: true);

    // [WEBSOCKET]: Lắng nghe sự kiện để cập nhật Dashboard Realtime
    WebSocketService().connect();
    WebSocketService().addListener(_onWebSocketMessage);
  }

  void _onWebSocketMessage(String message) {
    if (!mounted) return;
    if (message == "REFRESH_MATERIAL_RECEIPTS") {
      context.read<MaterialReceiptCubit>().loadInitial();
    } else if (message == "REFRESH_MATERIAL_INVENTORIES") {
      context.read<MaterialInventoryCubit>().loadInventories();
    } else if (message == "REFRESH_MATERIAL_EXPORTS") {
      context.read<MaterialExportCubit>().loadExports(isRefresh: true);
    }
  }

  @override
  void dispose() {
    WebSocketService().removeListener(_onWebSocketMessage);
    super.dispose();
  }

  // Hàm xử lý điều hướng chung cho Sidebar
  void _onNavigate(String route) {
    if (ResponsiveLayout.isMobile(context) &&
        _scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.pop(context); // Đóng drawer nếu đang ở trên mobile
    }
    if (route != '#') {
      context.go(route); // Chuyển trang
    }
  }

  // ============================================================
  // THÔNG BÁO: Bottom sheet danh sách cảnh báo tồn kho thấp
  // ============================================================
  void _showNotificationSheet(
    List<({MaterialInventory inv, MaterialItem mat})> lowStockItems,
  ) {
    final numFmt = NumberFormat("#,##0.##", "en_US");
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          maxChildSize: 0.85,
          minChildSize: 0.3,
          builder: (_, scrollCtrl) => Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red.shade600,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Cảnh báo tồn kho thấp (${lowStockItems.length})",
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              lowStockItems.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: Colors.green,
                            size: 48,
                          ),
                          SizedBox(height: 12),
                          Text(
                            "Không có cảnh báo tồn kho!",
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Expanded(
                      child: ListView.separated(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: lowStockItems.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1, indent: 16, endIndent: 16),
                        itemBuilder: (_, i) {
                          final item = lowStockItems[i];
                          final pct = item.mat.minStockLevel > 0
                              ? (item.inv.quantityKg / item.mat.minStockLevel)
                                    .clamp(0.0, 1.0)
                              : 0.0;
                          final isUrgent = pct < 0.3;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isUrgent
                                  ? Colors.red.shade50
                                  : Colors.orange.shade50,
                              child: Icon(
                                isUrgent
                                    ? Icons.error_outline
                                    : Icons.warning_amber_outlined,
                                color: isUrgent ? Colors.red : Colors.orange,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              item.mat.materialCode,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: pct,
                                  backgroundColor: Colors.grey.shade200,
                                  color: isUrgent ? Colors.red : Colors.orange,
                                  minHeight: 6,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Tồn: ${numFmt.format(item.inv.quantityKg)} kg  •  Tối thiểu: ${numFmt.format(item.mat.minStockLevel)} kg",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isUrgent
                                    ? Colors.red.shade50
                                    : Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isUrgent
                                      ? Colors.red.shade200
                                      : Colors.orange.shade200,
                                ),
                              ),
                              child: Text(
                                "${(pct * 100).toStringAsFixed(0)}%",
                                style: TextStyle(
                                  color: isUrgent
                                      ? Colors.red.shade700
                                      : Colors.orange.shade800,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            isThreeLine: true,
                          );
                        },
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // BÁO CÁO KHO: Dialog tổng hợp nhập / xuất / tồn
  // ============================================================
  void _showWarehouseReport({
    required String matCountStr,
    required String receiptCountStr,
    required String exportCountStr,
    required String lowStockStr,
    required List<MaterialReceipt> receipts,
    required List<MaterialExport> exports,
    required List<MaterialInventory> inventories,
    required List<MaterialItem> materials,
  }) {
    final numFmt = NumberFormat("#,##0.##", "en_US");

    // Tổng nhập (kg) từ danh sách phiếu nhập
    double totalInKg = receipts.fold(
      0.0,
      (sum, r) => sum + r.details.fold(0.0, (s, d) => s + d.receivedQuantityKg),
    );
    // Tổng xuất (kg) từ danh sách phiếu xuất
    double totalOutKg = exports.fold(
      0.0,
      (sum, e) => sum + e.details.fold(0.0, (s, d) => s + d.quantityKg),
    );
    // Tổng tồn kho hiện tại (kg)
    double totalStockKg = inventories.fold(
      0.0,
      (sum, inv) => sum + inv.quantityKg,
    );

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620, maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: _primaryColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bar_chart, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        "Báo Cáo Tổng Hợp Kho NVL",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white70,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- KPI Cards ---
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 2.2,
                        children: [
                          _buildReportKpi(
                            "Tổng Nhập",
                            "${numFmt.format(totalInKg)} kg",
                            Icons.arrow_downward,
                            Colors.teal,
                          ),
                          _buildReportKpi(
                            "Tổng Xuất",
                            "${numFmt.format(totalOutKg)} kg",
                            Icons.arrow_upward,
                            Colors.orange,
                          ),
                          _buildReportKpi(
                            "Tồn Kho",
                            "${numFmt.format(totalStockKg)} kg",
                            Icons.inventory_2,
                            Colors.blue,
                          ),
                          _buildReportKpi(
                            "Cảnh Báo",
                            "$lowStockStr mã",
                            Icons.warning_amber_rounded,
                            Colors.red,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // --- Bảng cảnh báo tồn thấp ---
                      const Text(
                        "CHI TIẾT CẢNH BÁO TỒN KHO THẤP",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            // Header row
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(8),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Expanded(
                                    flex: 3,
                                    child: Text(
                                      "Mã NVL",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const Expanded(
                                    flex: 2,
                                    child: Text(
                                      "Tồn (kg)",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  const Expanded(
                                    flex: 2,
                                    child: Text(
                                      "Tối thiểu",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      "Trạng thái",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            ...() {
                              final lowList =
                                  <
                                    ({MaterialInventory inv, MaterialItem mat})
                                  >[];
                              for (var inv in inventories) {
                                try {
                                  final mat = materials.firstWhere(
                                    (m) => m.materialId == inv.materialId,
                                  );
                                  if (mat.minStockLevel > 0 &&
                                      inv.quantityKg < mat.minStockLevel) {
                                    lowList.add((inv: inv, mat: mat));
                                  }
                                } catch (_) {}
                              }
                              if (lowList.isEmpty) {
                                return [
                                  const Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Center(
                                      child: Text(
                                        "✅ Không có mặt hàng nào dưới mức tối thiểu",
                                        style: TextStyle(color: Colors.green),
                                      ),
                                    ),
                                  ),
                                ];
                              }
                              return lowList.map((item) {
                                final isUrgent =
                                    item.inv.quantityKg <
                                    item.mat.minStockLevel * 0.3;
                                return Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 3,
                                            child: Text(
                                              item.mat.materialCode,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              numFmt.format(
                                                item.inv.quantityKg,
                                              ),
                                              textAlign: TextAlign.right,
                                              style: TextStyle(
                                                color: isUrgent
                                                    ? Colors.red
                                                    : Colors.orange,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              numFmt.format(
                                                item.mat.minStockLevel,
                                              ),
                                              textAlign: TextAlign.right,
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Center(
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: isUrgent
                                                      ? Colors.red.shade50
                                                      : Colors.orange.shade50,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  border: Border.all(
                                                    color: isUrgent
                                                        ? Colors.red.shade200
                                                        : Colors
                                                              .orange
                                                              .shade200,
                                                  ),
                                                ),
                                                child: Text(
                                                  isUrgent
                                                      ? "Khẩn cấp"
                                                      : "Thấp",
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: isUrgent
                                                        ? Colors.red.shade700
                                                        : Colors
                                                              .orange
                                                              .shade800,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Divider(height: 1),
                                  ],
                                );
                              }).toList();
                            }(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // --- Giao dịch gần đây ---
                      const Text(
                        "GIAO DỊCH GẦN ĐÂY NHẤT",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...() {
                        // Gộp 5 phiếu nhập + 5 phiếu xuất, sort theo ngày giảm dần
                        final entries =
                            <
                              ({
                                String code,
                                String desc,
                                DateTime date,
                                bool isIn,
                                double kg,
                              })
                            >[];
                        for (var r in receipts.take(5)) {
                          final kg = r.details.fold(
                            0.0,
                            (s, d) => s + d.receivedQuantityKg,
                          );
                          final date = r.receiptDate is DateTime
                              ? r.receiptDate as DateTime
                              : DateTime.tryParse(
                                      r.receiptDate?.toString() ?? '',
                                    ) ??
                                    DateTime.now();
                          entries.add((
                            code: r.receiptNumber ?? '-',
                            desc: "Nhập kho NVL",
                            date: date,
                            isIn: true,
                            kg: kg,
                          ));
                        }
                        for (var e in exports.take(5)) {
                          final kg = e.details.fold(
                            0.0,
                            (s, d) => s + d.quantityKg,
                          );
                          entries.add((
                            code: e.exportCode,
                            desc: "Xuất kho NVL",
                            date: e.createdAt,
                            isIn: false,
                            kg: kg,
                          ));
                        }
                        entries.sort((a, b) => b.date.compareTo(a.date));
                        return entries.take(6).map((entry) {
                          final dtStr = DateFormat(
                            'dd/MM HH:mm',
                          ).format(entry.date);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: entry.isIn
                                  ? Colors.teal.shade50
                                  : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: entry.isIn
                                    ? Colors.teal.shade100
                                    : Colors.orange.shade100,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  entry.isIn
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
                                  color: entry.isIn
                                      ? Colors.teal
                                      : Colors.orange,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.code,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        entry.desc,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "${entry.isIn ? '+' : '-'} ${numFmt.format(entry.kg)} kg",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: entry.isIn
                                            ? Colors.teal
                                            : Colors.orange,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      dtStr,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList();
                      }(),
                    ],
                  ),
                ),
              ),

              // Footer
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Đóng"),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportKpi(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Cụm Avatar và Thông báo (Truyền số lượng cảnh báo vào)
  List<Widget> _buildAppBarActions(
    int alertCount,
    List<({MaterialInventory inv, MaterialItem mat})> lowStockItems,
  ) {
    return [
      IconButton(
        icon: Badge(
          label: Text(alertCount.toString()),
          isLabelVisible: alertCount > 0,
          child: const Icon(Icons.notifications_active_outlined),
        ),
        onPressed: () => _showNotificationSheet(lowStockItems),
        tooltip: "Cảnh báo tồn kho",
      ),
      const SizedBox(width: 8),
      const CircleAvatar(
        radius: 16,
        backgroundColor: Color(0xFF003366),
        child: Icon(Icons.person, color: Colors.white, size: 18),
      ),
      const SizedBox(width: 16),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = ResponsiveLayout.isMobile(context);
    final isTablet = screenWidth >= 600 && screenWidth < 1000;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    // Mock User Info
    bool isAdmin = true;
    String currentPath = '/warehouse-dashboard';

    // Lắng nghe trạng thái của các Cubit
    final matState = context.watch<MaterialCubit>().state;
    final invState = context.watch<MaterialInventoryCubit>().state;
    final receiptState = context.watch<MaterialReceiptCubit>().state;
    // [MỚI]: Watch export cubit để lấy số phiếu xuất thực
    final exportState = context.watch<MaterialExportCubit>().state;

    // --- TÍNH TOÁN KPI ---
    String matCountStr = "...";
    if (matState is MaterialLoaded) {
      matCountStr =
          (matState as dynamic).totalCount?.toString() ??
          matState.materials.length.toString();
    }

    String receiptCountStr = "...";
    if (receiptState is MaterialReceiptLoaded) {
      receiptCountStr =
          receiptState.receipts.length.toString() +
          (receiptState.hasNextPage ? "+" : "");
    }

    // [MỚI]: Số phiếu xuất thực từ Cubit
    String exportCountStr = "...";
    List<MaterialExport> exports = [];
    if (exportState is MaterialExportLoaded) {
      exportCountStr =
          exportState.exports.length.toString() +
          (exportState.hasMore ? "+" : "");
      exports = exportState.exports;
    }

    // Tính toán Tồn kho sắp hết (Low Stock) và build danh sách chi tiết
    int lowStockCount = 0;
    bool invHasNext = false;
    final lowStockItems = <({MaterialInventory inv, MaterialItem mat})>[];
    if (matState is MaterialLoaded && invState is MaterialInventoryLoaded) {
      invHasNext = invState.hasNextPage;
      for (var inv in invState.inventories) {
        try {
          final mat = matState.materials.firstWhere(
            (m) => m.materialId == inv.materialId,
          );
          if (mat.minStockLevel > 0 && inv.quantityKg < mat.minStockLevel) {
            lowStockCount++;
            lowStockItems.add((inv: inv, mat: mat));
          }
        } catch (_) {}
      }
    }
    String lowStockStr =
        (matState is MaterialLoaded && invState is MaterialInventoryLoaded)
        ? "$lowStockCount${invHasNext ? '+' : ''}"
        : "...";

    // Danh sách receipts và inventories thực để dùng trong Báo cáo
    final receipts = receiptState is MaterialReceiptLoaded
        ? receiptState.receipts
        : <MaterialReceipt>[];
    final inventories = invState is MaterialInventoryLoaded
        ? invState.inventories
        : <MaterialInventory>[];
    final materials = matState is MaterialLoaded
        ? matState.materials
        : <MaterialItem>[];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _bgColor,

      appBar: isDesktop
          ? null
          : AppBar(
              title: const Text(
                "Bảng Điều Khiển - Kho NVL",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              backgroundColor: Colors.white,
              foregroundColor: _primaryColor,
              elevation: 0.5,
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              actions: _buildAppBarActions(
                lowStockCount,
                lowStockItems,
              ), // Truyền số cảnh báo
            ),

      drawer: isDesktop
          ? null
          : Drawer(
              child: AdminSidebar(
                currentPath: currentPath,
                isAdmin: isAdmin,
                onNavigate: _onNavigate,
              ),
            ),

      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop)
            AdminSidebar(
              currentPath: currentPath,
              isAdmin: isAdmin,
              onNavigate: _onNavigate,
            ),

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
                          "Bảng Điều Khiển - Kho NVL",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: _primaryColor,
                          ),
                        ),
                        const Spacer(),
                        ..._buildAppBarActions(
                          lowStockCount,
                          lowStockItems,
                        ), // Truyền số cảnh báo
                      ],
                    ),
                  ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- PHẦN 1: TỔNG QUAN KPI ---
                        const Text(
                          "TỔNG QUAN TRONG NGÀY",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: isMobile ? 2 : (isTablet ? 4 : 4),
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: isMobile ? 1.5 : 2.0,
                          children: [
                            _buildKpiCard(
                              title: "Mã NVL",
                              value: matCountStr,
                              icon: Icons.category,
                              color: Colors.blue,
                            ),
                            _buildKpiCard(
                              title: "Sắp hết hàng",
                              value: lowStockStr,
                              icon: Icons.warning_amber_rounded,
                              color: Colors.redAccent,
                            ),
                            _buildKpiCard(
                              title: "Phiếu Nhập",
                              value: receiptCountStr,
                              icon: Icons.input,
                              color: Colors.teal,
                            ),
                            _buildKpiCard(
                              title: "Phiếu Xuất",
                              value: exportCountStr,
                              icon: Icons.output,
                              color: Colors.orange,
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // --- PHẦN 2: DANH MỤC CHỨC NĂNG ---
                        const Text(
                          "DANH MỤC QUẢN LÝ",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: isMobile ? 1 : (isTablet ? 2 : 3),
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: isMobile ? 3.0 : 2.5,
                          children: [
                            _buildFeatureCard(
                              context,
                              title: "Đơn Mua Hàng (PO)",
                              subtitle: "Quản lý mua sắm vật tư",
                              icon: Icons.shopping_cart,
                              color: Colors.blueAccent,
                              onTap: () => _onNavigate('/purchase-orders'),
                            ),
                            _buildFeatureCard(
                              context,
                              title: "Nhà Cung Cấp",
                              subtitle: "Quản lý đối tác, liên hệ",
                              icon: Icons.local_shipping,
                              color: Colors.indigo,
                              onTap: () => _onNavigate('/suppliers'),
                            ),
                            _buildFeatureCard(
                              context,
                              title: "Nguyên Vật Liệu",
                              subtitle: "Danh mục mã NVL, quy cách",
                              icon: Icons.layers,
                              color: Colors.blueGrey,
                              onTap: () => _onNavigate('/materials'),
                            ),
                            _buildFeatureCard(
                              context,
                              title: "Tồn Kho NVL",
                              subtitle: "Tra cứu số lượng, thẻ kho",
                              icon: Icons.inventory,
                              color: Colors.purple,
                              onTap: () => _onNavigate('/inventorys'),
                            ),
                            _buildFeatureCard(
                              context,
                              title: "Nhập Kho NVL",
                              subtitle: "Tạo phiếu nhập, kiểm hàng",
                              icon: Icons.add_box,
                              color: Colors.teal,
                              onTap: () => _onNavigate('/stock-in'),
                            ),
                            _buildFeatureCard(
                              context,
                              title: "Xuất Kho NVL",
                              subtitle: "Xuất sản xuất, xuất trả",
                              icon: Icons.outbox,
                              color: Colors.orange.shade700,
                              onTap: () => _onNavigate('/material-exports'),
                            ),
                            _buildFeatureCard(
                              context,
                              title: "Báo Cáo Kho",
                              subtitle: "Nhập xuất tồn, cảnh báo",
                              icon: Icons.bar_chart,
                              color: Colors.redAccent,
                              onTap: () => _showWarehouseReport(
                                matCountStr: matCountStr,
                                receiptCountStr: receiptCountStr,
                                exportCountStr: exportCountStr,
                                lowStockStr: lowStockStr,
                                receipts: receipts,
                                exports: exports,
                                inventories: inventories,
                                materials: materials,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // --- PHẦN 3: GIAO DỊCH GẦN ĐÂY ---
                        if (!isMobile) ...[
                          const Text(
                            "GIAO DỊCH GẦN ĐÂY",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: () {
                              // Gộp phiếu nhập + phiếu xuất, sort theo ngày giảm dần
                              final numFmt = NumberFormat("#,##0.##", "en_US");
                              final entries =
                                  <
                                    ({
                                      String code,
                                      String desc,
                                      DateTime date,
                                      bool isIn,
                                      double kg,
                                    })
                                  >[];
                              for (var r in receipts.take(5)) {
                                final kg = r.details.fold(
                                  0.0,
                                  (s, d) => s + d.receivedQuantityKg,
                                );
                                final date = r.receiptDate is DateTime
                                    ? r.receiptDate as DateTime
                                    : DateTime.tryParse(
                                            r.receiptDate?.toString() ?? '',
                                          ) ??
                                          DateTime.now();
                                entries.add((
                                  code: r.receiptNumber ?? '-',
                                  desc: "Nhập kho NVL",
                                  date: date,
                                  isIn: true,
                                  kg: kg,
                                ));
                              }
                              for (var e in exports.take(5)) {
                                final kg = e.details.fold(
                                  0.0,
                                  (s, d) => s + d.quantityKg,
                                );
                                entries.add((
                                  code: e.exportCode,
                                  desc: "Xuất kho NVL",
                                  date: e.createdAt,
                                  isIn: false,
                                  kg: kg,
                                ));
                              }
                              entries.sort((a, b) => b.date.compareTo(a.date));
                              final display = entries.take(6).toList();

                              if (display.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Center(
                                    child: Text(
                                      "Chưa có giao dịch nào.",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                );
                              }

                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: display.length,
                                separatorBuilder: (_, _) => Divider(
                                  height: 1,
                                  color: Colors.grey.shade200,
                                ),
                                itemBuilder: (_, index) {
                                  final entry = display[index];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: entry.isIn
                                          ? Colors.teal.shade50
                                          : Colors.orange.shade50,
                                      child: Icon(
                                        entry.isIn
                                            ? Icons.arrow_downward
                                            : Icons.arrow_upward,
                                        color: entry.isIn
                                            ? Colors.teal
                                            : Colors.orange,
                                        size: 18,
                                      ),
                                    ),
                                    title: Text(
                                      entry.code,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(entry.desc),
                                    trailing: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          DateFormat(
                                            'dd/MM HH:mm',
                                          ).format(entry.date),
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          "${entry.isIn ? '+' : '-'} ${numFmt.format(entry.kg)} kg",
                                          style: TextStyle(
                                            color: entry.isIn
                                                ? Colors.teal
                                                : Colors.orange,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            }(),
                          ),
                        ],
                      ],
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

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: _primaryColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.7), color],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
