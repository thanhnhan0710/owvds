import '../../po_detail/domain/po_detail_model.dart';

class PurchaseOrderHeader {
  final int poId;
  final String poNumber;
  final int vendorId;
  final String? orderDate;
  final String? expectedArrivalDate;
  final int? incotermId;
  final int? statusId;
  final String? note;
  final double totalAmount;

  final List<PurchaseOrderDetail> details;

  PurchaseOrderHeader({
    this.poId = 0,
    required this.poNumber,
    required this.vendorId,
    this.orderDate,
    this.expectedArrivalDate,
    this.incotermId,
    this.statusId,
    this.note,
    this.totalAmount = 0.0,
    required this.details,
  });

  factory PurchaseOrderHeader.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderHeader(
      poId: json['po_id'] ?? 0,
      poNumber: json['po_number'] ?? '',
      vendorId: json['vendor_id'] ?? 0,
      orderDate: json['order_date'],
      expectedArrivalDate: json['expected_arrival_date'],
      incotermId: json['incoterm_id'],
      statusId: json['status_id'],
      note: json['note'],
      totalAmount: (json['total_amount'] ?? 0.0).toDouble(),
      details: json['details'] != null
          ? (json['details'] as List)
                .map((i) => PurchaseOrderDetail.fromJson(i))
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJsonForCreate() {
    return {
      'po_number': poNumber,
      'vendor_id': vendorId,
      if (orderDate != null) 'order_date': orderDate,
      if (expectedArrivalDate != null)
        'expected_arrival_date': expectedArrivalDate,
      if (incotermId != null) 'incoterm_id': incotermId,
      if (statusId != null) 'status_id': statusId,
      if (note != null) 'note': note,
      'details': details.map((d) => d.toJson()).toList(),
    };
  }

  Map<String, dynamic> toJsonForUpdate() {
    return {
      'po_number': poNumber,
      'vendor_id': vendorId,
      if (orderDate != null) 'order_date': orderDate,
      if (expectedArrivalDate != null)
        'expected_arrival_date': expectedArrivalDate,
      if (incotermId != null) 'incoterm_id': incotermId,
      if (statusId != null) 'status_id': statusId,
      if (note != null) 'note': note,
      // [QUAN TRỌNG - ĐÃ SỬA]: Phải có mảng details để gửi lên API khi Cập nhật (Edit)
      'details': details.map((d) => d.toJson()).toList(),
    };
  }
}
