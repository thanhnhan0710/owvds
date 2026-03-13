// lib/features/production/weaving_analytics/domain/weaving_analytics_model.dart

// ─────────────────────────────────────────
// Sản lượng theo Máy
// ─────────────────────────────────────────
class ProductionByMachineItem {
  final String periodLabel;
  final int periodOrder;
  final int machineId;
  final String machineName;
  final int line;
  final double totalWeight;
  final double runWaste;
  final double setupWaste;
  final double totalWaste;

  ProductionByMachineItem({
    required this.periodLabel,
    required this.periodOrder,
    required this.machineId,
    required this.machineName,
    required this.line,
    required this.totalWeight,
    required this.runWaste,
    required this.setupWaste,
    required this.totalWaste,
  });

  factory ProductionByMachineItem.fromJson(Map<String, dynamic> json) {
    return ProductionByMachineItem(
      periodLabel: json['period_label'] ?? '',
      periodOrder: json['period_order'] ?? 0,
      machineId: json['machine_id'] ?? 0,
      machineName: json['machine_name'] ?? '',
      line: json['line'] ?? 0,
      totalWeight: (json['total_weight'] ?? 0).toDouble(),
      runWaste: (json['run_waste'] ?? 0).toDouble(),
      setupWaste: (json['setup_waste'] ?? 0).toDouble(),
      totalWaste: (json['total_waste'] ?? 0).toDouble(),
    );
  }

  /// Nhãn hiển thị cho máy + line
  String get machineLabel => '$machineName-L$line';
}

class ProductionByMachineResponse {
  final String period;
  final String? startDate;
  final String? endDate;
  final List<ProductionByMachineItem> items;

  ProductionByMachineResponse({
    required this.period,
    this.startDate,
    this.endDate,
    required this.items,
  });

  factory ProductionByMachineResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? [];
    return ProductionByMachineResponse(
      period: json['period'] ?? '',
      startDate: json['start_date'],
      endDate: json['end_date'],
      items: rawItems.map((e) => ProductionByMachineItem.fromJson(e)).toList(),
    );
  }

  /// Danh sách nhãn period duy nhất, đã sắp xếp
  List<String> get periodLabels {
    final seen = <int>{};
    final labels = <_LabelOrder>[];
    for (final i in items) {
      if (seen.add(i.periodOrder)) {
        labels.add(_LabelOrder(i.periodLabel, i.periodOrder));
      }
    }
    labels.sort((a, b) => a.order.compareTo(b.order));
    return labels.map((e) => e.label).toList();
  }

  /// Danh sách tên máy duy nhất
  List<String> get machineLabels {
    final seen = <String>{};
    for (final i in items) {
      seen.add(i.machineLabel);
    }
    return seen.toList()..sort();
  }

  /// Tổng sản lượng
  double get totalWeight => items.fold(0, (s, e) => s + e.totalWeight);

  /// Tổng phế
  double get totalWaste => items.fold(0, (s, e) => s + e.totalWaste);
}

class _LabelOrder {
  final String label;
  final int order;
  _LabelOrder(this.label, this.order);
}

// ─────────────────────────────────────────
// Sản lượng theo Mã sản phẩm
// ─────────────────────────────────────────
class ProductionByProductItem {
  final String periodLabel;
  final int periodOrder;
  final String itemCode;
  final double totalWeight;

  ProductionByProductItem({
    required this.periodLabel,
    required this.periodOrder,
    required this.itemCode,
    required this.totalWeight,
  });

  factory ProductionByProductItem.fromJson(Map<String, dynamic> json) {
    return ProductionByProductItem(
      periodLabel: json['period_label'] ?? '',
      periodOrder: json['period_order'] ?? 0,
      itemCode: json['item_code'] ?? 'N/A',
      totalWeight: (json['total_weight'] ?? 0).toDouble(),
    );
  }
}

class ProductionByProductResponse {
  final String period;
  final String? startDate;
  final String? endDate;
  final List<ProductionByProductItem> items;

  ProductionByProductResponse({
    required this.period,
    this.startDate,
    this.endDate,
    required this.items,
  });

  factory ProductionByProductResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? [];
    return ProductionByProductResponse(
      period: json['period'] ?? '',
      startDate: json['start_date'],
      endDate: json['end_date'],
      items: rawItems.map((e) => ProductionByProductItem.fromJson(e)).toList(),
    );
  }

  List<String> get uniqueItemCodes {
    final seen = <String>{};
    for (final i in items) {
      seen.add(i.itemCode);
    }
    return seen.toList()..sort();
  }

  double get totalWeight => items.fold(0, (s, e) => s + e.totalWeight);
}

// ─────────────────────────────────────────
// KPI
// ─────────────────────────────────────────
class ProductionKPI {
  final String period;
  final double totalWeight;
  final double totalRunWaste;
  final double totalSetupWaste;
  final double totalWaste;
  final double wasteRatePct;
  final int recordCount;

  ProductionKPI({
    required this.period,
    required this.totalWeight,
    required this.totalRunWaste,
    required this.totalSetupWaste,
    required this.totalWaste,
    required this.wasteRatePct,
    required this.recordCount,
  });

  factory ProductionKPI.fromJson(Map<String, dynamic> json) {
    return ProductionKPI(
      period: json['period'] ?? '',
      totalWeight: (json['total_weight'] ?? 0).toDouble(),
      totalRunWaste: (json['total_run_waste'] ?? 0).toDouble(),
      totalSetupWaste: (json['total_setup_waste'] ?? 0).toDouble(),
      totalWaste: (json['total_waste'] ?? 0).toDouble(),
      wasteRatePct: (json['waste_rate_pct'] ?? 0).toDouble(),
      recordCount: json['record_count'] ?? 0,
    );
  }

  static ProductionKPI empty() => ProductionKPI(
    period: '',
    totalWeight: 0,
    totalRunWaste: 0,
    totalSetupWaste: 0,
    totalWaste: 0,
    wasteRatePct: 0,
    recordCount: 0,
  );
}

// ─────────────────────────────────────────
// Bộ lọc thời gian
// ─────────────────────────────────────────
enum AnalyticsPeriod {
  shift('Ca', 'shift'),
  day('Ngày', 'day'),
  week('Tuần', 'week'),
  month('Tháng', 'month'),
  year('Năm', 'year');

  final String label;
  final String value;
  const AnalyticsPeriod(this.label, this.value);
}
