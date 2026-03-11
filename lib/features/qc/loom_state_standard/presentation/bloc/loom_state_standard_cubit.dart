import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:owvds/features/qc/loom_state_standard/data/loom_state_standard_repository.dart';
import 'package:owvds/features/qc/loom_state_standard/domain/loom_state_standard_model.dart';
import 'package:file_picker/file_picker.dart';

abstract class StandardState {}

class StandardInitial extends StandardState {}

class StandardLoading extends StandardState {}

class StandardLoaded extends StandardState {
  final List<Standard> allStandards;
  final List<Standard> displayedStandards;

  // Lưu lại keyword để nếu thêm/sửa/xóa xong có thể gọi lại tìm kiếm
  final String? currentKeyword;

  StandardLoaded({
    required this.allStandards,
    required this.displayedStandards,
    this.currentKeyword,
  });
}

class StandardError extends StandardState {
  final String message;
  StandardError(this.message);
}

class StandardActionSuccess extends StandardState {
  final String message;
  StandardActionSuccess(this.message);
}

class StandardCubit extends Cubit<StandardState> {
  final StandardRepository _repo;
  List<Standard> _allStandardsCache = [];

  StandardCubit(this._repo) : super(StandardInitial());

  Future<void> loadStandards({
    bool forceRefresh = false,
    String? searchKeyword,
  }) async {
    emit(StandardLoading());
    try {
      if (_allStandardsCache.isEmpty || forceRefresh) {
        _allStandardsCache = await _repo.getStandards();
        // Sắp xếp ID giảm dần (mới nhất lên đầu)
        _allStandardsCache.sort((a, b) => b.standardId.compareTo(a.standardId));
      }

      List<Standard> displayed = _allStandardsCache;

      // Nếu có keyword đang được lưu, tiếp tục filter dựa trên cache
      if (searchKeyword != null && searchKeyword.isNotEmpty) {
        displayed = _allStandardsCache.where((std) {
          final kc = searchKeyword.toLowerCase();
          final pCode = std.product?.itemCode.toLowerCase() ?? '';
          final n = std.note?.toLowerCase() ?? '';
          final c = std.curved?.toLowerCase() ?? '';
          return pCode.contains(kc) || n.contains(kc) || c.contains(kc);
        }).toList();
      }

      emit(
        StandardLoaded(
          allStandards: _allStandardsCache,
          displayedStandards: displayed,
          currentKeyword: searchKeyword,
        ),
      );
    } catch (e) {
      emit(StandardError(e.toString()));
    }
  }

  Future<void> searchStandards(String keyword) async {
    if (keyword.trim().isEmpty) {
      loadStandards();
      return;
    }

    emit(StandardLoading());
    try {
      // Có thể gọi API search nếu bạn muốn search chính xác từ Server
      // final list = await _repo.searchStandards(keyword);
      // list.sort((a, b) => b.standardId.compareTo(a.standardId));

      // Hoặc search trên cache (tương tự như cách bạn hay làm)
      final kw = keyword.toLowerCase();
      final list = _allStandardsCache.where((std) {
        final pCode = std.product?.itemCode.toLowerCase() ?? '';
        final n = std.note?.toLowerCase() ?? '';
        final c = std.curved?.toLowerCase() ?? '';
        return pCode.contains(kw) || n.contains(kw) || c.contains(kw);
      }).toList();

      emit(
        StandardLoaded(
          allStandards: _allStandardsCache,
          displayedStandards: list,
          currentKeyword: keyword,
        ),
      );
    } catch (e) {
      emit(StandardError(e.toString()));
    }
  }

  Future<void> refreshCurrentState() async {
    String? currentSearch;
    if (state is StandardLoaded) {
      currentSearch = (state as StandardLoaded).currentKeyword;
    }
    await loadStandards(forceRefresh: true, searchKeyword: currentSearch);
  }

  Future<void> saveStandard({
    required Standard standard,
    required bool isEdit,
  }) async {
    try {
      emit(StandardLoading());
      if (isEdit) {
        await _repo.updateStandard(standard);
        emit(StandardActionSuccess("Cập nhật tiêu chuẩn thành công!"));
      } else {
        await _repo.createStandard(standard);
        emit(StandardActionSuccess("Tạo tiêu chuẩn thành công!"));
      }
      await refreshCurrentState();
    } catch (e) {
      emit(StandardError("Lỗi lưu tiêu chuẩn: $e"));
      await refreshCurrentState();
    }
  }

  Future<void> deleteStandard(int id) async {
    try {
      emit(StandardLoading());
      await _repo.deleteStandard(id);
      emit(StandardActionSuccess("Xóa tiêu chuẩn thành công!"));
      await refreshCurrentState();
    } catch (e) {
      emit(StandardError("Lỗi xóa: $e"));
      await refreshCurrentState();
    }
  }

  Future<void> importExcel(PlatformFile file) async {
    emit(StandardLoading());
    try {
      final result = await _repo.importExcel(file);
      if (result['errors'] != null && (result['errors'] as List).isNotEmpty) {
        emit(
          StandardError(
            "Đã import ${result['success_count']} dòng. Các lỗi:\n${(result['errors'] as List).join('\n')}",
          ),
        );
      } else {
        emit(
          StandardActionSuccess(
            "Nhập thành công ${result['success_count']} dòng.",
          ),
        );
      }
      await refreshCurrentState();
    } catch (e) {
      emit(StandardError(e.toString().replaceAll("Exception: ", "")));
      await refreshCurrentState();
    }
  }
}
