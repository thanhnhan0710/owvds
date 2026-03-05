import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
// Note: Bạn có thể cần import file_saver hoặc universal_html tùy vào nền tảng để lưu file
// import 'package:file_saver/file_saver.dart';

import '../../data/material_repository.dart';
import '../../domain/material_model.dart';

// --- STATES ---
abstract class MaterialState {}

class MaterialInitial extends MaterialState {}

class MaterialLoading extends MaterialState {}

class MaterialLoaded extends MaterialState {
  final List<MaterialItem> materials;
  final int totalCount;

  MaterialLoaded({required this.materials, required this.totalCount});
}

class MaterialError extends MaterialState {
  final String message;
  MaterialError(this.message);
}

// State riêng cho việc báo hiệu tải Excel thành công
class MaterialExportSuccess extends MaterialState {
  final Uint8List bytes;
  final String fileName;
  MaterialExportSuccess({required this.bytes, required this.fileName});
}

// --- CUBIT ---
class MaterialCubit extends Cubit<MaterialState> {
  final MaterialRepository _repo;

  MaterialCubit(this._repo) : super(MaterialInitial());

  Future<void> loadMaterials({
    int? typeId,
    int? supplierId,
    String? search,
    int skip = 0,
    int limit = 20,
  }) async {
    emit(MaterialLoading());
    try {
      final list = await _repo.getMaterials(
        typeId: typeId,
        supplierId: supplierId,
        search: search,
        skip: skip,
        limit: limit,
      );
      final total = await _repo.getMaterialCount();
      emit(MaterialLoaded(materials: list, totalCount: total));
    } catch (e) {
      emit(MaterialError(e.toString()));
    }
  }

  Future<void> searchMaterials(
    String keyword, {
    int? typeId,
    int? supplierId,
  }) async {
    // Chuyển việc xử lý sang hàm loadMaterials
    await loadMaterials(
      search: keyword,
      typeId: typeId,
      supplierId: supplierId,
    );
  }

  Future<void> addMaterial(MaterialItem material) async {
    try {
      await _repo.createMaterial(material);
      loadMaterials();
    } catch (e) {
      emit(MaterialError(e.toString()));
    }
  }

  Future<void> updateMaterial(MaterialItem material) async {
    try {
      await _repo.updateMaterial(material);
      loadMaterials();
    } catch (e) {
      emit(MaterialError(e.toString()));
    }
  }

  Future<void> deleteMaterial(int id) async {
    try {
      await _repo.deleteMaterial(id);
      loadMaterials();
    } catch (e) {
      emit(MaterialError(e.toString()));
    }
  }

  // Hàm gọi Export Excel
  Future<void> exportExcel({int? typeId, int? supplierId}) async {
    try {
      // Giữ lại state cũ để UI không bị giật lag khi đang tải
      final currentState = state;

      final bytes = await _repo.exportExcel(
        typeId: typeId,
        supplierId: supplierId,
      );

      // Bắn state thành công ra cho UI (UI sẽ dùng BlocListener để hiện dialog Save File)
      emit(MaterialExportSuccess(bytes: bytes, fileName: "Danh_Muc_NVL.xlsx"));

      // Phục hồi lại state hiển thị danh sách
      if (currentState is MaterialLoaded) {
        emit(currentState);
      } else {
        loadMaterials(typeId: typeId, supplierId: supplierId);
      }
    } catch (e) {
      emit(MaterialError(e.toString()));
    }
  }
}
