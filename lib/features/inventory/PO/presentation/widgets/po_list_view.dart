import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:owvds/features/inventory/PO/incoterm/presentation/bloc/incoterm_cubit.dart';
import 'package:owvds/features/inventory/PO/po_header/domain/po_header_model.dart';
import 'package:owvds/features/inventory/PO/po_header/presentation/bloc/po_header_cubit.dart';
import 'package:owvds/features/inventory/PO/po_status/presentation/bloc/po_status_cubit.dart';

import '../../../../../core/widgets/responsive_layout.dart';
import '../../../../inventory/supplier/presentation/bloc/supplier_cubit.dart';

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
              width: ResponsiveLayout.isMobile(context)
                  ? double.infinity
                  : 1000,
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
        content: Text(
          "Xóa Đơn hàng ${po.poNumber}? Sẽ xóa toàn bộ chi tiết vật tư bên trong.",
        ),
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
                if (state is POHeaderLoading)
                  return const Center(child: CircularProgressIndicator());
                if (state is POHeaderError)
                  return Center(
                    child: Text(
                      state.message,
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                if (state is POHeaderLoaded) {
                  if (state.pos.isEmpty)
                    return const Center(
                      child: Text(
                        "Không có Đơn mua hàng nào thỏa mãn điều kiện lọc.",
                      ),
                    );

                  if (isMobile) return _buildMobileList(context, state.pos);
                  return _buildDesktopTable(context, state.pos);
                }
                return const SizedBox();
              },
            ),
          ),
          // Pagination Footer
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
                'Tổng tiền',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Điều kiện',
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
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      );
                    },
                  ),
                ),
                DataCell(Text(po.orderDate ?? '-')),
                DataCell(
                  Text(
                    "${numFormat.format(po.totalAmount)} \$",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataCell(
                  BlocBuilder<IncotermCubit, IncotermState>(
                    builder: (ctx, state) {
                      if (po.incotermId == null) return const Text("-");
                      String code = "?";
                      if (state is IncotermLoaded) {
                        final inc = state.incoterms
                            .where((i) => i.incotermId == po.incotermId)
                            .firstOrNull;
                        if (inc != null) code = inc.incotermCode;
                      }
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
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
                  ),
                ),
                DataCell(
                  BlocBuilder<POStatusCubit, POStatusState>(
                    builder: (ctx, state) {
                      if (po.statusId == null) return const Text("-");
                      String statusName = "?";
                      if (state is POStatusLoaded) {
                        final s = state.statuses
                            .where((i) => i.statusId == po.statusId)
                            .firstOrNull;
                        if (s != null) statusName = s.statusCode;
                      }
                      // Fake colors based on common status keywords
                      Color bgColor = Colors.blue.shade50;
                      Color txtColor = Colors.blue.shade700;
                      if (statusName.toLowerCase().contains("completed")) {
                        bgColor = Colors.green.shade50;
                        txtColor = Colors.green.shade700;
                      } else if (statusName.toLowerCase().contains("partial")) {
                        bgColor = Colors.orange.shade50;
                        txtColor = Colors.orange.shade700;
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: txtColor,
                          ),
                        ),
                      );
                    },
                  ),
                ),
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

  Widget _buildMobileList(BuildContext context, List<PurchaseOrderHeader> pos) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: pos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final po = pos[index];
        return InkWell(
          onTap: () => _openEditDrawer(context, po),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      "${NumberFormat("#,##0.##", "en_US").format(po.totalAmount)} \$",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text("Ngày đặt: ${po.orderDate ?? '-'}"),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
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
              ],
            ),
          ),
        );
      },
    );
  }
}
