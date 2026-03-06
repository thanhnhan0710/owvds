import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../core/widgets/responsive_layout.dart';
import '../../../../inventory/supplier/presentation/bloc/supplier_cubit.dart';
import '../../incoterm/presentation/bloc/incoterm_cubit.dart';
import '../../po_status/presentation/bloc/po_status_cubit.dart';
import '../../po_header/domain/po_header_model.dart';
import '../../po_header/presentation/bloc/po_header_cubit.dart';

import 'po_detail_drawer.dart';

class POListView extends StatelessWidget {
  const POListView({super.key});

  final Color _primaryColor = const Color(0xFF003366);

  void _openEditDrawer(BuildContext context, PurchaseOrderHeader po) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "PODrawer",
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: ResponsiveLayout.isMobile(context) ? double.infinity : 900,
              height: double.infinity,
              child: PODetailDrawer(po: po),
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOut)),
          child: child,
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, PurchaseOrderHeader po) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: Text("Xóa Đơn hàng ${po.poNumber}? Sẽ xóa toàn bộ chi tiết."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              context.read<POHeaderCubit>().deletePO(po.poId);
              Navigator.pop(ctx);
            },
            child: const Text("Xóa"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: BlocBuilder<POHeaderCubit, POHeaderState>(
              builder: (context, state) {
                if (state is POHeaderLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is POHeaderError) {
                  return Center(
                    child: Text(
                      state.message,
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                if (state is POHeaderLoaded) {
                  if (state.pos.isEmpty) {
                    return const Center(
                      child: Text(
                        "Không có Đơn mua hàng nào thỏa mãn điều kiện lọc.",
                      ),
                    );
                  }
                  if (isMobile) return _buildMobileList(context, state.pos);
                  return _buildDesktopTable(context, state.pos);
                }
                return const SizedBox();
              },
            ),
          ),

          // ── Pagination Footer ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                BlocBuilder<POHeaderCubit, POHeaderState>(
                  builder: (ctx, st) {
                    int total = (st is POHeaderLoaded) ? st.totalCount : 0;
                    return Text(
                      "Đang xem kết quả lọc trên tổng $total",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    );
                  },
                ),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: null,
                      child: const Icon(Icons.chevron_left, size: 18),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: null,
                      child: const Icon(Icons.chevron_right, size: 18),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DESKTOP: DataTable (giữ nguyên)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildDesktopTable(
    BuildContext context,
    List<PurchaseOrderHeader> pos,
  ) {
    final numFormat = NumberFormat("#,##0", "en_US");

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
          showBottomBorder: true,
          dataRowMinHeight: 60,
          dataRowMaxHeight: 60,
          showCheckboxColumn: false,
          columns: const [
            DataColumn(
              label: Text(
                'Số PO',
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
              label: Text(
                'Ngày đặt',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Dự kiến ETA',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Tổng tiền',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Incoterm',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Trạng thái',
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
          rows: pos.map((po) {
            return DataRow(
              onSelectChanged: (selected) {
                if (selected == true) _openEditDrawer(context, po);
              },
              cells: [
                DataCell(
                  Text(
                    po.poNumber,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                ),
                DataCell(
                  BlocBuilder<SupplierCubit, SupplierState>(
                    builder: (ctx, state) {
                      String supName = "Loading...";
                      if (state is SupplierLoaded) {
                        final sup = state.suppliers
                            .where((s) => s.supplierId == po.vendorId)
                            .firstOrNull;
                        if (sup != null)
                          supName = sup.shortName ?? sup.supplierName;
                      }
                      return Text(
                        supName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      );
                    },
                  ),
                ),
                DataCell(Text(po.orderDate ?? '-')),
                DataCell(
                  Text(
                    po.expectedArrivalDate ?? '-',
                    style: const TextStyle(
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    "${numFormat.format(po.totalAmount)} ₫",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataCell(_buildIncotermBadge(po.incotermId)),
                DataCell(_buildStatusBadge(po.statusId)),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.remove_red_eye,
                          color: Colors.blue,
                          size: 18,
                        ),
                        onPressed: () => _openEditDrawer(context, po),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                          size: 18,
                        ),
                        onPressed: () => _confirmDelete(context, po),
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

  // ═══════════════════════════════════════════════════════════════════════════
  // MOBILE: Card đầy đủ thông tin — tương đương desktop table
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildMobileList(BuildContext context, List<PurchaseOrderHeader> pos) {
    final numFormat = NumberFormat("#,##0", "en_US");

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: pos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final po = pos[index];

        return InkWell(
          onTap: () => _openEditDrawer(context, po),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade100,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Row 1: Số PO + Tổng tiền ────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      po.poNumber,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "${numFormat.format(po.totalAmount)} ₫",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Divider(height: 1),
                const SizedBox(height: 10),

                // ── Row 2: Nhà cung cấp ─────────────────────────────────
                BlocBuilder<SupplierCubit, SupplierState>(
                  builder: (ctx, state) {
                    String supName = "...";
                    if (state is SupplierLoaded) {
                      final sup = state.suppliers
                          .where((s) => s.supplierId == po.vendorId)
                          .firstOrNull;
                      if (sup != null)
                        supName = sup.shortName ?? sup.supplierName;
                    }
                    return _infoRow(
                      icon: Icons.business,
                      iconColor: _primaryColor,
                      label: "Nhà cung cấp",
                      value: supName,
                      valueBold: true,
                    );
                  },
                ),
                const SizedBox(height: 6),

                // ── Row 3: Ngày đặt + ETA ──────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _infoRow(
                        icon: Icons.calendar_today,
                        iconColor: Colors.grey,
                        label: "Ngày đặt",
                        value: po.orderDate ?? '-',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _infoRow(
                        icon: Icons.local_shipping_outlined,
                        iconColor: Colors.deepOrange,
                        label: "Dự kiến ETA",
                        value: po.expectedArrivalDate ?? '-',
                        valueColor: Colors.deepOrange,
                        valueBold: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ── Row 4: Incoterm + Trạng thái ──────────────────────
                Row(
                  children: [
                    _buildIncotermBadge(po.incotermId),
                    const SizedBox(width: 8),
                    _buildStatusBadge(po.statusId),
                    const Spacer(),

                    // Hành động
                    IconButton(
                      icon: const Icon(
                        Icons.remove_red_eye,
                        color: Colors.blue,
                        size: 20,
                      ),
                      tooltip: "Xem / Sửa",
                      onPressed: () => _openEditDrawer(context, po),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      tooltip: "Xóa",
                      onPressed: () => _confirmDelete(context, po),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
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

  // ─── Shared badge builders ────────────────────────────────────────────────

  Widget _buildIncotermBadge(int? incotermId) {
    if (incotermId == null) {
      return const SizedBox.shrink();
    }
    return BlocBuilder<IncotermCubit, IncotermState>(
      builder: (ctx, state) {
        String code = "?";
        if (state is IncotermLoaded) {
          final inc = state.incoterms
              .where((i) => i.incotermId == incotermId)
              .firstOrNull;
          if (inc != null) code = inc.incotermCode;
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            code,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(int? statusId) {
    if (statusId == null) {
      return const SizedBox.shrink();
    }
    return BlocBuilder<POStatusCubit, POStatusState>(
      builder: (ctx, state) {
        String statusName = "?";
        if (state is POStatusLoaded) {
          final s = state.statuses
              .where((i) => i.statusId == statusId)
              .firstOrNull;
          if (s != null) statusName = s.statusCode;
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            border: Border.all(color: Colors.blue.shade200),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            statusName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
        );
      },
    );
  }

  // ─── Helper: 1 dòng info với icon + label + value ────────────────────────
  Widget _infoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    Color? valueColor,
    bool valueBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 5),
        Text(
          "$label: ",
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Flexible(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: valueColor ?? Colors.black87,
              fontWeight: valueBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
