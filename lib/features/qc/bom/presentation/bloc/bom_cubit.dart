import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/bom_repository.dart';

import '../../domain/bom_model.dart';

// --- STATES ---
abstract class BOMState {}

class BOMInitial extends BOMState {}

class BOMLoading extends BOMState {}

class BOMListLoaded extends BOMState {
  final List<BOMHeader> boms;
  BOMListLoaded(this.boms);
}

// [CẬP NHẬT] State chi tiết bao gồm cả BOMHeader và Summary
class BOMDetailViewLoaded extends BOMState {
  final BOMHeader bom;
  final List<BOMMaterialSummary> summary; // Danh sách số cuộn
  BOMDetailViewLoaded(this.bom, {this.summary = const []});
}

class BOMOperationSuccess extends BOMState {
  final String message;
  BOMOperationSuccess(this.message);
}

class BOMError extends BOMState {
  final String message;
  BOMError(this.message);
}

// --- CUBIT ---
class BOMCubit extends Cubit<BOMState> {
  final BOMRepository _repo;

  BOMCubit(this._repo) : super(BOMInitial());

  // Load danh sách
  Future<void> loadBOMHeaders({String? productCode, int? year}) async {
    emit(BOMLoading());
    try {
      final list = await _repo.getBOMs(productCode: productCode, year: year);
      emit(BOMListLoaded(list));
    } catch (e) {
      emit(BOMError(e.toString()));
    }
  }

  // Search
  Future<void> searchBOMs(String keyword) async {
    emit(BOMLoading());
    try {
      final list = await _repo.searchBOMs(keyword);
      emit(BOMListLoaded(list));
    } catch (e) {
      emit(BOMError(e.toString()));
    }
  }

  // [CẬP NHẬT] Load chi tiết (Gọi cả BOM và Summary)
  Future<void> loadBOMDetailView(int id) async {
    emit(BOMLoading());
    try {
      // Chạy song song 2 request để tối ưu tốc độ
      final results =
          await Future.wait([_repo.getBOMById(id), _repo.getBOMSummary(id)]);

      final bom = results[0] as BOMHeader;
      final summary = results[1] as List<BOMMaterialSummary>;

      emit(BOMDetailViewLoaded(bom, summary: summary));
    } catch (e) {
      emit(BOMError(e.toString()));
    }
  }

  // Save Header
  Future<void> saveBOMHeader(
      {required BOMHeader bom, required bool isEdit}) async {
    emit(BOMLoading());
    try {
      if (isEdit) {
        await _repo.updateBOM(bom);
      } else {
        await _repo.createBOM(bom);
      }
      emit(BOMOperationSuccess(
          isEdit ? "Cập nhật thành công" : "Tạo BOM thành công"));
      loadBOMHeaders();
    } catch (e) {
      final msg = e.toString().replaceAll("Exception: ", "");
      emit(BOMError(msg));
    }
  }

  // Save Detail
  Future<void> saveBOMDetail(BOMDetail detail, bool isEdit) async {
    final currentState = state;
    if (currentState is BOMDetailViewLoaded) {
      final currentBOM = currentState.bom;
      // Giữ lại summary cũ tạm thời để UI không bị giật
      final currentSummary = currentState.summary;
      emit(BOMLoading());

      try {
        List<BOMDetail> updatedDetails = List.from(currentBOM.bomDetails);

        if (isEdit) {
          final index =
              updatedDetails.indexWhere((d) => d.detailId == detail.detailId);
          if (index != -1) updatedDetails[index] = detail;
        } else {
          updatedDetails.add(detail);
        }

        final newBOMHeader = BOMHeader(
          bomId: currentBOM.bomId,
          productId: currentBOM.productId,
          applicableYear: currentBOM.applicableYear,
          displayName: currentBOM.displayName,
          targetWeightGm: currentBOM.targetWeightGm,
          totalScrapRate: currentBOM.totalScrapRate,
          totalShrinkageRate: currentBOM.totalShrinkageRate,
          widthBehindLoom: currentBOM.widthBehindLoom,
          picks: currentBOM.picks,
          version: currentBOM.version,
          isActive: currentBOM.isActive,
          bomDetails: updatedDetails,
        );

        await _repo.updateBOM(newBOMHeader);
        await loadBOMDetailView(
            currentBOM.bomId); // Reload để cập nhật tính toán & summary
      } catch (e) {
        final msg = e.toString().replaceAll("Exception: ", "");
        emit(BOMError("Lỗi lưu chi tiết: $msg"));
        emit(BOMDetailViewLoaded(currentBOM, summary: currentSummary));
      }
    }
  }

