class Incoterm {
  final int incotermId;
  final String incotermCode;
  final String? description;

  Incoterm({
    required this.incotermId,
    required this.incotermCode,
    this.description,
  });

  factory Incoterm.fromJson(Map<String, dynamic> json) {
    return Incoterm(
      incotermId: json['incoterm_id'] ?? 0,
      incotermCode: json['incoterm_code'] ?? '',
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'incoterm_code': incotermCode,
      if (description != null) 'description': description,
    };
  }
}
