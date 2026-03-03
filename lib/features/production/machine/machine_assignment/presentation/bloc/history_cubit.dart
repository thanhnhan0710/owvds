import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_saver/file_saver.dart';
import 'package:owvds/features/production/machine/machine_assignment/data/machine_assignment_repository.dart';
import 'package:owvds/features/production/machine/machine_assignment/domain/machine_assignment_model.dart';

abstract class HistoryState {}

class HistoryInitial extends HistoryState {}

class HistoryLoading extends HistoryState {}

class HistoryLoaded extends HistoryState {
  final List<MachineProductHistory> records;
  final int currentPage;
  final bool hasMore; // Kiểm tra xem còn trang sau không

  HistoryLoaded({
    required this.records,
    required this.currentPage,
    required this.hasMore,
  });
}

class HistoryError extends HistoryState {
  final String message;
  HistoryError(this.message);
}

class HistoryCubit extends Cubit<HistoryState> {
  final MachineAssignmentRepository _repo;
  final int? specificMachineId; // Nếu null => Là Lịch sử Global

  final int _pageSize = 20;
  String? _keyword;
  String? _startDate;
  String? _endDate;

  HistoryCubit(this._repo, {this.specificMachineId}) : super(HistoryInitial());

  // Đặt bộ lọc thời gian
  void setDateFilter(DateTime? start, DateTime? end) {
    _startDate = start?.toIso8601String();
    _endDate = end?.toIso8601String();
    loadPage(1); // Tự động load lại từ trang 1 khi đổi ngày
  }

  void setKeyword(String kw) {
    _keyword = kw.trim().isEmpty ? null : kw;
    loadPage(1);
  }

  Future<void> loadPage(int page) async {
    emit(HistoryLoading());
    try {
      final skip = (page - 1) * _pageSize;
      List<MachineProductHistory> data;

      if (specificMachineId != null) {
        data = await _repo.getHistory(
          specificMachineId!,
          skip: skip,
          limit: _pageSize,
          startDate: _startDate,
          endDate: _endDate,
        );
      } else {
        data = await _repo.getGlobalHistory(
          keyword: _keyword,
          skip: skip,
          limit: _pageSize,
          startDate: _startDate,
          endDate: _endDate,
        );
      }

      emit(
        HistoryLoaded(
          records: data,
          currentPage: page,
          hasMore:
              data.length ==
              _pageSize, // Nếu trả về đủ 20 dòng -> có thể còn trang sau
        ),
      );
    } catch (e) {
      emit(HistoryError("Lỗi tải lịch sử: $e"));
    }
  }

  Future<void> exportExcel() async {
    try {
      final bytes = specificMachineId != null
          ? await _repo.exportSingleMachineHistory(
              specificMachineId!,
              startDate: _startDate,
              endDate: _endDate,
            )
          : await _repo.exportGlobalHistory(
              keyword: _keyword,
              startDate: _startDate,
              endDate: _endDate,
            );

      final fileName = specificMachineId != null
          ? 'LichSu_May_$specificMachineId'
          : 'LichSu_ToanXuong';

      await FileSaver.instance.saveFile(
        name: '${fileName}_${DateTime.now().millisecondsSinceEpoch}.xlsx',
        bytes: bytes,
        mimeType: MimeType.microsoftExcel,
      );
    } catch (e) {
      emit(HistoryError("Lỗi xuất Excel: $e"));
      await loadPage(
        (state is HistoryLoaded) ? (state as HistoryLoaded).currentPage : 1,
      );
    }
  }
}
