class PurchaseOrderDetail {
  final int detailId;
  final int poId;
  final int materialId;
  final String currency;
  final double exchangeRate;
  final double quantityKg;
  final int quantityRolls;
  final double unitPrice;
  final double lineTotal;
  final bool isPricingByRoll;
  final double receivedQuantity;
  final int receivedRolls;

  PurchaseOrderDetail({
    this.detailId = 0,
    this.poId = 0,
    required this.materialId,
    this.currency = "VND",
    this.exchangeRate = 1.0,
    required this.quantityKg,
    this.quantityRolls = 0,
    required this.unitPrice,
    this.lineTotal = 0.0,
    this.isPricingByRoll = false,
    this.receivedQuantity = 0.0,
    this.receivedRolls = 0,
  });

  factory PurchaseOrderDetail.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderDetail(
      detailId: json['detail_id'] ?? 0,
      poId: json['po_id'] ?? 0,
      materialId: json['material_id'] ?? 0,
      currency: json['currency'] ?? 'VND',
      exchangeRate: (json['exchange_rate'] ?? 1.0).toDouble(),
      quantityKg: (json['quantity_kg'] ?? 0.0).toDouble(),
      quantityRolls: json['quantity_rolls'] ?? 0,
      unitPrice: (json['unit_price'] ?? 0.0).toDouble(),
      lineTotal: (json['line_total'] ?? 0.0).toDouble(),
      isPricingByRoll: json['is_pricing_by_roll'] ?? false,
      receivedQuantity: (json['received_quantity'] ?? 0.0).toDouble(),
      receivedRolls: json['received_rolls'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'material_id': materialId,
      'currency': currency,
      'exchange_rate': exchangeRate,
      'quantity_kg': quantityKg,
      'quantity_rolls': quantityRolls,
      'unit_price': unitPrice,
      'is_pricing_by_roll': isPricingByRoll,
    };
  }
}
