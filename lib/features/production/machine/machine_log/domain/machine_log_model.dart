class MachineLog {
  final int id;
  final int machineId;
  final String status;
  final DateTime startTime;
  final DateTime? endTime;
  final String? reason;
  final String? imageUrl; // <--- QUAN TRỌNG: Phải có dòng này
  final double durationMinutes;

  MachineLog({
    required this.id,
    required this.machineId,
    required this.status,
    required this.startTime,
    this.endTime,
    this.reason,
    this.imageUrl,
    this.durationMinutes = 0.0,
  });

  factory MachineLog.fromJson(Map<String, dynamic> json) {
    // Debug: In ra để xem server trả về gì
    // print("JSON LOG: ${json['id']} - img: ${json['image_url']}");

    DateTime start = DateTime.parse(json['start_time']);
    DateTime? end =
        json['end_time'] != null ? DateTime.parse(json['end_time']) : null;

    double duration = 0.0;
    if (end != null) {
      duration = end.difference(start).inMinutes.toDouble();
    } else {
      duration = DateTime.now().difference(start).inMinutes.toDouble();
    }

    return MachineLog(
      id: json['id'] ?? 0,
      machineId: json['machine_id'] ?? 0,
      status: json['status'] ?? 'UNKNOWN',
      startTime: start,
      endTime: end,
      reason: json['reason'],
      // <--- QUAN TRỌNG: Map đúng key 'image_url' từ server snake_case
      imageUrl: json['image_url'],
      durationMinutes: duration,
    );
  }
}
