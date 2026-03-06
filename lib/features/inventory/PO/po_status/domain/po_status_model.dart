class POStatus {
  final int statusId;
  final String statusCode;
  final String? description;

  POStatus({
    required this.statusId,
    required this.statusCode,
    this.description,
  });

  factory POStatus.fromJson(Map<String, dynamic> json) {
    return POStatus(
      statusId: json['status_id'] ?? 0,
      statusCode: json['status_code'] ?? '',
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status_code': statusCode,
      if (description != null) 'description': description,
    };
  }
}
