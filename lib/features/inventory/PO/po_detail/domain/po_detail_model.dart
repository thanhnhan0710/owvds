class PurchaseOrderDetail {
  final int detailId;
  final int poId;
  final int materialId;
  final String currency;
  final double quantityKg;
  final int quantityRolls;
  final double unitPrice;
  final double lineTotal;
  final bool isPricingByRoll;

  // --- Các trường Logistics mới ---
  final double? oceanFreight;
  final String? confirmDelivery;
  final String? goodsReadiness;
  final String? shippingLine;
  final String? forwarder;
  final String? etd;
  final String? eta;
  final String? atd;
  final String? bookingDate;

  // --- Nhập kho & Đối soát ---
  final double receivedQuantity;
  final int receivedRolls;
  final double remainingQuantity; // Computed từ Backend
  final int remainingRolls; // Computed từ Backend

  PurchaseOrderDetail({
    this.detailId = 0,
    this.poId = 0,
    required this.materialId,
    this.currency = "USD",
    required this.quantityKg,
    this.quantityRolls = 0,
    required this.unitPrice,
    this.lineTotal = 0.0,
    this.isPricingByRoll = false,
    this.oceanFreight,
    this.confirmDelivery,
    this.goodsReadiness,
    this.shippingLine,
    this.forwarder,
    this.etd,
    this.eta,
    this.atd,
    this.bookingDate,
    this.receivedQuantity = 0.0,
    this.receivedRolls = 0,
    this.remainingQuantity = 0.0,
    this.remainingRolls = 0,
  });

  factory PurchaseOrderDetail.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderDetail(
      detailId: json['detail_id'] ?? 0,
      poId: json['po_id'] ?? 0,
      materialId: json['material_id'] ?? 0,
      currency: json['currency'] ?? 'USD',
      quantityKg: (json['quantity_kg'] ?? 0.0).toDouble(),
      quantityRolls: json['quantity_rolls'] ?? 0,
      unitPrice: (json['unit_price'] ?? 0.0).toDouble(),
      lineTotal: (json['line_total'] ?? 0.0).toDouble(),
      isPricingByRoll: json['is_pricing_by_roll'] ?? false,

      oceanFreight: json['ocean_freight'] != null
          ? (json['ocean_freight'] as num).toDouble()
          : null,
      confirmDelivery: json['confirm_delivery'],
      goodsReadiness: json['goods_readiness'],
      shippingLine: json['shipping_line'],
      forwarder: json['forwarder'],
      etd: json['etd'],
      eta: json['eta'],
      atd: json['atd'],
      bookingDate: json['booking_date'],

      receivedQuantity: (json['received_quantity'] ?? 0.0).toDouble(),
      receivedRolls: json['received_rolls'] ?? 0,
      remainingQuantity: (json['remaining_quantity'] ?? 0.0).toDouble(),
      remainingRolls: json['remaining_rolls'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'material_id': materialId,
      'currency': currency,
      'quantity_kg': quantityKg,
      'quantity_rolls': quantityRolls,
      'unit_price': unitPrice,
      'is_pricing_by_roll': isPricingByRoll,

      if (oceanFreight != null) 'ocean_freight': oceanFreight,
      if (confirmDelivery != null) 'confirm_delivery': confirmDelivery,
      if (goodsReadiness != null) 'goods_readiness': goodsReadiness,
      if (shippingLine != null) 'shipping_line': shippingLine,
      if (forwarder != null) 'forwarder': forwarder,
      if (etd != null) 'etd': etd,
      if (eta != null) 'eta': eta,
      if (atd != null) 'atd': atd,
      if (bookingDate != null) 'booking_date': bookingDate,
    };
  }
}
