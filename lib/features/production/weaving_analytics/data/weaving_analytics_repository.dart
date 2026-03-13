// lib/features/production/weaving_analytics/data/weaving_analytics_repository.dart

import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../domain/weaving_analytics_model.dart';

class WeavingAnalyticsRepository {
  final Dio _dio = ApiClient().dio;

  static const String _base = '/api/v1/weaving-productions/analytics';

  // ─────────────────────────────────────────
  // Tham số chung
  // ─────────────────────────────────────────
  Map<String, dynamic> _params(
    AnalyticsPeriod period,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    final p = <String, dynamic>{'period': period.value};
    if (startDate != null) p['start_date'] = _fmt(startDate);
    if (endDate != null) p['end_date'] = _fmt(endDate);
    return p;
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ─────────────────────────────────────────
  // KPI
  // ─────────────────────────────────────────
  Future<ProductionKPI> getKPI(
    AnalyticsPeriod period, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final res = await _dio.get(
        '$_base/kpi',
        queryParameters: _params(period, startDate, endDate),
      );
      return ProductionKPI.fromJson(res.data);
    } catch (e) {
      throw Exception('Failed to load KPI: $e');
    }
  }

  // ─────────────────────────────────────────
  // Sản lượng theo Máy
  // ─────────────────────────────────────────
  Future<ProductionByMachineResponse> getByMachine(
    AnalyticsPeriod period, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final res = await _dio.get(
        '$_base/by-machine',
        queryParameters: _params(period, startDate, endDate),
      );
      return ProductionByMachineResponse.fromJson(res.data);
    } catch (e) {
      throw Exception('Failed to load production by machine: $e');
    }
  }

  // ─────────────────────────────────────────
  // Sản lượng theo Mã SP
  // ─────────────────────────────────────────
  Future<ProductionByProductResponse> getByProduct(
    AnalyticsPeriod period, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final res = await _dio.get(
        '$_base/by-product',
        queryParameters: _params(period, startDate, endDate),
      );
      return ProductionByProductResponse.fromJson(res.data);
    } catch (e) {
      throw Exception('Failed to load production by product: $e');
    }
  }

  // ─────────────────────────────────────────
  // Tải tất cả (gọi song song)
  // ─────────────────────────────────────────
  Future<
    ({
      ProductionKPI kpi,
      ProductionByMachineResponse byMachine,
      ProductionByProductResponse byProduct,
    })
  >
  loadAll(
    AnalyticsPeriod period, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final results = await Future.wait([
      getKPI(period, startDate: startDate, endDate: endDate),
      getByMachine(period, startDate: startDate, endDate: endDate),
      getByProduct(period, startDate: startDate, endDate: endDate),
    ]);
    return (
      kpi: results[0] as ProductionKPI,
      byMachine: results[1] as ProductionByMachineResponse,
      byProduct: results[2] as ProductionByProductResponse,
    );
  }

  // ─────────────────────────────────────────
  // Xuất Excel → trả về bytes
  // ─────────────────────────────────────────
  Future<Uint8List> exportExcel(
    AnalyticsPeriod period,
    String exportType, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final params = _params(period, startDate, endDate);
      params['export_type'] = exportType;

      final res = await _dio.get(
        '$_base/export-excel',
        queryParameters: params,
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(res.data as List<int>);
    } catch (e) {
      throw Exception('Failed to export Excel: $e');
    }
  }
}