  // Delete Detail
  Future<void> deleteBOMDetail(int detailId, int bomId) async {
    final currentState = state;
    if (currentState is BOMDetailViewLoaded) {
      final currentBOM = currentState.bom;
      final currentSummary = currentState.summary;
      emit(BOMLoading());

      try {
        List<BOMDetail> updatedDetails = List.from(currentBOM.bomDetails);
        updatedDetails.removeWhere((d) => d.detailId == detailId);

        final newBOMHeader = BOMHeader(
          bomId: currentBOM.bomId,
          productId: currentBOM.productId,
          applicableYear: currentBOM.applicableYear,
          displayName: currentBOM.displayName,
          targetWeightGm: currentBOM.targetWeightGm,
          totalScrapRate: currentBOM.totalScrapRate,
          totalShrinkageRate: currentBOM.totalShrinkageRate,
          widthBehindLoom: currentBOM.widthBehindLoom,
          picks: currentBOM.picks,
          version: currentBOM.version,
          isActive: currentBOM.isActive,
          bomDetails: updatedDetails,
        );

        await _repo.updateBOM(newBOMHeader);
        await loadBOMDetailView(bomId);
      } catch (e) {
        emit(BOMError("Lỗi xóa chi tiết: $e"));
        emit(BOMDetailViewLoaded(currentBOM, summary: currentSummary));
      }
    }
  }

  // Delete Header
  Future<void> deleteBOMHeader(int id) async {
    try {
      await _repo.deleteBOM(id);
      loadBOMHeaders();
    } catch (e) {
      emit(BOMError(e.toString()));
    }
  }

  // [MỚI] Import file
  Future<void> importExcel(PlatformFile file, int applicableYear) async {
    emit(BOMLoading());
    try {
      final result = await _repo.importBOMExcel(file, applicableYear);

      // Load lại list ngay sau khi xong
      await loadBOMHeaders();

      // Nếu API trả về list những dòng không import được
      if (result['errors'] != null && (result['errors'] as List).isNotEmpty) {
        final errList = (result['errors'] as List).join('\n');
        emit(BOMError(
            "Đã import ${result['success_count']} BOM. Bỏ qua các lỗi sau:\n$errList"));
      } else {
        emit(BOMOperationSuccess("Nhập file Excel BOM thành công!"));
      }
    } catch (e) {
      emit(BOMError(e.toString().replaceAll("Exception: ", "")));
      loadBOMHeaders(); // Dù lỗi cũng refresh lại lỡ có record nào thành công
    }
  }

  Future<void> exportExcel() async {
    try {
      final bytes = await _repo.exportExcel();

      await FileSaver.instance.saveFile(
        name: 'BOM YARN${DateTime.now().millisecondsSinceEpoch}.xlsx',
        bytes: bytes,
        mimeType: MimeType.microsoftExcel,
      );
      // Optional: Có thể emit thông báo thành công nếu muốn
      emit(BOMOperationSuccess("Xuất file BOM thành công!"));
    } catch (e) {
      emit(BOMError(
          "Lỗi xuất file: ${e.toString().replaceAll("Exception: ", "")}"));
    }
  }
}
