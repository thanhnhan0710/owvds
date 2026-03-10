import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/material_receipt_repository.dart';
import '../../domain/material_receipt_model.dart';

abstract class MaterialReceiptState {}

class MaterialReceiptInitial extends MaterialReceiptState {}

// [MỚI]: Trạng thái xuất file thành công
class MaterialReceiptExportSuccess extends MaterialReceiptState {
  final Uint8List bytes;
  final String fileName;
  MaterialReceiptExportSuccess({required this.bytes, required this.fileName});
}

class MaterialReceiptLoading extends MaterialReceiptState {}

class MaterialReceiptLoaded extends MaterialReceiptState {
  final List<MaterialReceipt> receipts;
  final String currentFilter;
  final int currentPage;
  final bool hasNextPage;

  MaterialReceiptLoaded({
    required this.receipts,
    required this.currentFilter,
    required this.currentPage,
    required this.hasNextPage,
  });
}

class MaterialReceiptError extends MaterialReceiptState {
  final String message;
  MaterialReceiptError(this.message);
}

class MaterialReceiptCubit extends Cubit<MaterialReceiptState> {
  final MaterialReceiptRepository _repo;

  // Trạng thái nội bộ để giữ context khi Reload/Websocket
  String _currentFilter = 'ALL';
  int _currentPage = 1;
  final int _pageSize = 20;

  // [ĐÃ SỬA LỖI]: Khai báo thêm biến lưu trữ ngày bắt đầu và kết thúc
  DateTime? _currentStartDate;
  DateTime? _currentEndDate;

  MaterialReceiptCubit(this._repo) : super(MaterialReceiptInitial());

  // Mặc định load TẤT CẢ khi mới vào màn hình
  Future<void> loadInitial() async {
    await applyFilter('ALL');
  }

  // Chuyển tab bộ lọc thời gian
  Future<void> applyFilter(String filterType) async {
    _currentFilter = filterType;
    _currentPage = 1; // Reset về trang 1 khi đổi bộ lọc
    await _fetchData();
  }

  // Chuyển trang (Next / Prev)
  Future<void> changePage(int newPage) async {
    if (newPage < 1) return;
    _currentPage = newPage;
    await _fetchData();
  }

  // Websocket gọi hàm này để âm thầm làm mới dữ liệu trang hiện tại
  Future<void> refreshCurrentView() async {
    await _fetchData(isRefresh: true);
  }

  Future<void> _fetchData({bool isRefresh = false}) async {
    if (!isRefresh) emit(MaterialReceiptLoading());

    try {
      DateTime now = DateTime.now();
      _currentEndDate = now;

      switch (_currentFilter) {
        case 'TODAY':
          _currentStartDate = DateTime(now.year, now.month, now.day);
          break;
        case 'WEEK':
          _currentStartDate = DateTime(
            now.year,
            now.month,
            now.day - (now.weekday - 1),
          );
          break;
        case 'MONTH':
          _currentStartDate = DateTime(now.year, now.month, 1);
          break;
        case 'QUARTER':
          int firstMonth = (((now.month - 1) / 3).floor() * 3) + 1;
          _currentStartDate = DateTime(now.year, firstMonth, 1);
          break;
        case 'YEAR':
          _currentStartDate = DateTime(now.year, 1, 1);
          break;
        case 'ALL':
        default:
          _currentStartDate = null;
          _currentEndDate = null;
          break;
      }

      int skip = (_currentPage - 1) * _pageSize;

      final list = await _repo.getReceipts(
        skip: skip,
        limit: _pageSize + 1,
        startDate: _currentStartDate?.toIso8601String(),
        endDate: _currentEndDate?.toIso8601String(),
      );

      bool hasNext = list.length > _pageSize;
      List<MaterialReceipt> displayList = hasNext
          ? list.sublist(0, _pageSize)
          : list;

      emit(
        MaterialReceiptLoaded(
          receipts: displayList,
          currentFilter: _currentFilter,
          currentPage: _currentPage,
          hasNextPage: hasNext,
        ),
      );
    } catch (e) {
      emit(MaterialReceiptError("Lỗi tải danh sách: $e"));
    }
  }

  // [MỚI]: Hàm Export Excel
  Future<void> exportExcel() async {
    try {
      final currentState = state;

      // Hiện loading nhẹ
      if (currentState is MaterialReceiptLoaded) emit(MaterialReceiptLoading());

      final bytes = await _repo.exportExcel(
        startDate: _currentStartDate?.toIso8601String(),
        endDate: _currentEndDate?.toIso8601String(),
      );

      // Trả file về cho giao diện xử lý (tải xuống)
      emit(
        MaterialReceiptExportSuccess(
          bytes: bytes,
          fileName: "DanhSachPhieuNhapKho",
        ),
      );

      // Phục hồi lại trạng thái cũ
      if (currentState is MaterialReceiptLoaded) {
        emit(currentState);
      } else {
        await refreshCurrentView();
      }
    } catch (e) {
      emit(MaterialReceiptError("Không thể xuất file Excel: $e"));
      await Future.delayed(const Duration(milliseconds: 500));
      await refreshCurrentView();
    }
  }

  // Thêm hoặc Cập nhật phiếu
  Future<void> saveReceipt(MaterialReceipt receipt, bool isEdit) async {
    try {
      if (isEdit) {
        await _repo.updateReceipt(receipt);
      } else {
        await _repo.createReceipt(receipt);
      }
      refreshCurrentView();
    } catch (e) {
      emit(MaterialReceiptError("Lỗi lưu phiếu: $e"));
    }
  }

  // Duyệt phiếu (Backend sẽ chốt số liệu tồn kho)
  Future<void> completeReceipt(MaterialReceipt receipt) async {
    try {
      final updated = receipt.copyWith(status: 'Completed');
      await _repo.updateReceipt(updated);
      refreshCurrentView();
    } catch (e) {
      emit(MaterialReceiptError("Lỗi duyệt phiếu: $e"));
    }
  }

  Future<void> deleteReceipt(int id) async {
    try {
      await _repo.deleteReceipt(id);
      refreshCurrentView();
    } catch (e) {
      emit(MaterialReceiptError("Lỗi xóa phiếu: $e"));
    }
  }
}
