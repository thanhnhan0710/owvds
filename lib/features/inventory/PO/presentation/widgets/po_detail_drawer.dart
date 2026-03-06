import 'package:flutter/material.dart' hide MaterialState;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:intl/intl.dart';

import 'package:owvds/features/inventory/PO/incoterm/domain/incoterm_model.dart';
import 'package:owvds/features/inventory/PO/incoterm/presentation/bloc/incoterm_cubit.dart';
import 'package:owvds/features/inventory/PO/po_header/domain/po_header_model.dart';
import 'package:owvds/features/inventory/PO/po_header/presentation/bloc/po_header_cubit.dart';
import 'package:owvds/features/inventory/PO/po_status/domain/po_status_model.dart';
import 'package:owvds/features/inventory/PO/po_status/presentation/bloc/po_status_cubit.dart';
import 'package:owvds/features/inventory/PO/po_detail/domain/po_detail_model.dart';

import '../../../../inventory/supplier/presentation/bloc/supplier_cubit.dart';
import '../../../../inventory/supplier/domain/supplier_model.dart';
import '../../../../inventory/material/presentation/bloc/material_cubit.dart';
import '../../../../inventory/material/domain/material_model.dart';

class LocalPODetail {
  int? materialId;
  String currency;
  double qtyKg;
  double price;
  int backendRolls;

  LocalPODetail({
    this.materialId,
    this.currency = "VND",
    this.qtyKg = 0,
    this.price = 0,
    this.backendRolls = 0,
  });

  double get lineTotal => qtyKg * price;
}

class PODetailDrawer extends StatefulWidget {
  final PurchaseOrderHeader? po;
  const PODetailDrawer({super.key, this.po});

  @override
  State<PODetailDrawer> createState() => _PODetailDrawerState();
}

class _PODetailDrawerState extends State<PODetailDrawer> {
  final Color _primary = const Color(0xFF003366);
  final _formKey = GlobalKey<FormState>();

  final _poNumCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _etaCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  int? _selectedSupplierId;
  int? _selectedIncotermId;
  int? _selectedStatusId;

  final List<LocalPODetail> _details = [];

  // ─── Breakpoint: <= 600 là mobile ───────────────────────────────────────────
  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width <= 600;

  @override
  void initState() {
    super.initState();
    if (widget.po != null) {
      _poNumCtrl.text = widget.po!.poNumber;
      _dateCtrl.text = widget.po!.orderDate ?? '';
      _etaCtrl.text = widget.po!.expectedArrivalDate ?? '';
      _noteCtrl.text = widget.po!.note ?? '';

      _selectedSupplierId = widget.po!.vendorId;
      _selectedIncotermId = widget.po!.incotermId;
      _selectedStatusId = widget.po!.statusId;

      for (var d in widget.po!.details) {
        _details.add(
          LocalPODetail(
            materialId: d.materialId,
            currency: d.currency,
            qtyKg: d.quantityKg,
            price: d.unitPrice,
            backendRolls: d.quantityRolls,
          ),
        );
      }
      context.read<MaterialCubit>().loadMaterials(
        supplierId: _selectedSupplierId,
      );
    } else {
      _poNumCtrl.text = "Đang tải số PO...";
      context.read<POHeaderCubit>().getNextPONumber().then((nextNumber) {
        if (mounted)
          setState(() => _poNumCtrl.text = nextNumber.replaceAll('"', ''));
      });

      _dateCtrl.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
      context.read<MaterialCubit>().loadMaterials(supplierId: -1);
    }
  }

