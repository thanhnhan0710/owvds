import 'package:flutter/material.dart' hide MaterialState;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:intl/intl.dart';
import 'package:owvds/features/inventory/PO/po_header/domain/po_header_model.dart';
import 'package:owvds/features/inventory/PO/po_header/presentation/bloc/po_header_cubit.dart';

import '../bloc/material_receipt_cubit.dart';
import '../../domain/material_receipt_model.dart';

// Import Cubit và Model của Warehouse & PO
import '../../../warehouse/presentation/bloc/warehouse_cubit.dart';

import '../../../../inventory/material/presentation/bloc/material_cubit.dart';
import '../../../../inventory/material/domain/material_model.dart';

class MaterialReceiptFormDialog extends StatefulWidget {
  final MaterialReceipt? receipt; // null = Tạo mới, có data = Sửa/Duyệt

  const MaterialReceiptFormDialog({super.key, this.receipt});

  @override
  State<MaterialReceiptFormDialog> createState() =>
      _MaterialReceiptFormDialogState();
}

class _MaterialReceiptFormDialogState extends State<MaterialReceiptFormDialog> {
  final _formKey = GlobalKey<FormState>();

  // Controllers cho Header
  late TextEditingController _noteCtrl;
  late TextEditingController _containerCtrl;
  late TextEditingController _sealCtrl;

  int? _selectedWarehouseId;
  PurchaseOrderHeader? _selectedPo;

  List<MaterialReceiptDetail> _details = [];

  bool get isEdit => widget.receipt != null;
  bool get isCompleted => widget.receipt?.status == 'Completed';

  MaterialReceiptDetail _updateDetail(
    MaterialReceiptDetail d, {
    int? materialId,
    double? poQuantityKg,
    int? poQuantityCones,
    double? receivedQuantityKg,
    int? receivedQuantityCones,
    int? numberOfPallets,
    String? supplierBatchNo,
    String? originCountry,
    String? location,
    String? note,
  }) {
    return MaterialReceiptDetail(
      detailId: d.detailId,
      receiptId: d.receiptId,
      materialId: materialId ?? d.materialId,
      poQuantityKg: poQuantityKg ?? d.poQuantityKg,
      poQuantityCones: poQuantityCones ?? d.poQuantityCones,
      receivedQuantityKg: receivedQuantityKg ?? d.receivedQuantityKg,
      receivedQuantityCones: receivedQuantityCones ?? d.receivedQuantityCones,
      numberOfPallets: numberOfPallets ?? d.numberOfPallets,
      supplierBatchNo: supplierBatchNo ?? d.supplierBatchNo,
      originCountry: originCountry ?? d.originCountry,
      location: location ?? d.location,
      note: note ?? d.note,
    );
  }

