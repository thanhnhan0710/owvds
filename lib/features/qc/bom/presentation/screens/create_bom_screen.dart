import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:intl/intl.dart';
import 'package:owvds/core/widgets/responsive_layout.dart';
import 'package:owvds/features/production/loom_state/product/domain/product_model.dart';
import 'package:owvds/features/production/loom_state/product/presentation/bloc/product_cubit.dart';
import 'package:owvds/features/inventory/material/domain/material_model.dart';
import 'package:owvds/features/inventory/material/presentation/bloc/material_cubit.dart'
    as mat_bloc;

// Models & Cubits
import '../../domain/bom_model.dart';
import '../bloc/bom_cubit.dart';

// L10n
import '../../../../../l10n/app_localizations.dart';

class CreateBOMScreen extends StatefulWidget {
  final BOMHeader? existingBOM;

  const CreateBOMScreen({super.key, this.existingBOM});

  @override
  State<CreateBOMScreen> createState() => _CreateBOMScreenState();
}

class _CreateBOMScreenState extends State<CreateBOMScreen> {
  final _formKey = GlobalKey<FormState>();

  // Formatters
  final _numberFormat = NumberFormat("#,##0.000");
  final _percentFormat = NumberFormat("#,##0.0'%'");
  final _precisionFormat = NumberFormat(
    "#,##0.#####",
  ); // Hiển thị tối đa 5 số thập phân

  // --- Header Controllers ---
  final _yearCtrl = TextEditingController(text: DateTime.now().year.toString());
  final _targetWeightCtrl = TextEditingController(text: "0.0");
  final _widthCtrl = TextEditingController();
  final _picksCtrl = TextEditingController();
  final _scrapRateCtrl = TextEditingController(text: "0.0");
  final _shrinkageRateCtrl = TextEditingController(text: "0.0");
  final _versionCtrl = TextEditingController(text: "1");

  int? _selectedProductId;
  bool _isActive = true;

  // --- Details List (Local State) ---
  List<BOMDetail> _tempDetails = [];

  @override
  void initState() {
    super.initState();
    context.read<ProductCubit>().loadProducts();
    context.read<mat_bloc.MaterialCubit>().loadMaterials();

    if (widget.existingBOM != null) {
      _initEditData(widget.existingBOM!);
    }
  }

  void _initEditData(BOMHeader bom) {
    _selectedProductId = bom.productId;
    _yearCtrl.text = bom.applicableYear.toString();
    _targetWeightCtrl.text = bom.targetWeightGm.toString();
    _widthCtrl.text = bom.widthBehindLoom?.toString() ?? "";
    _picksCtrl.text = bom.picks?.toString() ?? "";
    _scrapRateCtrl.text = bom.totalScrapRate.toString();
    _shrinkageRateCtrl.text = bom.totalShrinkageRate.toString();
    _versionCtrl.text = bom.version.toString();
    _isActive = bom.isActive;

    _tempDetails = List.from(bom.bomDetails);
    _recalculateDetails();
  }

