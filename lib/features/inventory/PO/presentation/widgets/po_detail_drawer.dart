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

import '../../../../../core/widgets/responsive_layout.dart';

import '../../../../inventory/supplier/presentation/bloc/supplier_cubit.dart';
import '../../../../inventory/supplier/domain/supplier_model.dart';
import '../../../../inventory/material/presentation/bloc/material_cubit.dart';

import '../../po_detail/domain/po_detail_model.dart';

// Import bảng table nhập liệu động
import 'po_detail_table.dart';

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
  final _noteCtrl = TextEditingController();

  int? _selectedSupplierId;
  int? _selectedIncotermId;
  int? _selectedStatusId;

  final List<LocalPODetail> _details = [];

  @override
  void initState() {
    super.initState();
    if (widget.po != null) {
      _poNumCtrl.text = widget.po!.poNumber;
      _dateCtrl.text = widget.po!.orderDate ?? '';
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
            oceanFreight: d.oceanFreight,
            confirmDelivery: d.confirmDelivery,
            goodsReadiness: d.goodsReadiness,
            shippingLine: d.shippingLine,
            forwarder: d.forwarder,
            etd: d.etd,
            eta: d.eta,
            atd: d.atd,
            bookingDate: d.bookingDate,
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
        if (mounted) setState(() => _poNumCtrl.text = nextNumber);
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
              content: Text("Đã đổi Nhà cung cấp. Cần nhập lại vật tư!"),
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

      List<PurchaseOrderDetail> poDetails = _details
          .where((d) => d.materialId != null)
          .map((d) {
            return PurchaseOrderDetail(
              materialId: d.materialId!,
              currency: d.currency,
              quantityKg: d.qtyKg,
              quantityRolls: d.backendRolls,
              unitPrice: d.price,
              isPricingByRoll: false,
              lineTotal: d.lineTotal,
              oceanFreight: d.oceanFreight,
              confirmDelivery: d.confirmDelivery,
              goodsReadiness: d.goodsReadiness,
              shippingLine: d.shippingLine,
              forwarder: d.forwarder,
              etd: d.etd,
              eta: d.eta,
              atd: d.atd,
              bookingDate: d.bookingDate,
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
    // Lấy trạng thái màn hình để responsive form
    final isMobile = ResponsiveLayout.isMobile(context);

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // DRAWER HEADER (ĐÃ SỬA LỖI OVERFLOW)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 24,
              vertical: 16,
            ),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.description,
                        color: const Color(0xFF003366),
                        size: isMobile ? 24 : 28,
                      ),
                      SizedBox(width: isMobile ? 8 : 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.po == null
                                  ? "Tạo Đơn Mới"
                                  : "Chi tiết PO: ${widget.po!.poNumber}",
                              style: TextStyle(
                                fontSize: isMobile ? 16 : 18,
                                fontWeight: FontWeight.bold,
                                color: _primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (!isMobile)
                              Text(
                                "Cập nhật thông tin & Lịch trình",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: isMobile ? 8 : 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isMobile)
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Đóng"),
                      ),
                    if (!isMobile) const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 12 : 16,
                          vertical: 10,
                        ),
                      ),
                      icon: Icon(Icons.save, size: isMobile ? 16 : 18),
                      onPressed: _savePO,
                      label: Text(
                        widget.po == null ? "Lưu" : "Cập nhật",
                        style: TextStyle(fontSize: isMobile ? 13 : 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // DRAWER BODY
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- HEADER SECTION ---
                    const Text(
                      "1. THÔNG TIN CHUNG (HEADER)",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.all(isMobile ? 16 : 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          // Hàng 1
                          isMobile
                              ? Column(
                                  children: [
                                    _buildSupplierDropdown(),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _poNumCtrl,
                                      decoration: _inputDeco("Số PO (*)"),
                                      validator: (v) =>
                                          v!.isEmpty ? "Bắt buộc" : null,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildDatePicker(),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: _buildSupplierDropdown(),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      flex: 1,
                                      child: TextFormField(
                                        controller: _poNumCtrl,
                                        decoration: _inputDeco("Số PO (*)"),
                                        validator: (v) =>
                                            v!.isEmpty ? "Bắt buộc" : null,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      flex: 1,
                                      child: _buildDatePicker(),
                                    ),
                                  ],
                                ),
                          const SizedBox(height: 16),

                          // Hàng 2 (ĐÃ SỬA isExpanded: true ĐỂ CHỐNG TRÀN)
                          isMobile
                              ? Column(
                                  children: [
                                    _buildIncotermDropdown(),
                                    const SizedBox(height: 16),
                                    _buildStatusDropdown(),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _noteCtrl,
                                      decoration: _inputDeco("Ghi chú chung"),
                                      maxLines: 2,
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(child: _buildIncotermDropdown()),
                                    const SizedBox(width: 16),
                                    Expanded(child: _buildStatusDropdown()),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      flex: 2,
                                      child: TextFormField(
                                        controller: _noteCtrl,
                                        decoration: _inputDeco("Ghi chú chung"),
                                      ),
                                    ),
                                  ],
                                ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // --- DETAIL SECTION ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "2. CHI TIẾT VẬT TƯ & LỊCH TRÌNH",
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
                          label: Text(isMobile ? "Thêm" : "Thêm dòng"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade50,
                            foregroundColor: Colors.green.shade700,
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    PODetailTable(details: _details),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // CÁC WIDGETS TÁCH RỜI ĐỂ DỄ ĐỌC CODE
  Widget _buildSupplierDropdown() {
    return BlocBuilder<SupplierCubit, SupplierState>(
      builder: (context, state) {
        List<Supplier> sups = (state is SupplierLoaded) ? state.suppliers : [];
        return DropdownSearch<Supplier>(
          items: (f, p) => sups,
          itemAsString: (s) => s.supplierName,
          compareFn: (i, s) => i.supplierId == s.supplierId,
          selectedItem: sups
              .where((s) => s.supplierId == _selectedSupplierId)
              .firstOrNull,
          onChanged: (val) => _onSupplierChanged(val?.supplierId),
          decoratorProps: DropDownDecoratorProps(
            decoration: _inputDeco("Nhà cung cấp (*)"),
          ),
          popupProps: const PopupProps.menu(showSearchBox: true),
          validator: (v) => v == null ? "Bắt buộc" : null,
        );
      },
    );
  }

  Widget _buildDatePicker() {
    return TextFormField(
      controller: _dateCtrl,
      decoration: _inputDeco("Ngày đặt (YYYY-MM-DD)"),
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2050),
        );
        if (d != null) _dateCtrl.text = DateFormat('yyyy-MM-dd').format(d);
      },
    );
  }

  Widget _buildIncotermDropdown() {
    return BlocBuilder<IncotermCubit, IncotermState>(
      builder: (ctx, state) {
        List<Incoterm> list = (state is IncotermLoaded) ? state.incoterms : [];
        return DropdownButtonFormField<int>(
          isExpanded: true, // [SỬA LỖI TRÀN]
          value: _selectedIncotermId,
          decoration: _inputDeco("Điều kiện Incoterm"),
          items: list
              .map(
                (i) => DropdownMenuItem(
                  value: i.incotermId,
                  child: Text(i.incotermCode, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (val) => _selectedIncotermId = val,
        );
      },
    );
  }

  Widget _buildStatusDropdown() {
    return BlocBuilder<POStatusCubit, POStatusState>(
      builder: (ctx, state) {
        List<POStatus> list = (state is POStatusLoaded) ? state.statuses : [];
        return DropdownButtonFormField<int>(
          isExpanded: true, // [SỬA LỖI TRÀN]
          value: _selectedStatusId,
          decoration: _inputDeco("Trạng thái"),
          items: list
              .map(
                (i) => DropdownMenuItem(
                  value: i.statusId,
                  child: Text(i.statusCode, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (val) => _selectedStatusId = val,
        );
      },
    );
  }

  InputDecoration _inputDeco(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
