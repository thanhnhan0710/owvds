import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_saver/file_saver.dart'; // Yêu cầu package: file_saver
import 'package:intl/intl.dart';
import '../../data/material_export_repository.dart';
import '../../domain/material_export_model.dart';

// --- STATES ---
abstract class MaterialExportState {}

class MaterialExportInitial extends MaterialExportState {}

class MaterialExportLoading extends MaterialExportState {}

class MaterialExportLoaded extends MaterialExportState {
  final List<MaterialExport> exports;
  final bool hasMore;
  final int currentPage;

  MaterialExportLoaded({
    required this.exports,
    required this.hasMore,
    required this.currentPage,
  });
}

class MaterialExportError extends MaterialExportState {
  final String message;
  MaterialExportError(this.message);
}

class MaterialExportActionSuccess extends MaterialExportState {
  final String message;
  MaterialExportActionSuccess(this.message);
}

// --- CUBIT ---
class MaterialExportCubit extends Cubit<MaterialExportState> {
  final MaterialExportRepository _repository;

  // Trạng thái bộ lọc nội bộ
  final int _pageSize = 20;
  String? _searchQuery;
  int? _warehouseId;
  int? _exporterId;
  int? _receiverId;
  String? _fromDate;
  String? _toDate;

  MaterialExportCubit(this._repository) : super(MaterialExportInitial());

  // Đặt bộ lọc và tự động tải lại từ trang 1
  void setFilters({
    String? search,
    int? warehouseId,
    int? exporterId,
    int? receiverId,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    _searchQuery = search;
    _warehouseId = warehouseId;
    _exporterId = exporterId;
    _receiverId = receiverId;
    _fromDate = fromDate != null
        ? DateFormat('yyyy-MM-dd').format(fromDate)
        : null;
    _toDate = toDate != null ? DateFormat('yyyy-MM-dd').format(toDate) : null;

    loadExports(isRefresh: true);
  }

  // Tải danh sách
  Future<void> loadExports({bool isRefresh = false}) async {
    try {
      int skip = 0;
      int page = 1;
      List<MaterialExport> currentList = [];

      if (!isRefresh && state is MaterialExportLoaded) {
        final currentState = state as MaterialExportLoaded;
        if (!currentState.hasMore) return; // Hết dữ liệu thì không tải nữa
        page = currentState.currentPage + 1;
        skip = currentState.exports.length;
        currentList = currentState.exports;
      }

      // Vẫn báo loading nếu là refresh hoặc lần đầu
      if (isRefresh || state is! MaterialExportLoaded) {
        emit(MaterialExportLoading());
      }

      final newData = await _repository.getExports(
        skip: skip,
        limit: _pageSize,
        search: _searchQuery,
        warehouseId: _warehouseId,
        exporterId: _exporterId,
        receiverId: _receiverId,
        fromDate: _fromDate,
        toDate: _toDate,
      );

      final combinedList = isRefresh ? newData : [...currentList, ...newData];

      emit(
        MaterialExportLoaded(
          exports: combinedList,
          currentPage: page,
          hasMore:
              newData.length ==
              _pageSize, // Nếu trả về đủ số lượng limit nghĩa là có thể còn trang sau
        ),
      );
    } catch (e) {
      emit(MaterialExportError("Không thể tải danh sách xuất kho: $e"));
    }
  }

  // Lấy mã phiếu tự động để hiển thị lên Form tạo mới
  Future<String> getNextCode() async {
    try {
      return await _repository.getNextExportCode();
    } catch (e) {
      return "AUTO";
    }
  }

  // Tạo phiếu xuất
  Future<void> createExport(MaterialExportRequest request) async {
    emit(MaterialExportLoading());
    try {
      await _repository.createExport(request);
      emit(MaterialExportActionSuccess("Tạo phiếu xuất kho thành công"));
      loadExports(isRefresh: true); // Reload lại danh sách sau khi tạo
    } catch (e) {
      emit(MaterialExportError("Lỗi tạo phiếu xuất: $e"));
      loadExports(isRefresh: true); // Trả lại state loaded nếu lỗi
    }
  }

  // Cập nhật phiếu
  Future<void> updateExport(int id, Map<String, dynamic> updateData) async {
    emit(MaterialExportLoading());
    try {
      await _repository.updateExport(id, updateData);
      emit(MaterialExportActionSuccess("Cập nhật phiếu xuất thành công"));
      loadExports(isRefresh: true);
    } catch (e) {
      emit(MaterialExportError("Lỗi cập nhật: $e"));
      loadExports(isRefresh: true);
    }
  }

  // Xóa/Hủy phiếu
  Future<void> deleteExport(int id) async {
    emit(MaterialExportLoading());
    try {
      await _repository.deleteExport(id);
      emit(
        MaterialExportActionSuccess(
          "Hủy phiếu xuất thành công. Đã hoàn trả tồn kho.",
        ),
      );
      loadExports(isRefresh: true);
    } catch (e) {
      emit(MaterialExportError("Lỗi hủy phiếu: $e"));
      loadExports(isRefresh: true);
    }
  }

  // Xuất file Excel
  Future<void> downloadExcel() async {
    try {
      final bytes = await _repository.exportExcel(
        search: _searchQuery,
        warehouseId: _warehouseId,
        exporterId: _exporterId,
        receiverId: _receiverId,
        fromDate: _fromDate,
        toDate: _toDate,
      );

      final fileName =
          'DanhSachXuatKho_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';

      await FileSaver.instance.saveFile(
        name: fileName,
        bytes: bytes,
        mimeType: MimeType.microsoftExcel,
      );
    } catch (e) {
      emit(MaterialExportError("Không thể tải file Excel: $e"));
      // Quay lại state cũ
      loadExports(isRefresh: false);
    }
  }
}