  // --- LOGIC TÍNH TOÁN (TOP-DOWN) ---
  void _recalculateDetails() {
    double scrapRate = double.tryParse(_scrapRateCtrl.text) ?? 0.0;
    double shrinkageRate = double.tryParse(_shrinkageRateCtrl.text) ?? 0.0;
    double targetWeight = double.tryParse(_targetWeightCtrl.text) ?? 0.0;

    // Vòng 1: Tính Actual Weight và Theoretical Weight cho từng item, đồng thời tính Tổng Actual
    List<BOMDetail> tempCalcList = [];
    double totalActual = 0.0;

    for (var item in _tempDetails) {
      // 1. Tính Actual Weight (g/m)
      // Formula: (Actual Len / 100) * (Dtex / 11000) * Threads
      double actual =
          (item.actualLengthCm / 100) * (item.yarnDtex / 11000) * item.threads;

      // Chia 2 nếu là Filling
      if (item.componentType == BOMComponentType.filling ||
          item.componentType == BOMComponentType.secondFilling) {
        actual = actual / 2;
      }

      // 2. Tính Theoretical Weight (g/m) - Để hiển thị tham khảo
      // Formula: ((threads * dtex * twisted * (1 + crossweave/100)) / 10000) * (1 + scrap) * (1 + shrinkage)
      double theoretical =
          ((item.threads *
                  item.yarnDtex *
                  item.twisted *
                  (1 + (item.crossweaveRate / 100))) /
              10000) *
          (1 + (scrapRate / 100)) *
          (1 + (shrinkageRate / 100));

      totalActual += actual;

      // Tạo object tạm với giá trị actual/theo mới tính
      tempCalcList.add(
        BOMDetail(
          detailId: item.detailId,
          bomId: item.bomId,
          materialId: item.materialId,
          componentType: item.componentType,
          threads: item.threads,
          yarnDtex: item.yarnDtex,
          yarnTypeName: item.yarnTypeName,
          twisted: item.twisted,
          crossweaveRate: item.crossweaveRate,
          actualLengthCm: item.actualLengthCm,
          actualWeightCal: actual,
          weightPerYarnGm: theoretical, // Lưu giá trị lý thuyết
          weightPercentage: 0, // Tính ở vòng 2
          bomGm: 0, // Tính ở vòng 2
          note: item.note,
        ),
      );
    }

    // Vòng 2: Tính % Tỷ trọng và BOM g/m dựa trên Target Weight
    List<BOMDetail> finalList = [];
    for (var item in tempCalcList) {
      // Tính % (Actual / Total Actual)
      double percentage = totalActual > 0
          ? (item.actualWeightCal / totalActual) * 100
          : 0.0;

      // Tính BOM g/m (Công thức mới theo yêu cầu)
      // bom_gm = percentage / 100 * target * (1 + scrap/100)
      double bomGm = (percentage / 100) * targetWeight * (1 + scrapRate / 100);

      finalList.add(
        BOMDetail(
          detailId: item.detailId,
          bomId: item.bomId,
          materialId: item.materialId,
          componentType: item.componentType,
          threads: item.threads,
          yarnDtex: item.yarnDtex,
          yarnTypeName: item.yarnTypeName,
          twisted: item.twisted,
          crossweaveRate: item.crossweaveRate,
          actualLengthCm: item.actualLengthCm,
          actualWeightCal: item.actualWeightCal,
          weightPerYarnGm: item.weightPerYarnGm,
          weightPercentage: percentage, // Cập nhật %
          bomGm: bomGm, // Cập nhật BOM g/m
          note: item.note,
        ),
      );
    }

    setState(() {
      _tempDetails = finalList;
    });
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(widget.existingBOM == null ? l10n.newBOM : l10n.editBOM),
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: () => _submitBOM(context, l10n),
            icon: const Icon(Icons.save, color: Colors.white),
            label: Text(
              l10n.save,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // 1. HEADER INFO
            _buildHeaderForm(l10n),

            const Divider(height: 1, thickness: 1, color: Colors.grey),

            // 2. DETAILS LIST
            Expanded(
              child: SelectionArea(
                child: Container(
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Components (${_tempDetails.length})",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF003366),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () =>
                                  _showAddComponentDialog(context, null, l10n),
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
                      Expanded(
                        child: _tempDetails.isEmpty
                            ? Center(
                                child: Text(
                                  l10n.noItemsPO,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              )
                            : (isDesktop
                                  ? _buildDesktopTable(l10n)
                                  : _buildMobileList(l10n)),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 3. FOOTER SUMMARY
            _buildFooterSummary(),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildHeaderForm(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(0),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: BlocBuilder<ProductCubit, ProductState>(
                  builder: (context, state) {
                    List<Product> products = [];
                    if (state is ProductLoaded)
                      products = state.displayedProducts;

                    return DropdownSearch<Product>(
                      items: (filter, props) {
                        if (filter.isEmpty) return products;
                        return products
                            .where(
                              (p) => p.itemCode.toLowerCase().contains(
                                filter.toLowerCase(),
                              ),
                            )
                            .toList();
                      },
                      itemAsString: (Product p) => p.itemCode,
                      selectedItem:
                          products.any((p) => p.id == _selectedProductId)
                          ? products.firstWhere(
                              (p) => p.id == _selectedProductId,
                            )
                          : null,
                      compareFn: (i, s) => i.id == s.id,
                      decoratorProps: DropDownDecoratorProps(
                        decoration: _inputDeco(
                          l10n.product,
                          icon: Icons.inventory_2,
                        ),
                      ),
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        itemBuilder: (ctx, item, isDisabled, isSelected) =>
                            ListTile(
                              title: Text(
                                item.itemCode,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              selected: isSelected,
                            ),
                      ),
                      onChanged: (p) =>
                          setState(() => _selectedProductId = p?.id),
                      validator: (p) => p == null ? l10n.required : null,
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _yearCtrl,
                  decoration: _inputDeco(
                    "Applicable Year",
                    icon: Icons.calendar_today,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? l10n.required : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _targetWeightCtrl,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.number,
                  decoration: _inputDeco("Target (g/m)", icon: Icons.scale),
                  // Khi nhập Target -> Tính lại BOM
                  onChanged: (val) => _recalculateDetails(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _widthCtrl,
                  decoration: _inputDeco("Width (mm)"),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _picksCtrl,
                  decoration: _inputDeco("Picks"),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _scrapRateCtrl,
                  decoration: _inputDeco("Scrap Rate (%)"),
                  keyboardType: TextInputType.number,
                  // Khi đổi Scrap Rate -> Tính lại
                  onChanged: (_) => _recalculateDetails(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _shrinkageRateCtrl,
                  decoration: _inputDeco("Shrinkage Rate (%)"),
                  keyboardType: TextInputType.number,
                  // Khi đổi Shrinkage -> Tính lại
                  onChanged: (_) => _recalculateDetails(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(AppLocalizations l10n) {
    final sortedDetails = List<BOMDetail>.from(_tempDetails)
      ..sort((a, b) => a.componentType.index.compareTo(b.componentType.index));

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
                columnSpacing: 24,
                dataRowMinHeight: 50,
                dataRowMaxHeight: 60,
                columns: const [
                  DataColumn(
                    label: Text(
                      "Type",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
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
                    label: Text(
                      "Dtex",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text(
                      "Twist",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    numeric: true,
                  ),
                  // [MỚI] Crossweave
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
                  // [MỚI] Weight (Theo) & % Ratio
                  DataColumn(
                    label: Text(
                      "Weight (g/m)",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    numeric: true,
                  ),
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
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
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
                rows: sortedDetails.map((d) {
                  final typeColor = _getComponentColor(d.componentType);
                  final realIndex = _tempDetails.indexOf(d);

                  return DataRow(
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
                            border: Border.all(
                              color: typeColor.withOpacity(0.3),
                            ),
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
                          d.yarnTypeName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      DataCell(Text("${d.threads}")),
                      DataCell(Text(d.yarnDtex.toStringAsFixed(0))),
                      DataCell(Text(d.twisted.toString())),
                      // [MỚI]
                      DataCell(Text("${d.crossweaveRate}%")),
                      DataCell(Text(d.actualLengthCm.toString())),
                      // [YÊU CẦU] Max 5 số thập phân
                      DataCell(
                        Text(_precisionFormat.format(d.actualWeightCal)),
                      ),
                      // [MỚI]
                      DataCell(Text(_numberFormat.format(d.weightPerYarnGm))),
                      DataCell(Text(_percentFormat.format(d.weightPercentage))),

                      // [THAY ĐỔI] Hiển thị BOM full decimal
                      DataCell(
                        Text(
                          _precisionFormat.format(d.bomGm),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                size: 18,
                                color: Colors.orange,
                              ),
                              onPressed: () => _showAddComponentDialog(
                                context,
                                realIndex,
                                l10n,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                size: 18,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                setState(() {
                                  _tempDetails.removeAt(realIndex);
                                  _recalculateDetails();
                                });
                              },
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
      },
    );
  }

  Widget _buildMobileList(AppLocalizations l10n) {
    final sortedDetails = List<BOMDetail>.from(_tempDetails)
      ..sort((a, b) => a.componentType.index.compareTo(b.componentType.index));

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: sortedDetails.length,
      separatorBuilder: (_, sep) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final d = sortedDetails[index];
        final typeColor = _getComponentColor(d.componentType);
        final realIndex = _tempDetails.indexOf(d);

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    d.yarnTypeName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
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
                      fontSize: 10,
                      color: typeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text(
                  "${d.threads} ends | ${d.yarnDtex.toInt()} dtex | CW: ${d.crossweaveRate}%",
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Act: ${_precisionFormat.format(d.actualWeightCal)} g/m",
                    ),
                    Expanded(
                      child: Text(
                        "BOM: ${d.bomGm} g/m",
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton(
              onSelected: (val) {
                if (val == 'edit') {
                  _showAddComponentDialog(context, realIndex, l10n);
                }
                if (val == 'delete') {
                  setState(() {
                    _tempDetails.removeAt(realIndex);
                    _recalculateDetails();
                  });
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 'edit', child: Text("Edit")),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text("Delete", style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooterSummary() {
    double totalBOM = _tempDetails.fold(0.0, (sum, item) => sum + item.bomGm);
    double totalActual = _tempDetails.fold(
      0.0,
      (sum, item) => sum + item.actualWeightCal,
    );
    // [YÊU CẦU] Thêm tổng trọng lượng lý thuyết
    double totalWeight = _tempDetails.fold(
      0.0,
      (sum, item) => sum + item.weightPerYarnGm,
    );

    double target = double.tryParse(_targetWeightCtrl.text) ?? 0.0;
    double ratio = target > 0 ? (totalBOM / target) : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Total Actual:",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                "${_numberFormat.format(totalActual)} g/m",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          // [MỚI] Hiển thị Total Weight
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Total Weight:",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                "${_numberFormat.format(totalWeight)} g/m",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                "Calculated BOM (Sum):",
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
              if (target > 0)
                Text(
                  "vs Target: ${_numberFormat.format(target)} (${_percentFormat.format(ratio)})",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: totalBOM > target ? Colors.red : Colors.green,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddComponentDialog(
    BuildContext context,
    int? index,
    AppLocalizations l10n,
  ) {
    final isEdit = index != null;
    final existingItem = isEdit ? _tempDetails[index] : null;

    int? selectedMatId = existingItem?.materialId;
    BOMComponentType selectedType =
        existingItem?.componentType ?? BOMComponentType.ground;
    double currentDtex = existingItem?.yarnDtex ?? 0.0;

    final yarnNameCtrl = TextEditingController(
      text: existingItem?.yarnTypeName ?? '',
    );
    final threadsCtrl = TextEditingController(
      text: existingItem?.threads.toString() ?? '0',
    );
    final twistCtrl = TextEditingController(
      text: existingItem?.twisted.toString() ?? '1.0',
    );
    final lenCtrl = TextEditingController(
      text: existingItem?.actualLengthCm.toString() ?? '0.0',
    );
    final crossCtrl = TextEditingController(
      text: existingItem?.crossweaveRate.toString() ?? '0.0',
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(isEdit ? "Edit Component" : "Add Component"),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<BOMComponentType>(
                        value: selectedType,
                        decoration: _inputDeco("Type"),
                        items: BOMComponentType.values
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(
                                  e.value.toUpperCase(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setStateDialog(() => selectedType = v!),
                      ),
                      const SizedBox(height: 12),
                      BlocBuilder<
                        mat_bloc.MaterialCubit,
                        mat_bloc.MaterialState
                      >(
                        builder: (context, state) {
                          List<MaterialItem> materials = [];
                          if (state is mat_bloc.MaterialLoaded) {
                            materials = state.materials;
                          }
                          return DropdownSearch<MaterialItem>(
                            items: (filter, props) {
                              if (filter.isEmpty) return materials;
                              return materials
                                  .where(
                                    (m) => m.materialCode
                                        .toLowerCase()
                                        .contains(filter.toLowerCase()),
                                  )
                                  .toList();
                            },
                            itemAsString: (m) => m.materialCode,
                            selectedItem: materials
                                .where((m) => m.materialId == selectedMatId)
                                .firstOrNull,
                            compareFn: (i, s) => i.materialId == s.materialId,
                            decoratorProps: DropDownDecoratorProps(
                              decoration: _inputDeco(
                                "Material",
                                icon: Icons.search,
                              ),
                            ),
                            popupProps: PopupProps.menu(
                              showSearchBox: true,
                              itemBuilder:
                                  (ctx, item, isDisabled, isSelected) =>
                                      ListTile(
                                        title: Text(item.materialName),
                                        subtitle: Text('${item.dtex}'),
                                        selected: isSelected,
                                      ),
                            ),
                            onChanged: (m) {
                              if (m != null) {
                                setStateDialog(() {
                                  selectedMatId = m.materialId;
                                  yarnNameCtrl.text =
                                      "${m.materialName} ${m.dtex ?? ''}";
                                  if (m.dtex != null) {
                                    currentDtex =
                                        double.tryParse(m.dtex.toString()) ??
                                        0.0;
                                  } else {
                                    currentDtex = 0.0;
                                  }
                                });
                              }
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: yarnNameCtrl,
                        decoration: _inputDeco("Yarn Name / Code"),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: threadsCtrl,
                              decoration: _inputDeco("Threads"),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: twistCtrl,
                              decoration: _inputDeco("Twist"),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: lenCtrl,
                              decoration: _inputDeco("Actual (cm)"),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: crossCtrl,
                              decoration: _inputDeco("Crossweave (%)"),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "Current Dtex: ${currentDtex.toStringAsFixed(0)}",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (yarnNameCtrl.text.isNotEmpty) {
                      final newItem = BOMDetail(
                        detailId: existingItem?.detailId ?? 0,
                        bomId: widget.existingBOM?.bomId ?? 0,
                        materialId: selectedMatId ?? 1,
                        componentType: selectedType,
                        threads: int.tryParse(threadsCtrl.text) ?? 0,
                        yarnTypeName: yarnNameCtrl.text,
                        twisted: double.tryParse(twistCtrl.text) ?? 1.0,
                        actualLengthCm: double.tryParse(lenCtrl.text) ?? 0.0,
                        crossweaveRate: double.tryParse(crossCtrl.text) ?? 0.0,
                        yarnDtex: currentDtex,
                        weightPerYarnGm: existingItem?.weightPerYarnGm ?? 0,
                        actualWeightCal: 0,
                        weightPercentage: 0,
                        bomGm: 0,
                        note: "",
                      );

                      setState(() {
                        if (isEdit) {
                          _tempDetails[index] = newItem;
                        } else {
                          _tempDetails.add(newItem);
                        }
                        _recalculateDetails();
                      });
                      Navigator.pop(ctx);
                    }
                  },
                  child: Text(isEdit ? l10n.save : l10n.addBOM),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _submitBOM(BuildContext context, AppLocalizations l10n) {
    if (_formKey.currentState!.validate() && _selectedProductId != null) {
      final newBOM = BOMHeader(
        bomId: widget.existingBOM?.bomId ?? 0,
        productId: _selectedProductId!,
        applicableYear: int.tryParse(_yearCtrl.text) ?? DateTime.now().year,
        // Target Weight được lấy từ Input người dùng
        targetWeightGm: double.tryParse(_targetWeightCtrl.text) ?? 0.0,
        widthBehindLoom: double.tryParse(_widthCtrl.text),
        picks: int.tryParse(_picksCtrl.text),
        totalScrapRate: double.tryParse(_scrapRateCtrl.text) ?? 0.0,
        totalShrinkageRate: double.tryParse(_shrinkageRateCtrl.text) ?? 0.0,
        version: int.tryParse(_versionCtrl.text) ?? 1,
        isActive: _isActive,
        bomDetails: _tempDetails,
      );

      context.read<BOMCubit>().saveBOMHeader(
        bom: newBOM,
        isEdit: widget.existingBOM != null,
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.productRequired),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  InputDecoration _inputDeco(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null
          ? Icon(icon, size: 18, color: Colors.grey)
          : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      isDense: true,
    );
  }
}