  void _onSupplierChanged(int? supplierId) {
    if (supplierId == null) return;
    if (_selectedSupplierId != supplierId) {
      setState(() {
        _selectedSupplierId = supplierId;
        if (_details.isNotEmpty) {
          _details.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Đã đổi Nhà cung cấp. Danh sách vật tư đã được làm mới!",
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      });
      context.read<MaterialCubit>().loadMaterials(supplierId: supplierId);
    }
  }

  void _savePO() {
    if (_formKey.currentState!.validate()) {
      if (_selectedSupplierId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Bắt buộc chọn Nhà cung cấp")),
        );
        return;
      }

      final matState = context.read<MaterialCubit>().state;
      List<MaterialItem> allMats = (matState is MaterialLoaded)
          ? matState.materials
          : [];

      List<PurchaseOrderDetail> poDetails = _details
          .where((d) => d.materialId != null)
          .map((d) {
            int finalRolls = d.backendRolls;
            final mat = allMats
                .where((m) => m.materialId == d.materialId)
                .firstOrNull;
            if (mat != null &&
                mat.kgPerBobbin != null &&
                mat.kgPerBobbin! > 0) {
              finalRolls = (d.qtyKg / mat.kgPerBobbin!).ceil();
            }
            return PurchaseOrderDetail(
              materialId: d.materialId!,
              currency: d.currency,
              exchangeRate: d.currency == 'VND' ? 1.0 : 25000.0,
              quantityKg: d.qtyKg,
              quantityRolls: finalRolls,
              unitPrice: d.price,
              isPricingByRoll: false,
              lineTotal: d.lineTotal,
            );
          })
          .toList();

      if (widget.po == null && poDetails.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Đơn mua hàng phải có ít nhất 1 vật tư!"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final header = PurchaseOrderHeader(
        poId: widget.po?.poId ?? 0,
        poNumber: _poNumCtrl.text,
        vendorId: _selectedSupplierId!,
        orderDate: _dateCtrl.text.isEmpty ? null : _dateCtrl.text,
        expectedArrivalDate: _etaCtrl.text.isEmpty ? null : _etaCtrl.text,
        incotermId: _selectedIncotermId,
        statusId: _selectedStatusId,
        note: _noteCtrl.text,
        details: poDetails,
      );

      if (widget.po == null) {
        context.read<POHeaderCubit>().addPO(header);
      } else {
        context.read<POHeaderCubit>().updatePO(header);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // ─── Header bar ────────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 24,
              vertical: isMobile ? 12 : 16,
            ),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.po == null
                        ? "Tạo Đơn Hàng Mới"
                        : "Chi tiết PO: ${widget.po!.poNumber}",
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 20,
                      fontWeight: FontWeight.bold,
                      color: _primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Đóng"),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _savePO,
                      child: Text(widget.po == null ? "Lưu PO" : "Cập nhật"),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ─── Body ──────────────────────────────────────────────────────────
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Section label ─────────────────────────────────────
                    const Text(
                      "THÔNG TIN CHUNG (HEADER)",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Header fields ─────────────────────────────────────
                    Container(
                      padding: EdgeInsets.all(isMobile ? 14 : 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          // Nhà cung cấp + Số PO
                          _responsiveRow(
                            isMobile: isMobile,
                            children: [
                              BlocBuilder<SupplierCubit, SupplierState>(
                                builder: (context, state) {
                                  List<Supplier> sups =
                                      (state is SupplierLoaded)
                                      ? state.suppliers
                                      : [];
                                  return DropdownSearch<Supplier>(
                                    items: (f, p) => sups,
                                    itemAsString: (s) => s.supplierName,
                                    compareFn: (i, s) =>
                                        i.supplierId == s.supplierId,
                                    selectedItem: sups
                                        .where(
                                          (s) =>
                                              s.supplierId ==
                                              _selectedSupplierId,
                                        )
                                        .firstOrNull,
                                    onChanged: (val) =>
                                        _onSupplierChanged(val?.supplierId),
                                    decoratorProps: DropDownDecoratorProps(
                                      decoration: _inputDeco(
                                        "Nhà cung cấp (*)",
                                      ),
                                    ),
                                    popupProps: const PopupProps.menu(
                                      showSearchBox: true,
                                    ),
                                    validator: (v) =>
                                        v == null ? "Bắt buộc" : null,
                                  );
                                },
                              ),
                              TextFormField(
                                controller: _poNumCtrl,
                                decoration: _inputDeco("Số PO (*)"),
                                validator: (v) =>
                                    v!.isEmpty ? "Bắt buộc" : null,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Ngày đặt + ETA
                          _responsiveRow(
                            isMobile: isMobile,
                            children: [
                              TextFormField(
                                controller: _dateCtrl,
                                decoration: _inputDeco("Ngày đặt (YYYY-MM-DD)"),
                                onTap: () async {
                                  final d = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2050),
                                  );
                                  if (d != null)
                                    _dateCtrl.text = DateFormat(
                                      'yyyy-MM-dd',
                                    ).format(d);
                                },
                              ),
                              TextFormField(
                                controller: _etaCtrl,
                                decoration: _inputDeco("Dự kiến hàng về"),
                                onTap: () async {
                                  final d = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2050),
                                  );
                                  if (d != null)
                                    _etaCtrl.text = DateFormat(
                                      'yyyy-MM-dd',
                                    ).format(d);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Incoterm + Trạng thái
                          _responsiveRow(
                            isMobile: isMobile,
                            children: [
                              BlocBuilder<IncotermCubit, IncotermState>(
                                builder: (ctx, state) {
                                  List<Incoterm> list =
                                      (state is IncotermLoaded)
                                      ? state.incoterms
                                      : [];
                                  return DropdownButtonFormField<int>(
                                    value: _selectedIncotermId,
                                    decoration: _inputDeco(
                                      "Điều kiện Incoterm",
                                    ),
                                    items: list
                                        .map(
                                          (i) => DropdownMenuItem(
                                            value: i.incotermId,
                                            child: Text(i.incotermCode),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (val) =>
                                        _selectedIncotermId = val,
                                  );
                                },
                              ),
                              BlocBuilder<POStatusCubit, POStatusState>(
                                builder: (ctx, state) {
                                  List<POStatus> list =
                                      (state is POStatusLoaded)
                                      ? state.statuses
                                      : [];
                                  return DropdownButtonFormField<int>(
                                    value: _selectedStatusId,
                                    decoration: _inputDeco("Trạng thái"),
                                    items: list
                                        .map(
                                          (i) => DropdownMenuItem(
                                            value: i.statusId,
                                            child: Text(i.statusCode),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (val) => _selectedStatusId = val,
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _noteCtrl,
                            decoration: _inputDeco("Ghi chú"),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Chi tiết vật tư ────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "CHI TIẾT VẬT TƯ",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 1.2,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            if (_selectedSupplierId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Hãy chọn Nhà cung cấp ở trên trước!",
                                  ),
                                ),
                              );
                              return;
                            }
                            setState(() => _details.add(LocalPODetail()));
                          },
                          icon: const Icon(Icons.add_circle, size: 16),
                          label: const Text("Thêm dòng"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade50,
                            foregroundColor: Colors.green.shade700,
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ── Detail list: mobile = cards, desktop = table ───────
                    isMobile ? _buildMobileCardList() : _buildDesktopTable(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MOBILE: Mỗi dòng vật tư = 1 Card dọc
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildMobileCardList() {
    if (_details.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text("Bấm 'Thêm dòng' để thêm vật tư."),
      );
    }

    return Column(
      children: _details.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
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
              // ── Card header: số thứ tự + nút xoá ────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Dòng ${index + 1}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _primary,
                        fontSize: 13,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () => setState(() => _details.removeAt(index)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              // ── Card body ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mã vật tư – full width, đủ lớn để chọn thoải mái
                    const Text(
                      "Mã vật tư",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    BlocBuilder<MaterialCubit, MaterialState>(
                      builder: (context, matState) {
                        List<MaterialItem> mats = (matState is MaterialLoaded)
                            ? matState.materials
                            : [];
                        return DropdownSearch<MaterialItem>(
                          items: (f, p) => mats,
                          itemAsString: (m) => "[${m.materialCode}]",
                          compareFn: (i, s) => i.materialId == s.materialId,
                          selectedItem: mats
                              .where((m) => m.materialId == item.materialId)
                              .firstOrNull,
                          onChanged: (val) =>
                              setState(() => item.materialId = val?.materialId),
                          decoratorProps: DropDownDecoratorProps(
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          popupProps: const PopupProps.menu(
                            showSearchBox: true,
                            constraints: BoxConstraints(maxHeight: 300),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // SL (Kg) + Số cuộn (tính tự động)
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Số lượng (Kg)",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                initialValue: item.qtyKg.toString(),
                                keyboardType: TextInputType.number,
                                decoration: _denseDeco(),
                                onChanged: (v) => setState(
                                  () => item.qtyKg = double.tryParse(v) ?? 0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Số cuộn",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              BlocBuilder<MaterialCubit, MaterialState>(
                                builder: (context, matState) {
                                  int displayRolls = item.backendRolls;
                                  if (matState is MaterialLoaded &&
                                      item.materialId != null) {
                                    final mat = matState.materials
                                        .where(
                                          (m) =>
                                              m.materialId == item.materialId,
                                        )
                                        .firstOrNull;
                                    if (mat != null &&
                                        mat.kgPerBobbin != null &&
                                        mat.kgPerBobbin! > 0) {
                                      displayRolls =
                                          (item.qtyKg / mat.kgPerBobbin!)
                                              .ceil();
                                    }
                                  }
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.teal.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.teal.shade200,
                                      ),
                                    ),
                                    child: Text(
                                      "$displayRolls cuộn",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal.shade700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Tiền tệ + Đơn giá
                    Row(
                      children: [
                        // Tiền tệ
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Tiền tệ",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: item.currency,
                                isExpanded: true,
                                icon: const Icon(
                                  Icons.arrow_drop_down,
                                  size: 18,
                                ),
                                decoration: _denseDeco(),
                                items: ["VND", "USD", "CNY"]
                                    .map(
                                      (c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(
                                          c,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => item.currency = v!),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Đơn giá
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Đơn giá",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                initialValue: item.price.toString(),
                                keyboardType: TextInputType.number,
                                decoration: _denseDeco(),
                                onChanged: (v) => setState(
                                  () => item.price = double.tryParse(v) ?? 0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Thành tiền
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text(
                          "Thành tiền: ",
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        Text(
                          "${NumberFormat("#,##0.##").format(item.lineTotal)} ${item.currency}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DESKTOP: Layout bảng ngang như cũ (giữ nguyên)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildDesktopTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header row
          Container(
            color: Colors.grey.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    "Mã Vật Tư",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    "SL (Kg)",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    "Cuộn",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "Tiền tệ",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "Đơn giá",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "Thành tiền",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                SizedBox(width: 40),
              ],
            ),
          ),

          if (_details.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text("Bấm 'Thêm dòng' để thêm vật tư.")),
            ),

          ..._details.asMap().entries.map((entry) {
            int index = entry.key;
            LocalPODetail item = entry.value;
            return Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: BlocBuilder<MaterialCubit, MaterialState>(
                      builder: (context, matState) {
                        List<MaterialItem> mats = (matState is MaterialLoaded)
                            ? matState.materials
                            : [];
                        return DropdownSearch<MaterialItem>(
                          items: (f, p) => mats,
                          itemAsString: (m) => "[${m.materialCode}]",
                          compareFn: (i, s) => i.materialId == s.materialId,
                          selectedItem: mats
                              .where((m) => m.materialId == item.materialId)
                              .firstOrNull,
                          onChanged: (val) =>
                              setState(() => item.materialId = val?.materialId),
                          decoratorProps: DropDownDecoratorProps(
                            decoration: InputDecoration(
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
                          popupProps: const PopupProps.menu(
                            showSearchBox: true,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      initialValue: item.qtyKg.toString(),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 11,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      onChanged: (v) =>
                          setState(() => item.qtyKg = double.tryParse(v) ?? 0),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: BlocBuilder<MaterialCubit, MaterialState>(
                      builder: (context, matState) {
                        int displayRolls = item.backendRolls;
                        if (matState is MaterialLoaded &&
                            item.materialId != null) {
                          final mat = matState.materials
                              .where((m) => m.materialId == item.materialId)
                              .firstOrNull;
                          if (mat != null &&
                              mat.kgPerBobbin != null &&
                              mat.kgPerBobbin! > 0) {
                            displayRolls = (item.qtyKg / mat.kgPerBobbin!)
                                .ceil();
                          }
                        }
                        return Text(
                          "$displayRolls c",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade700,
                            fontSize: 13,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: item.currency,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, size: 16),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      items: ["VND", "USD", "CNY"]
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(
                                c,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => item.currency = v!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      initialValue: item.price.toString(),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 11,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      onChanged: (v) =>
                          setState(() => item.price = double.tryParse(v) ?? 0),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Text(
                      NumberFormat("#,##0.##").format(item.lineTotal),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () => setState(() => _details.removeAt(index)),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  /// Trên mobile: xếp children thành Column; desktop: Row với Expanded
  Widget _responsiveRow({
    required bool isMobile,
    required List<Widget> children,
  }) {
    if (isMobile) {
      return Column(
        children:
            children
                .expand((child) => [child, const SizedBox(height: 12)])
                .toList()
              ..removeLast(),
      );
    }
    return Row(
      children:
          children
              .expand<Widget>(
                (child) => [Expanded(child: child), const SizedBox(width: 16)],
              )
              .toList()
            ..removeLast(),
    );
  }

  InputDecoration _denseDeco() => InputDecoration(
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  );

  InputDecoration _inputDeco(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
  );
}
