class Basket {
  final int id;
  final String code;
  final double tareWeight;
  final String status; // READY, IN_USE, HOLDING, DAMAGED
  final String note;

  Basket({
    required this.id,
    required this.code,
    required this.tareWeight,
    required this.status,
    required this.note,
  });

  factory Basket.fromJson(Map<String, dynamic> json) {
    return Basket(
      id: json['basket_id'] ?? 0,
      code: json['basket_code'] ?? '',
      tareWeight: (json['tare_weight'] ?? 0).toDouble(),
      status: json['status'] ?? 'READY',
      note: json['note'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'basket_code': code,
      'tare_weight': tareWeight,
      'status': status,
      'note': note,
    };
  }
}