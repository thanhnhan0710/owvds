import 'package:flutter/material.dart' hide MaterialState;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:intl/intl.dart';

import '../../../../inventory/material/presentation/bloc/material_cubit.dart';
import '../../../../inventory/material/domain/material_model.dart';

class LocalPODetail {
  int? materialId;

  // Tài chính & Khối lượng đặt
  String currency;
  double qtyKg;
  double price;
  int backendRolls;

  // Thông tin đối soát Nhập kho
  double receivedQuantity;
  int receivedRolls;

  // Tự động tính toán số lượng còn lại (Kg)
  double get remainingQuantity =>
      (qtyKg - receivedQuantity) > 0 ? (qtyKg - receivedQuantity) : 0;

  // Logistics
  double? oceanFreight;
  String? confirmDelivery;
  String? goodsReadiness;
  String? shippingLine;
  String? forwarder;
  String? etd;
  String? eta;
  String? atd;
  String? bookingDate;

  LocalPODetail({
    this.materialId,
    this.currency = "USD",
    this.qtyKg = 0,
    this.price = 0,
    this.backendRolls = 0,
    this.receivedQuantity = 0,
    this.receivedRolls = 0,
    this.oceanFreight,
    this.confirmDelivery,
    this.goodsReadiness,
    this.shippingLine,
    this.forwarder,
    this.etd,
    this.eta,
    this.atd,
    this.bookingDate,
  });

  double get lineTotal => qtyKg * price;

  // JSON Methods cho tính năng Auto-Save
  Map<String, dynamic> toJson() => {
    'materialId': materialId,
    'currency': currency,
    'qtyKg': qtyKg,
    'price': price,
    'backendRolls': backendRolls,
    'receivedQuantity': receivedQuantity,
    'receivedRolls': receivedRolls,
    'oceanFreight': oceanFreight,
    'confirmDelivery': confirmDelivery,
    'goodsReadiness': goodsReadiness,
    'shippingLine': shippingLine,
    'forwarder': forwarder,
    'etd': etd,
    'eta': eta,
    'atd': atd,
    'bookingDate': bookingDate,
  };

  factory LocalPODetail.fromJson(Map<String, dynamic> json) => LocalPODetail(
    materialId: json['materialId'],
    currency: json['currency'] ?? "USD",
    qtyKg: (json['qtyKg'] ?? 0).toDouble(),
    price: (json['price'] ?? 0).toDouble(),
    backendRolls: json['backendRolls'] ?? 0,
    receivedQuantity: (json['receivedQuantity'] ?? 0).toDouble(),
    receivedRolls: json['receivedRolls'] ?? 0,
    oceanFreight: json['oceanFreight'] != null
        ? (json['oceanFreight'] as num).toDouble()
        : null,
    confirmDelivery: json['confirmDelivery'],
    goodsReadiness: json['goodsReadiness'],
    shippingLine: json['shippingLine'],
    forwarder: json['forwarder'],
    etd: json['etd'],
    eta: json['eta'],
    atd: json['atd'],
    bookingDate: json['bookingDate'],
  );
}

class PODetailTable extends StatefulWidget {
  final List<LocalPODetail> details;
  const PODetailTable({super.key, required this.details});

  @override
  State<PODetailTable> createState() => _PODetailTableState();
}