  @override
  void initState() {
    super.initState();

    context.read<WarehouseCubit>().loadWarehouses();
    context.read<POHeaderCubit>().loadPOs();
    context.read<MaterialCubit>().loadMaterials();

    _noteCtrl = TextEditingController(text: widget.receipt?.note ?? '');
    _containerCtrl = TextEditingController(
      text: widget.receipt?.containerNo ?? '',
    );
    _sealCtrl = TextEditingController(text: widget.receipt?.sealNo ?? '');
    _selectedWarehouseId = widget.receipt?.warehouseId;

    if (isEdit) {
      _details = widget.receipt!.details.map((e) => _updateDetail(e)).toList();
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _containerCtrl.dispose();
    _sealCtrl.dispose();
    super.dispose();
  }

  void _onPoSelected(PurchaseOrderHeader? po) {
    if (po == null) return;

    if (_details.isNotEmpty && _details.first.materialId != 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Cảnh báo đổi PO"),
          content: const Text(
            "Đổi PO sẽ xóa toàn bộ danh sách vật tư bạn đang nhập bên dưới. Tiếp tục?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Hủy"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _applyNewPo(po);
              },
              child: const Text("Đồng ý"),
            ),
          ],
        ),
      );
    } else {
      _applyNewPo(po);
    }
  }

  void _applyNewPo(PurchaseOrderHeader po) {
    setState(() {
      _selectedPo = po;
      _details.clear();
      _addNewDetailLine();
    });
  }

  void _addNewDetailLine() {
    if (_selectedPo == null && !isEdit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn PO trước khi thêm vật tư!'),
        ),
      );
      return;
    }
    setState(() {
      _details.add(
        MaterialReceiptDetail(
          materialId: 0,
          receivedQuantityKg: 0,
          poQuantityKg: 0,
          poQuantityCones: 0,
          numberOfPallets: 0,
        ),
      );
    });
  }

  void _removeDetailLine(int index) {
    setState(() {
      _details.removeAt(index);
    });
  }

  void _submit(String status) {
    if (_formKey.currentState!.validate()) {
      if (_selectedWarehouseId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn Kho nhập!')),
        );
        return;
      }

      if (_selectedPo == null && !isEdit) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn chứng từ PO!')),
        );
        return;
      }

      if (_details.isEmpty ||
          _details.any((d) => d.materialId == 0 || d.receivedQuantityKg <= 0)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng chọn vật tư và nhập khối lượng > 0!'),
          ),
        );
        return;
      }

      final payload = MaterialReceipt(
        receiptId: widget.receipt?.receiptId,
        receiptNumber: widget.receipt?.receiptNumber,
        receiptDate:
            widget.receipt?.receiptDate ??
            DateFormat('yyyy-MM-dd').format(DateTime.now()),
        poHeaderId: _selectedPo?.poId ?? widget.receipt?.poHeaderId,
        warehouseId: _selectedWarehouseId!,
        containerNo: _containerCtrl.text.trim(),
        sealNo: _sealCtrl.text.trim(),
        note: _noteCtrl.text.trim(),
        status: status,
        details: _details,
      );

      context.read<MaterialReceiptCubit>().saveReceipt(payload, isEdit);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 900;

    return Dialog(
      insetPadding: isMobile
          ? const EdgeInsets.all(16)
          : const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: isMobile ? double.infinity : 1200,
        height: 800,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // HEADER BANNER
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              color: const Color(0xFF003366),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      isEdit
                          ? "Sửa/Duyệt Phiếu Nhập: ${widget.receipt!.receiptNumber}"
                          : "Tạo Phiếu Nhập Kho Mới",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isCompleted)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        "ĐÃ DUYỆT",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // FORM NỘI DUNG
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  children: [
                    const Text(
                      "1. Chứng từ & Logistics",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blueGrey,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (isMobile) ...[
                      _buildPoDropdown(),
                      const SizedBox(height: 16),
                      _buildWarehouseDropdown(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _containerCtrl,
                              enabled: !isCompleted,
                              decoration: const InputDecoration(
                                labelText: "Số Container",
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _sealCtrl,
                              enabled: !isCompleted,
                              decoration: const InputDecoration(
                                labelText: "Số Seal (Chì)",
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(child: _buildPoDropdown()),
                          const SizedBox(width: 16),
                          Expanded(child: _buildWarehouseDropdown()),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _containerCtrl,
                              enabled: !isCompleted,
                              decoration: const InputDecoration(
                                labelText: "Số Container",
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _sealCtrl,
                              enabled: !isCompleted,
                              decoration: const InputDecoration(
                                labelText: "Số Seal (Chì)",
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _noteCtrl,
                      enabled: !isCompleted,
                      decoration: const InputDecoration(
                        labelText: "Ghi chú phiếu nhập",
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const Divider(height: 48),

                    // DANH SÁCH CHI TIẾT
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            "2. Kiểm đếm Hàng hóa",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.blueGrey,
                            ),
                          ),
                        ),
                        if (!isCompleted)
                          ElevatedButton.icon(
                            onPressed: _addNewDetailLine,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text("Thêm Dòng Mới"),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (!isMobile)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                "Chọn Nguyên Vật Liệu",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                "Đã Đặt (PO)",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.blueGrey,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                "Thực Nhận (Kg / Cuộn)",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                "Logistics (Pallet / Vị trí / Lô NCC)",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            SizedBox(width: 40),
                          ],
                        ),
                      ),
                    if (!isMobile) const SizedBox(height: 8),

                    if (_selectedPo == null && !isEdit)
                      const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(
                          child: Text(
                            "Vui lòng chọn PO ở bước 1 để hiển thị danh sách vật tư.",
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),

                    // Render các dòng nhập
                    ..._details.asMap().entries.map((entry) {
                      int idx = entry.key;
                      MaterialReceiptDetail d = entry.value;

                      return Card(
                        elevation: isMobile ? 2 : 0,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: _buildDetailRow(d, idx, isMobile),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // FOOTER & ACTION BUTTONS
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 16,
                children: [
                  Text(
                    isCompleted
                        ? "Phiếu đã chốt sổ tồn kho."
                        : "Vui lòng kiểm đếm kỹ thực tế so với số lượng PO.",
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: isCompleted
                          ? Colors.green
                          : Colors.orange.shade800,
                    ),
                  ),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Đóng"),
                      ),
                      if (!isCompleted) ...[
                        OutlinedButton(
                          onPressed: () => _submit('Draft'),
                          child: const Text("Lưu Bản Nháp"),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showConfirmCompleteDialog(),
                          icon: const Icon(Icons.check_circle),
                          label: const Text("DUYỆT & TẠO LÔ"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===============================================
  // CÁC COMPONENT GIAO DIỆN TÁCH RỜI
  // ===============================================

  Widget _buildPoDropdown() {
    return BlocBuilder<POHeaderCubit, POHeaderState>(
      builder: (context, state) {
        List<PurchaseOrderHeader> poList = [];
        if (state is POHeaderLoaded) poList = state.pos;

        PurchaseOrderHeader? currentPoValue = _selectedPo;
        if (currentPoValue == null &&
            isEdit &&
            widget.receipt!.poHeaderId != null) {
          currentPoValue = poList
              .where((p) => p.poId == widget.receipt!.poHeaderId)
              .firstOrNull;
          if (currentPoValue != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _selectedPo = currentPoValue);
            });
          }
        }

        return DropdownButtonFormField<PurchaseOrderHeader>(
          value: currentPoValue,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: "Đơn mua hàng (PO) *",
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: poList
              .map(
                (po) => DropdownMenuItem(value: po, child: Text(po.poNumber)),
              )
              .toList(),
          onChanged: (isEdit || isCompleted) ? null : _onPoSelected,
          validator: (v) => v == null ? "Bắt buộc chọn" : null,
        );
      },
    );
  }

  Widget _buildWarehouseDropdown() {
    return BlocBuilder<WarehouseCubit, WarehouseState>(
      builder: (context, state) {
        if (state is WarehouseLoaded) {
          return DropdownButtonFormField<int>(
            value: _selectedWarehouseId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: "Kho Nhập (*)",
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: state.warehouses
                .map(
                  (w) => DropdownMenuItem(
                    value: w.warehouseId,
                    child: Text(w.name),
                  ),
                )
                .toList(),
            onChanged: isCompleted
                ? null
                : (val) => setState(() => _selectedWarehouseId = val),
            validator: (v) => v == null ? "Bắt buộc chọn" : null,
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildMaterialSearchDropdown(MaterialReceiptDetail d, int idx) {
    return BlocBuilder<MaterialCubit, MaterialState>(
      builder: (context, matState) {
        List<MaterialItem> allMats = (matState is MaterialLoaded)
            ? matState.materials
            : [];

        List<MaterialItem> itemsInPo = [];
        if (_selectedPo != null) {
          for (var poDetail in _selectedPo!.details) {
            final fullMat = allMats
                .where((m) => m.materialId == poDetail.materialId)
                .firstOrNull;
            if (fullMat != null) {
              itemsInPo.add(fullMat);
            }
          }
        }

        return DropdownSearch<MaterialItem>(
          popupProps: PopupProps.menu(
            showSearchBox: true,
            searchFieldProps: TextFieldProps(
              decoration: InputDecoration(
                hintText: "Tìm mã/tên...",
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          items: (String filter, dynamic props) {
            if (filter.isEmpty) return itemsInPo;
            return itemsInPo
                .where(
                  (m) =>
                      m.materialCode.toLowerCase().contains(
                        filter.toLowerCase(),
                      ) ||
                      m.materialName.toLowerCase().contains(
                        filter.toLowerCase(),
                      ),
                )
                .toList();
          },
          itemAsString: (MaterialItem m) =>
              "[${m.materialCode}] ${m.materialName}",
          compareFn: (MaterialItem item1, MaterialItem item2) =>
              item1.materialId == item2.materialId,
          selectedItem: itemsInPo
              .where((m) => m.materialId == d.materialId)
              .firstOrNull,
          onChanged: isCompleted
              ? null
              : (MaterialItem? val) {
                  if (val == null) return;
                  var matchedPoDetail = _selectedPo!.details.firstWhere(
                    (x) => x.materialId == val.materialId,
                  );
                  setState(() {
                    // [ĐÃ SỬA]: Dùng _details[idx] thay vì d
                    _details[idx] = _updateDetail(
                      _details[idx],
                      materialId: val.materialId,
                      poQuantityKg: matchedPoDetail.quantityKg,
                      poQuantityCones: matchedPoDetail.quantityRolls,
                    );
                  });
                },
          decoratorProps: DropDownDecoratorProps(
            decoration: InputDecoration(
              hintText: "Chọn vật tư...",
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              fillColor: _selectedPo != null
                  ? Colors.grey.shade100
                  : Colors.white,
              filled: true,
            ),
          ),
          validator: (v) => v == null ? "Lỗi" : null,
        );
      },
    );
  }

  Widget _buildDetailRow(MaterialReceiptDetail d, int idx, bool isMobile) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildMaterialSearchDropdown(d, idx)),
              if (!isCompleted && _details.length > 1) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeDetailLine(idx),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "SL Đặt (PO):",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blueGrey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${d.poQuantityKg} Kg - ${d.poQuantityCones} cuộn",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: d.receivedQuantityKg == 0
                      ? ''
                      : d.receivedQuantityKg.toString(),
                  enabled: !isCompleted,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: "Thực nhận (Kg)",
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  // [ĐÃ SỬA]: Dùng _details[idx] và replaceAll để fix lỗi Parse
                  onChanged: (v) => _details[idx] = _updateDetail(
                    _details[idx],
                    receivedQuantityKg:
                        double.tryParse(v.replaceAll(',', '')) ?? 0.0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: d.receivedQuantityCones == 0
                      ? ''
                      : d.receivedQuantityCones.toString(),
                  enabled: !isCompleted,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Số Cuộn",
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  // [ĐÃ SỬA]
                  onChanged: (v) => _details[idx] = _updateDetail(
                    _details[idx],
                    receivedQuantityCones:
                        int.tryParse(v.replaceAll(',', '')) ?? 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: TextFormField(
                  initialValue: d.numberOfPallets == 0
                      ? ''
                      : d.numberOfPallets.toString(),
                  enabled: !isCompleted,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Pallet",
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  // [ĐÃ SỬA]
                  onChanged: (v) => _details[idx] = _updateDetail(
                    _details[idx],
                    numberOfPallets: int.tryParse(v.replaceAll(',', '')) ?? 0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: d.location,
                  enabled: !isCompleted,
                  decoration: const InputDecoration(
                    labelText: "Vị trí cất (Kệ/Bin)",
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  // [ĐÃ SỬA]
                  onChanged: (v) =>
                      _details[idx] = _updateDetail(_details[idx], location: v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: d.supplierBatchNo,
            enabled: !isCompleted,
            decoration: const InputDecoration(
              labelText: "Mã Lô NCC (Tùy chọn)",
              isDense: true,
              border: OutlineInputBorder(),
            ),
            // [ĐÃ SỬA]
            onChanged: (v) => _details[idx] = _updateDetail(
              _details[idx],
              supplierBatchNo: v,
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: _buildMaterialSearchDropdown(d, idx)),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade50,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Khối lượng: ${d.poQuantityKg} Kg",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  "Số cuộn: ${d.poQuantityCones}",
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: d.receivedQuantityKg == 0
                      ? ''
                      : d.receivedQuantityKg.toString(),
                  enabled: !isCompleted,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: "Kg Nhận",
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  // [ĐÃ SỬA]
                  onChanged: (v) => _details[idx] = _updateDetail(
                    _details[idx],
                    receivedQuantityKg:
                        double.tryParse(v.replaceAll(',', '')) ?? 0.0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: d.receivedQuantityCones == 0
                      ? ''
                      : d.receivedQuantityCones.toString(),
                  enabled: !isCompleted,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Cuộn Nhận",
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  // [ĐÃ SỬA]
                  onChanged: (v) => _details[idx] = _updateDetail(
                    _details[idx],
                    receivedQuantityCones:
                        int.tryParse(v.replaceAll(',', '')) ?? 0,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      initialValue: d.numberOfPallets == 0
                          ? ''
                          : d.numberOfPallets.toString(),
                      enabled: !isCompleted,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Số Pallet",
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      // [ĐÃ SỬA]
                      onChanged: (v) => _details[idx] = _updateDetail(
                        _details[idx],
                        numberOfPallets:
                            int.tryParse(v.replaceAll(',', '')) ?? 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      initialValue: d.location,
                      enabled: !isCompleted,
                      decoration: const InputDecoration(
                        labelText: "Vị trí kho (Bin)",
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      // [ĐÃ SỬA]
                      onChanged: (v) => _details[idx] = _updateDetail(
                        _details[idx],
                        location: v,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: d.supplierBatchNo,
                enabled: !isCompleted,
                decoration: const InputDecoration(
                  labelText: "Mã Lô NCC (Tùy chọn)",
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                // [ĐÃ SỬA]
                onChanged: (v) => _details[idx] = _updateDetail(
                  _details[idx],
                  supplierBatchNo: v,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 40,
          child: (!isCompleted && _details.length > 1)
              ? IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeDetailLine(idx),
                )
              : const SizedBox(),
        ),
      ],
    );
  }

  void _showConfirmCompleteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Chốt Số Liệu Nhập Kho"),
        content: const Text(
          "Sau khi DUYỆT:\n1. Tồn kho NVL sẽ tăng lên tương ứng.\n2. Số lượng đã nhận trong PO sẽ được cập nhật.\n3. Phiếu sẽ KHÔNG THỂ thay đổi.\n\nBạn chắc chắn chứ?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Kiểm tra lại"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _submit('Completed');
            },
            child: const Text("Đồng ý Duyệt"),
          ),
        ],
      ),
    );
  }
}
