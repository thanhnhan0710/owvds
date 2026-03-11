enum BOMComponentType {
  ground,
  grdMarker,
  edge,
  binder,
  stuffer,
  stufferMaker,
  lock,
  catchCord,
  filling,
  secondFilling;

  static BOMComponentType fromString(String value) {
    switch (value.toUpperCase()) {
      case "GROUND": return BOMComponentType.ground;
      case "GRD. MARKER": return BOMComponentType.grdMarker;
      case "EDGE": return BOMComponentType.edge;
      case "BINDER": return BOMComponentType.binder;
      case "STUFFER": return BOMComponentType.stuffer;
      case "STUFFER MAKER": return BOMComponentType.stufferMaker;
      case "LOCK": return BOMComponentType.lock;
      case "CATCH CORD": return BOMComponentType.catchCord;
      case "FILLING": return BOMComponentType.filling;
      case "2ND FILLING": return BOMComponentType.secondFilling;
      default: return BOMComponentType.ground;
    }
  }

  String get value {
    switch (this) {
      case BOMComponentType.ground: return "GROUND";
      case BOMComponentType.grdMarker: return "GRD. MARKER";
      case BOMComponentType.edge: return "EDGE";
      case BOMComponentType.binder: return "BINDER";
      case BOMComponentType.stuffer: return "STUFFER";
      case BOMComponentType.stufferMaker: return "STUFFER MAKER";
      case BOMComponentType.lock: return "LOCK";
      case BOMComponentType.catchCord: return "CATCH CORD";
      case BOMComponentType.filling: return "FILLING";
      case BOMComponentType.secondFilling: return "2ND FILLING";
    }
  }
}

// [MỚI] Model cho bảng tổng hợp số cuộn
class BOMMaterialSummary {
  final int materialId;
  final String materialName;
  final int totalRolls;

  BOMMaterialSummary({
    required this.materialId,
    required this.materialName,
    required this.totalRolls,
  });

  factory BOMMaterialSummary.fromJson(Map<String, dynamic> json) {
    return BOMMaterialSummary(
      materialId: json['material_id'] ?? 0,
      materialName: json['material_name'] ?? 'Unknown',
      totalRolls: json['total_rolls'] ?? 0,
    );
  }
}

class BOMHeader {
  final int bomId;
  final int productId;
  final int applicableYear; 
  final String? displayName; 
  
  final double targetWeightGm;      
  final double totalScrapRate;      
  final double totalShrinkageRate;  
  final double? widthBehindLoom;    
  final int? picks;                 

  final int version;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  final List<BOMDetail> bomDetails;

  BOMHeader({
    required this.bomId,
    required this.productId,
    required this.applicableYear,
    this.displayName,
    required this.targetWeightGm,
    required this.totalScrapRate,
    required this.totalShrinkageRate,
    this.widthBehindLoom,
    this.picks,
    required this.version,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
    this.bomDetails = const [],
  });

  factory BOMHeader.fromJson(Map<String, dynamic> json) {
    var detailsList = json['bom_details'] as List? ?? [];
    List<BOMDetail> details = detailsList.map((i) => BOMDetail.fromJson(i)).toList();

    return BOMHeader(
      bomId: json['bom_id'] ?? 0,
      productId: json['product_id'] ?? 0,
      applicableYear: json['applicable_year'] ?? DateTime.now().year,
      displayName: json['display_name'],
      targetWeightGm: (json['target_weight_gm'] ?? 0.0).toDouble(),
      totalScrapRate: (json['total_scrap_rate'] ?? 0.0).toDouble(),
      totalShrinkageRate: (json['total_shrinkage_rate'] ?? 0.0).toDouble(),
      widthBehindLoom: json['width_behind_loom'] != null ? (json['width_behind_loom']).toDouble() : null,
      picks: json['picks'],
      version: json['version'] ?? 1,
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      bomDetails: details,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'applicable_year': applicableYear,
      'target_weight_gm': targetWeightGm,
      'total_scrap_rate': totalScrapRate,
      'total_shrinkage_rate': totalShrinkageRate,
      'width_behind_loom': widthBehindLoom,
      'picks': picks,
      'is_active': isActive,
      'details': bomDetails.map((e) => e.toJson()).toList(),
    };
  }
}

class BOMDetail {
  final int detailId;
  final int bomId;
  final int materialId;
  final BOMComponentType componentType;

  final int threads;
  final String yarnTypeName;
  final double twisted;
  final double crossweaveRate;
  final double actualLengthCm;

  final double yarnDtex;
  final double weightPerYarnGm;
  final double actualWeightCal;
  final double weightPercentage;
  final double bomGm;

  final String note;

  BOMDetail({
    required this.detailId,
    required this.bomId,
    this.materialId = 1,
    required this.componentType,
    required this.threads,
    required this.yarnTypeName,
    required this.twisted,
    required this.crossweaveRate,
    required this.actualLengthCm,
    this.yarnDtex = 0.0,
    this.weightPerYarnGm = 0.0,
    this.actualWeightCal = 0.0,
    this.weightPercentage = 0.0,
    this.bomGm = 0.0,
    required this.note,
  });

  factory BOMDetail.fromJson(Map<String, dynamic> json) {
    return BOMDetail(
      detailId: json['detail_id'] ?? 0,
      bomId: json['bom_id'] ?? 0,
      materialId: json['material_id'] ?? 1,
      componentType: BOMComponentType.fromString(json['component_type'] ?? "Ground"),
      threads: json['threads'] ?? 0,
      yarnTypeName: json['yarn_type_name'] ?? '',
      twisted: (json['twisted'] ?? 1.0).toDouble(),
      crossweaveRate: (json['crossweave_rate'] ?? 0.0).toDouble(),
      actualLengthCm: (json['actual_length_cm'] ?? 0.0).toDouble(),
      yarnDtex: (json['yarn_dtex'] ?? 0.0).toDouble(),
      weightPerYarnGm: (json['weight_per_yarn_gm'] ?? 0.0).toDouble(),
      actualWeightCal: (json['actual_weight_cal'] ?? 0.0).toDouble(),
      weightPercentage: (json['weight_percentage'] ?? 0.0).toDouble(),
      bomGm: (json['bom_gm'] ?? 0.0).toDouble(),
      note: json['note'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'detail_id': detailId, 
      'material_id': materialId,
      'component_type': componentType.value,
      'threads': threads,
      'yarn_type_name': yarnTypeName,
      'twisted': twisted,
      'crossweave_rate': crossweaveRate,
      'actual_length_cm': actualLengthCm,
      'note': note,
    };
  }
  
  BOMDetail copyWith({
    int? detailId,
    int? bomId,
    int? materialId,
    BOMComponentType? componentType,
    int? threads,
    String? yarnTypeName,
    double? twisted,
    double? crossweaveRate,
    double? actualLengthCm,
    String? note,
  }) {
    return BOMDetail(
      detailId: detailId ?? this.detailId,
      bomId: bomId ?? this.bomId,
      materialId: materialId ?? this.materialId,
      componentType: componentType ?? this.componentType,
      threads: threads ?? this.threads,
      yarnTypeName: yarnTypeName ?? this.yarnTypeName,
      twisted: twisted ?? this.twisted,
      crossweaveRate: crossweaveRate ?? this.crossweaveRate,
      actualLengthCm: actualLengthCm ?? this.actualLengthCm,
      yarnDtex: yarnDtex,
      weightPerYarnGm: weightPerYarnGm,
      actualWeightCal: actualWeightCal,
      weightPercentage: weightPercentage,
      bomGm: bomGm,
      note: note ?? this.note,
    );
  }
}