class _PODetailTableState extends State<PODetailTable> {
  void _pickDate(BuildContext context, LocalPODetail item, String field) async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2050),
    );
    if (d != null) {
      setState(() {
        String formatted = DateFormat('yyyy-MM-dd').format(d);
        if (field == 'etd') item.etd = formatted;
        if (field == 'eta') item.eta = formatted;
        if (field == 'atd') item.atd = formatted;
        if (field == 'booking') item.bookingDate = formatted;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final numFmt = NumberFormat("#,##0.##", "en_US");

    double totalUSD = 0;
    for (var d in widget.details) {
      if (d.materialId != null) totalUSD += d.lineTotal;
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              // [ĐÃ SỬA]: Tăng minWidth để đảm bảo bao phủ đủ tổng chiều rộng cột + khoảng cách
              constraints: const BoxConstraints(minWidth: 2250),
              child: Column(
                children: [
                  // --- 1. HEADER CỦA BẢNG ---
                  Container(
                    color: Colors.grey.shade50,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        // [ĐÃ SỬA LỖI LỆCH PHA]: Thêm các SizedBox(width: 8) tương ứng với các dòng Data bên dưới
                        _buildHeaderCell(
                          "Mã Vật Tư",
                          200,
                          color: Colors.black87,
                        ),
                        const SizedBox(width: 8),

                        _buildHeaderCell(
                          "Đặt (Kg)",
                          90,
                          align: TextAlign.right,
                          color: Colors.black87,
                        ),
                        const SizedBox(width: 8),

                        _buildHeaderCell(
                          "Đặt (c)",
                          70,
                          align: TextAlign.right,
                          color: Colors.black87,
                        ),
                        const SizedBox(width: 8),

                        _buildHeaderCell(
                          "Nhận (Kg)",
                          90,
                          align: TextAlign.right,
                          color: Colors.purple.shade700,
                        ),
                        const SizedBox(width: 8),

                        _buildHeaderCell(
                          "Nhận (c)",
                          70,
                          align: TextAlign.right,
                          color: Colors.purple.shade700,
                        ),
                        const SizedBox(width: 8),

                        _buildHeaderCell(
                          "Còn (Kg)",
                          90,
                          align: TextAlign.right,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 8),

                        _buildHeaderCell(
                          "Còn (c)",
                          70,
                          align: TextAlign.right,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 8),

                        _buildHeaderCell(
                          "Tiền tệ",
                          80,
                          align: TextAlign.center,
                          color: Colors.black87,
                        ),
                        const SizedBox(width: 8),

                        _buildHeaderCell(
                          "Đơn giá",
                          90,
                          align: TextAlign.right,
                          color: Colors.black87,
                        ),
                        const SizedBox(width: 8),

                        _buildHeaderCell(
                          "Thành tiền",
                          110,
                          align: TextAlign.right,
                          color: Colors.black87,
                        ),
                        const SizedBox(width: 8),

                        _buildHeaderCell(
                          "Conf. Delivery",
                          100,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 8),

                        _buildHeaderCell(
                          "Readiness",
                          100,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 8),

                        _buildHeaderCell(
                          "Ship Line",
                          100,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 8),

                        _buildHeaderCell(
                          "FWD",
                          100,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 8),

                        _buildHeaderCell(
                          "O/F (\$)",
                          80,
                          align: TextAlign.right,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 8),

                        _buildHeaderCell(
                          "Booking Date",
                          120,
                          align: TextAlign.center,
                          color: Colors.orange.shade800,
                        ),
                        const SizedBox(width: 8),

                        _buildHeaderCell(
                          "ETD",
                          120,
                          align: TextAlign.center,
                          color: Colors.orange.shade800,
                        ),
                        const SizedBox(width: 8),

                        _buildHeaderCell(
                          "ETA",
                          120,
                          align: TextAlign.center,
                          color: Colors.orange.shade800,
                        ),
                        const SizedBox(width: 8),

                        _buildHeaderCell(
                          "ATD",
                          120,
                          align: TextAlign.center,
                          color: Colors.orange.shade800,
                        ),
                        const SizedBox(width: 8),

                        const SizedBox(width: 40),
                      ],
                    ),
                  ),

                  if (widget.details.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text("Bấm 'Thêm dòng vật tư' để thêm hàng."),
                      ),
                    ),

                  // --- 2. CÁC DÒNG NHẬP LIỆU ---
                  ...widget.details.asMap().entries.map((entry) {
                    int index = entry.key;
                    LocalPODetail item = entry.value;

                    return Container(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          // 1. Mã vật tư
                          SizedBox(
                            width: 200,
                            child: BlocBuilder<MaterialCubit, MaterialState>(
                              builder: (context, matState) {
                                List<MaterialItem> mats =
                                    (matState is MaterialLoaded)
                                    ? matState.materials
                                    : [];
                                return DropdownSearch<MaterialItem>(
                                  popupProps: PopupProps.menu(
                                    showSearchBox: true,
                                    searchFieldProps: TextFieldProps(
                                      decoration: InputDecoration(
                                        hintText: "Tìm mã/tên...",
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 8,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  items: (String filter, dynamic props) {
                                    if (filter.isEmpty) return mats;
                                    return mats
                                        .where(
                                          (m) =>
                                              m.materialCode
                                                  .toLowerCase()
                                                  .contains(
                                                    filter.toLowerCase(),
                                                  ) ||
                                              m.materialName
                                                  .toLowerCase()
                                                  .contains(
                                                    filter.toLowerCase(),
                                                  ),
                                        )
                                        .toList();
                                  },
                                  itemAsString: (MaterialItem m) =>
                                      "[${m.materialCode}]",
                                  compareFn:
                                      (
                                        MaterialItem item1,
                                        MaterialItem item2,
                                      ) => item1.materialId == item2.materialId,
                                  selectedItem: mats
                                      .where(
                                        (m) => m.materialId == item.materialId,
                                      )
                                      .firstOrNull,
                                  onChanged: (MaterialItem? val) => setState(
                                    () => item.materialId = val?.materialId,
                                  ),
                                  decoratorProps: DropDownDecoratorProps(
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 8,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),

                          // 2. Số lượng Đặt (Kg)
                          SizedBox(
                            width: 90,
                            child: TextFormField(
                              initialValue: item.qtyKg == 0
                                  ? ''
                                  : numFmt
                                        .format(item.qtyKg)
                                        .replaceAll(',', ''),
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.right,
                              decoration: _inputDeco(),
                              onChanged: (v) => setState(
                                () => item.qtyKg = double.tryParse(v) ?? 0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // --- NHÓM TÍNH TOÁN (Cuộn, Đã nhận, Còn lại) BỌC TRONG BLOC ĐỂ TÍNH TOÁN ĐỒNG BỘ ---
                          BlocBuilder<MaterialCubit, MaterialState>(
                            builder: (context, matState) {
                              // Tính số cuộn đặt ban đầu
                              int displayRolls = item.backendRolls;
                              if (matState is MaterialLoaded &&
                                  item.materialId != null) {
                                final mat = matState.materials
                                    .where(
                                      (m) => m.materialId == item.materialId,
                                    )
                                    .firstOrNull;
                                if (mat != null &&
                                    mat.kgPerBobbin != null &&
                                    mat.kgPerBobbin! > 0) {
                                  displayRolls = (item.qtyKg / mat.kgPerBobbin!)
                                      .ceil();
                                }
                              }

                              // Tính số cuộn còn lại
                              int remainingRolls =
                                  displayRolls - item.receivedRolls;
                              if (remainingRolls < 0) remainingRolls = 0;

                              return Row(
                                children: [
                                  // 3. Đặt (Cuộn)
                                  SizedBox(
                                    width: 70,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.teal.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        "$displayRolls",
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.teal.shade700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // 4. Đã nhận (Kg)
                                  SizedBox(
                                    width: 90,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.purple.shade50,
                                        border: Border.all(
                                          color: Colors.purple.shade100,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        numFmt.format(item.receivedQuantity),
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.purple.shade700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // 5. Đã nhận (Cuộn)
                                  SizedBox(
                                    width: 70,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.purple.shade50,
                                        border: Border.all(
                                          color: Colors.purple.shade100,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        numFmt.format(item.receivedRolls),
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.purple.shade700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // 6. Còn lại (Kg)
                                  SizedBox(
                                    width: 90,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            item.remainingQuantity == 0 &&
                                                item.qtyKg > 0
                                            ? Colors.green.shade50
                                            : Colors.orange.shade50,
                                        border: Border.all(
                                          color:
                                              item.remainingQuantity == 0 &&
                                                  item.qtyKg > 0
                                              ? Colors.green.shade200
                                              : Colors.orange.shade200,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        numFmt.format(item.remainingQuantity),
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color:
                                              item.remainingQuantity == 0 &&
                                                  item.qtyKg > 0
                                              ? Colors.green.shade700
                                              : Colors.orange.shade800,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // 7. Còn lại (Cuộn)
                                  SizedBox(
                                    width: 70,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            item.remainingQuantity == 0 &&
                                                item.qtyKg > 0
                                            ? Colors.green.shade50
                                            : Colors.orange.shade50,
                                        border: Border.all(
                                          color:
                                              item.remainingQuantity == 0 &&
                                                  item.qtyKg > 0
                                              ? Colors.green.shade200
                                              : Colors.orange.shade200,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        numFmt.format(remainingRolls),
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color:
                                              item.remainingQuantity == 0 &&
                                                  item.qtyKg > 0
                                              ? Colors.green.shade700
                                              : Colors.orange.shade800,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(width: 8),

                          // Tiền tệ
                          SizedBox(
                            width: 80,
                            child: DropdownButtonFormField<String>(
                              value: item.currency,
                              isExpanded: true,
                              icon: const Icon(Icons.arrow_drop_down, size: 16),
                              decoration: _inputDeco(),
                              items: ["USD", "CNY", "VND"]
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(
                                        c,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => item.currency = v!),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Giá
                          SizedBox(
                            width: 90,
                            child: TextFormField(
                              initialValue: item.price == 0
                                  ? ''
                                  : numFmt
                                        .format(item.price)
                                        .replaceAll(',', ''),
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.right,
                              decoration: _inputDeco(),
                              onChanged: (v) => setState(
                                () => item.price = double.tryParse(v) ?? 0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Thành tiền
                          SizedBox(
                            width: 110,
                            child: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 8),
                              child: Text(
                                numFmt.format(item.lineTotal),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Logistics
                          SizedBox(
                            width: 100,
                            child: TextFormField(
                              initialValue: item.confirmDelivery,
                              decoration: _inputDeco(
                                fillColor: Colors.blue.shade50,
                              ),
                              onChanged: (v) => item.confirmDelivery = v,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 100,
                            child: TextFormField(
                              initialValue: item.goodsReadiness,
                              decoration: _inputDeco(
                                fillColor: Colors.blue.shade50,
                              ),
                              onChanged: (v) => item.goodsReadiness = v,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 100,
                            child: TextFormField(
                              initialValue: item.shippingLine,
                              decoration: _inputDeco(
                                fillColor: Colors.blue.shade50,
                              ),
                              onChanged: (v) => item.shippingLine = v,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 100,
                            child: TextFormField(
                              initialValue: item.forwarder,
                              decoration: _inputDeco(
                                fillColor: Colors.blue.shade50,
                              ),
                              onChanged: (v) => item.forwarder = v,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 80,
                            child: TextFormField(
                              initialValue: item.oceanFreight?.toString() ?? '',
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.right,
                              decoration: _inputDeco(
                                fillColor: Colors.blue.shade50,
                              ),
                              onChanged: (v) =>
                                  item.oceanFreight = double.tryParse(v),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Ngày tháng
                          SizedBox(
                            width: 120,
                            child: InkWell(
                              onTap: () => _pickDate(context, item, 'booking'),
                              child: InputDecorator(
                                decoration: _inputDeco(
                                  fillColor: Colors.orange.shade50,
                                ),
                                child: Text(
                                  item.bookingDate ?? '',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 120,
                            child: InkWell(
                              onTap: () => _pickDate(context, item, 'etd'),
                              child: InputDecorator(
                                decoration: _inputDeco(
                                  fillColor: Colors.orange.shade50,
                                ),
                                child: Text(
                                  item.etd ?? '',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 120,
                            child: InkWell(
                              onTap: () => _pickDate(context, item, 'eta'),
                              child: InputDecorator(
                                decoration: _inputDeco(
                                  fillColor: Colors.orange.shade50,
                                ),
                                child: Text(
                                  item.eta ?? '',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 120,
                            child: InkWell(
                              onTap: () => _pickDate(context, item, 'atd'),
                              child: InputDecorator(
                                decoration: _inputDeco(
                                  fillColor: Colors.orange.shade50,
                                ),
                                child: Text(
                                  item.atd ?? '',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),
                          SizedBox(
                            width: 40,
                            child: IconButton(
                              icon: const Icon(
                                Icons.remove_circle,
                                color: Colors.red,
                              ),
                              onPressed: () => setState(
                                () => widget.details.removeAt(index),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // 3. FOOTER TỔNG TIỀN
          if (widget.details.isNotEmpty)
            Container(
              color: const Color(0xFF003366),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    "TỔNG CỘNG ĐƠN HÀNG: ",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    "\$ ${numFmt.format(totalUSD)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco({Color? fillColor}) => InputDecoration(
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
    filled: fillColor != null,
    fillColor: fillColor ?? Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
  );

  Widget _buildHeaderCell(
    String text,
    double width, {
    TextAlign align = TextAlign.left,
    Color color = Colors.black87,
  }) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11,
          color: color,
        ),
      ),
    );
  }
}
