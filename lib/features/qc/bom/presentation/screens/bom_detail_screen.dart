import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:owvds/core/widgets/responsive_layout.dart';
import 'package:owvds/features/inventory/material/presentation/bloc/material_cubit.dart'
    as mat_bloc;
import 'package:owvds/features/production/loom_state/product/presentation/bloc/product_cubit.dart';

// Models
import '../../domain/bom_model.dart';

// Cubits
import '../bloc/bom_cubit.dart';

// Import file dialog
import 'material_detail_dialog.dart';

class BOMDetailScreen extends StatefulWidget {
  final int? bomId;

  const BOMDetailScreen({super.key, required this.bomId});

  @override
  State<BOMDetailScreen> createState() => _BOMDetailScreenState();
}

class _BOMDetailScreenState extends State<BOMDetailScreen> {
  final _numberFormat = NumberFormat("#,##0.000");
  final _percentFormat = NumberFormat("#,##0.0'%'");
  final _precisionFormat = NumberFormat("#,##0.#####");

  @override
  void initState() {
    super.initState();
    if (widget.bomId != null) {
      context.read<BOMCubit>().loadBOMDetailView(widget.bomId!);
    }
    context.read<mat_bloc.MaterialCubit>().loadMaterials();
    context.read<ProductCubit>().loadProducts();
  }

  List<BOMDetail> _generateFullDisplayList(
    List<BOMDetail> currentDetails,
    int bomId,
  ) {
    List<BOMDetail> fullList = [];
    for (var type in BOMComponentType.values) {
      final existingItems = currentDetails
          .where((d) => d.componentType == type)
          .toList();
      if (existingItems.isNotEmpty) {
        fullList.addAll(existingItems);
      } else {
        fullList.add(
          BOMDetail(
            detailId: 0,
            bomId: bomId,
            materialId: 0,
            componentType: type,
            threads: 0,
            yarnTypeName: "",
            twisted: 0,
            crossweaveRate: 0,
            actualLengthCm: 0,
            yarnDtex: 0,
            weightPerYarnGm: 0,
            actualWeightCal: 0,
            weightPercentage: 0,
            bomGm: 0,
            note: "",
          ),
        );
      }
    }
    return fullList;
  }

  Color _getComponentColor(BOMComponentType type) {
    switch (type) {
      case BOMComponentType.ground:
        return Colors.blue.shade700;
      case BOMComponentType.grdMarker:
        return Colors.blue.shade300;
      case BOMComponentType.filling:
        return Colors.orange.shade800;
      case BOMComponentType.secondFilling:
        return Colors.orange.shade400;
      case BOMComponentType.edge:
        return Colors.green.shade600;
      case BOMComponentType.binder:
        return Colors.purple.shade600;
      case BOMComponentType.stuffer:
        return Colors.grey.shade700;
      case BOMComponentType.stufferMaker:
        return Colors.blueGrey.shade400;
      case BOMComponentType.lock:
        return Colors.lightGreen.shade400;
      case BOMComponentType.catchCord:
        return Colors.teal;
    }
  }

