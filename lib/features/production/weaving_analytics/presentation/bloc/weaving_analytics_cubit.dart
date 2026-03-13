// lib/features/production/weaving_analytics/presentation/weaving_analytics_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:owvds/features/production/weaving_analytics/data/weaving_analytics_repository.dart';
import 'package:owvds/features/production/weaving_analytics/domain/weaving_analytics_model.dart';

// ─────────────────────────────────────────
// STATES
// ─────────────────────────────────────────
abstract class WeavingAnalyticsState {}

class WeavingAnalyticsInitial extends WeavingAnalyticsState {}

class WeavingAnalyticsLoading extends WeavingAnalyticsState {}

class WeavingAnalyticsLoaded extends WeavingAnalyticsState {
  final ProductionKPI kpi;
  final ProductionByMachineResponse byMachine;
  final ProductionByProductResponse byProduct;
  final AnalyticsPeriod period;
  final DateTime? startDate;
  final DateTime? endDate;

  WeavingAnalyticsLoaded({
    required this.kpi,
    required this.byMachine,
    required this.byProduct,
    required this.period,
    this.startDate,
    this.endDate,
  });
}

class WeavingAnalyticsError extends WeavingAnalyticsState {
  final String message;
  WeavingAnalyticsError(this.message);
}

class WeavingAnalyticsExporting extends WeavingAnalyticsState {
  final WeavingAnalyticsLoaded previousState;
  WeavingAnalyticsExporting(this.previousState);
}

// ─────────────────────────────────────────
// CUBIT
// ─────────────────────────────────────────
class WeavingAnalyticsCubit extends Cubit<WeavingAnalyticsState> {
  final WeavingAnalyticsRepository _repo;

  WeavingAnalyticsCubit(this._repo) : super(WeavingAnalyticsInitial());

  // ── Load toàn bộ dữ liệu analytics ──
  Future<void> load({
    AnalyticsPeriod period = AnalyticsPeriod.day,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    emit(WeavingAnalyticsLoading());
    try {
      final data = await _repo.loadAll(
        period,
        startDate: startDate,
        endDate: endDate,
      );
      emit(
        WeavingAnalyticsLoaded(
          kpi: data.kpi,
          byMachine: data.byMachine,
          byProduct: data.byProduct,
          period: period,
          startDate: startDate,
          endDate: endDate,
        ),
      );
    } catch (e) {
      emit(WeavingAnalyticsError('Không thể tải dữ liệu: $e'));
    }
  }

  // ── Đổi bộ lọc và tải lại ──
  Future<void> changePeriod(
    AnalyticsPeriod period, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await load(period: period, startDate: startDate, endDate: endDate);
  }

  // ── Xuất Excel ──
  Future<void> exportExcel({
    required String exportType,
    required Function(List<int> bytes, String filename) onSuccess,
    required Function(String error) onError,
  }) async {
    final current = state;
    if (current is! WeavingAnalyticsLoaded) return;

    emit(WeavingAnalyticsExporting(current));

    try {
      final bytes = await _repo.exportExcel(
        current.period,
        exportType,
        startDate: current.startDate,
        endDate: current.endDate,
      );

      final periodVi =
          {
            'shift': 'Ca',
            'day': 'Ngay',
            'week': 'Tuan',
            'month': 'Thang',
            'year': 'Nam',
          }[current.period.value] ??
          current.period.value;

      final now = DateTime.now();
      final filename =
          'SanLuong_${periodVi}_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.xlsx';

      onSuccess(bytes, filename);
    } catch (e) {
      onError('Xuất Excel thất bại: $e');
    } finally {
      emit(current); // Quay lại trạng thái loaded
    }
  }
}