  void _showAddEditDetailDialog(
    BuildContext context,
    BOMDetail? detail,
    BOMHeader header,
  ) async {
    final isNew = detail == null || detail.detailId == 0;
    final BOMDetail? result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) =>
          MaterialDetailDialog(detail: detail, bomId: header.bomId),
    );

    if (result == null) return;
    if (!mounted) return;
    context.read<BOMCubit>().saveBOMDetail(result, !isNew);
  }

  void _confirmDeleteDetail(BuildContext context, BOMDetail detail, int bomId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text("Remove component '${detail.yarnTypeName}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<BOMCubit>().deleteBOMDetail(detail.detailId, bomId);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("BOM Configuration"),
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, true),
        ),
      ),
      // [UPDATED] Sử dụng SingleChildScrollView làm cha để cuộn toàn trang
      body: BlocConsumer<BOMCubit, BOMState>(
        listener: (context, state) {
          if (state is BOMError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
          if (state is BOMOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is BOMLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          BOMHeader? bom;
          List<BOMMaterialSummary> summary = [];

          if (state is BOMDetailViewLoaded) {
            bom = state.bom;
            summary = state.summary;
          }

          if (bom == null) return const Center(child: Text("Loading data..."));

          final displayList = _generateFullDisplayList(
            bom.bomDetails,
            bom.bomId,
          );

          // [UPDATED] Bố cục cuộn toàn trang
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderInfo(context, bom),
                const Divider(height: 1, thickness: 1, color: Colors.grey),

                Container(
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title & Add Button
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Components (${displayList.length})",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF003366),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () =>
                                  _showAddEditDetailDialog(context, null, bom!),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text("Add Component"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE3F2FD),
                                foregroundColor: const Color(0xFF0055AA),
                                elevation: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),

                      // [UPDATED] List/Table hiển thị full chiều cao
                      isDesktop
                          ? _buildDesktopTable(displayList, bom)
                          : _buildMobileList(displayList, bom),

                      if (summary.isNotEmpty) _buildRollsSummaryTable(summary),
                    ],
                  ),
                ),

                _buildFooterSummary(bom),
                // Padding dưới cùng để tránh bị nút home che
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRollsSummaryTable(List<BOMMaterialSummary> summary) {
    return Container(
      color: Colors.grey.shade50,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "ROLLS SUMMARY",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF003366),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
              color: Colors.white,
            ),
            child: DataTable(
              headingRowHeight: 40,
              dataRowMinHeight: 40,
              dataRowMaxHeight: 40,
              headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
              columns: const [
                DataColumn(
                  label: Text(
                    "Material / Yarn Name",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Total Rolls",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  numeric: true,
                ),
              ],
              rows: summary
                  .map(
                    (s) => DataRow(
                      cells: [
                        DataCell(
                          Text(
                            s.materialName,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        DataCell(
                          Text(
                            "${s.totalRolls}",
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderInfo(BuildContext context, BOMHeader bom) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "Year ${bom.applicableYear}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            bom.displayName ?? 'Production BOM',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    BlocBuilder<ProductCubit, ProductState>(
                      builder: (context, state) {
                        String pName = "PID: ${bom.productId}";
                        if (state is ProductLoaded) {
                          final p = state.allProducts
                              .where((e) => e.id == bom.productId)
                              .firstOrNull;
                          if (p != null) pName = p.itemCode;
                        }
                        return Text(
                          "Product Code: $pName",
                          style: TextStyle(color: Colors.grey.shade600),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: Wrap(
                  spacing: 20,
                  runSpacing: 10,
                  alignment: WrapAlignment.end,
                  children: [
                    _buildStatItem(
                      "Target",
                      "${_numberFormat.format(bom.targetWeightGm)} g/m",
                    ),
                    _buildStatItem(
                      "Width",
                      bom.widthBehindLoom != null
                          ? "${bom.widthBehindLoom} mm"
                          : "-",
                    ),
                    _buildStatItem("Picks", "${bom.picks ?? '-'}"),
                    _buildStatItem(
                      "Scrap",
                      _percentFormat.format(bom.totalScrapRate),
                    ),
                    _buildStatItem(
                      "Shrinkage",
                      _percentFormat.format(bom.totalShrinkageRate),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopTable(List<BOMDetail> details, BOMHeader bom) {
    // Desktop: Cho phép cuộn ngang bảng, nhưng chiều dọc bung hết theo nội dung
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
        columnSpacing: 20,
        dataRowMinHeight: 45,
        dataRowMaxHeight: 55,
        columns: const [
          DataColumn(
            label: Text("Type", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          DataColumn(
            label: Text(
              "Material / Yarn",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              "Threads",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            numeric: true,
          ),
          DataColumn(
            label: Text("Dtex", style: TextStyle(fontWeight: FontWeight.bold)),
            numeric: true,
          ),
          DataColumn(
            label: Text("Twist", style: TextStyle(fontWeight: FontWeight.bold)),
            numeric: true,
          ),
          DataColumn(
            label: Text(
              "Crossweave",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            numeric: true,
          ),
          DataColumn(
            label: Text(
              "Actual Len",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            numeric: true,
          ),
          DataColumn(
            label: Text(
              "Actual (g/m)",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            numeric: true,
          ),
          DataColumn(
            label: Text(
              "Weight (g/m)",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            numeric: true,
          ), // Theoretical
          DataColumn(
            label: Text(
              "% Ratio",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            numeric: true,
          ),
          DataColumn(
            label: Text(
              "BOM (g/m)",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            numeric: true,
          ),
          DataColumn(
            label: Text(
              "Actions",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
        rows: details.map((d) {
          final typeColor = _getComponentColor(d.componentType);
          final isVirtual = d.detailId == 0;
          final isEmpty = d.yarnTypeName.isEmpty && d.threads == 0;

          final textStyle = TextStyle(
            fontSize: 13,
            color: isVirtual ? Colors.grey.shade400 : Colors.black87,
          );
          final numStyle = TextStyle(
            fontSize: 13,
            color: isVirtual ? Colors.grey.shade300 : Colors.black87,
          );

          return DataRow(
            color: isVirtual ? MaterialStateProperty.all(Colors.white) : null,
            cells: [
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: typeColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    d.componentType.value,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: typeColor,
                    ),
                  ),
                ),
              ),
              DataCell(
                Text(
                  isEmpty ? "-" : d.yarnTypeName,
                  style: textStyle.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
              DataCell(Text(isEmpty ? "-" : "${d.threads}", style: numStyle)),
              DataCell(
                Text(
                  isEmpty ? "-" : d.yarnDtex.toStringAsFixed(0),
                  style: numStyle,
                ),
              ),
              DataCell(
                Text(isEmpty ? "-" : d.twisted.toString(), style: numStyle),
              ),
              DataCell(
                Text(isEmpty ? "-" : "${d.crossweaveRate}%", style: numStyle),
              ),
              DataCell(
                Text(
                  isEmpty ? "-" : d.actualLengthCm.toString(),
                  style: numStyle,
                ),
              ),
              DataCell(
                Text(
                  isEmpty ? "-" : _precisionFormat.format(d.actualWeightCal),
                  style: numStyle,
                ),
              ),
              DataCell(
                Text(
                  isEmpty ? "-" : _numberFormat.format(d.weightPerYarnGm),
                  style: numStyle,
                ),
              ),
              DataCell(
                Text(
                  isEmpty ? "-" : _percentFormat.format(d.weightPercentage),
                  style: numStyle,
                ),
              ),
              DataCell(
                Text(
                  isEmpty ? "-" : _precisionFormat.format(d.bomGm),
                  style: numStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isVirtual ? Colors.grey.shade300 : Colors.blue,
                  ),
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        isVirtual ? Icons.add_circle_outline : Icons.edit,
                        size: 18,
                        color: isVirtual ? Colors.green : Colors.orange,
                      ),
                      tooltip: isVirtual ? "Add" : "Edit",
                      onPressed: () =>
                          _showAddEditDetailDialog(context, d, bom),
                    ),
                    if (!isVirtual)
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          size: 18,
                          color: Colors.red,
                        ),
                        onPressed: () =>
                            _confirmDeleteDetail(context, d, bom.bomId),
                      ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMobileList(List<BOMDetail> details, BOMHeader bom) {
    // Mobile: ListView shrinkWrap=true và physics=NeverScrollableScrollPhysics
    // để nó bung hết chiều cao và cuộn theo SingleChildScrollView của body
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      itemCount: details.length,
      separatorBuilder: (_, sep) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final d = details[index];
        final typeColor = _getComponentColor(d.componentType);
        final isVirtual = d.detailId == 0;

        return Card(
          elevation: 0,
          color: isVirtual ? Colors.grey.shade50 : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            onTap: () => _showAddEditDetailDialog(context, d, bom),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    d.componentType.value,
                    style: TextStyle(
                      fontSize: 11,
                      color: typeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (!isVirtual)
                  Expanded(
                    child: Text(
                      d.yarnTypeName,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: isVirtual
                ? const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      "(No Data - Tap to Add)",
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text(
                        "${d.threads} ends | ${d.yarnDtex.toInt()} dtex",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Act: ${d.actualWeightCal.toStringAsFixed(2)} g/m",
                          ),
                          Text(
                            "BOM: ${_numberFormat.format(d.bomGm)} g/m",
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
            trailing: isVirtual
                ? const Icon(Icons.add, color: Colors.green)
                : const Icon(Icons.chevron_right, color: Colors.grey),
          ),
        );
      },
    );
  }

  Widget _buildFooterSummary(BOMHeader bom) {
    double totalBOM = 0.0;
    double totalWeightTheo = 0.0;
    double totalActualCal = 0.0;

    for (var d in bom.bomDetails) {
      totalBOM += d.bomGm;
      totalWeightTheo += d.weightPerYarnGm;
      totalActualCal += d.actualWeightCal;
    }

    double ratio = bom.targetWeightGm > 0 ? (totalBOM / bom.targetWeightGm) : 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black12)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildSummaryItem(
                "Total Actual Cal",
                totalActualCal,
                Colors.black87,
              ),
              _buildSummaryItem(
                "Total Weight",
                totalWeightTheo,
                Colors.black87,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    "Calculated BOM:",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Text(
                    "${_numberFormat.format(totalBOM)} g/m",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003366),
                    ),
                  ),
                  if (bom.targetWeightGm > 0)
                    Text(
                      "vs Target: ${_numberFormat.format(bom.targetWeightGm)} (${_percentFormat.format(ratio)})",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: totalBOM > bom.targetWeightGm
                            ? Colors.red
                            : Colors.green,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          "${_numberFormat.format(value)} g/m",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
