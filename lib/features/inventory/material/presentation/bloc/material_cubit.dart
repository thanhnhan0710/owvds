import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';

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

  // [MỚI] Lưu trữ các biến bộ lọc hiện tại để dùng lại khi Refresh
  int? _currentTypeId;
  int? _currentSupplierId;
  String? _currentSearch;
  int _currentSkip = 0;
  int _currentLimit = 20;

  MaterialCubit(this._repo) : super(MaterialInitial());

  Future<void> loadMaterials({
    int? typeId,
    int? supplierId,
    String? search,
    int skip = 0,
    int limit = 20,
  }) async {
    // Cập nhật lại bộ lọc hiện tại vào bộ nhớ của Cubit
    _currentTypeId = typeId;
    _currentSupplierId = supplierId;
    _currentSearch = search;
    _currentSkip = skip;
    _currentLimit = limit;

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

  // [MỚI] Hàm tiện ích để load lại đúng trang & bộ lọc đang hiển thị
  Future<void> refreshCurrentState() async {
    await loadMaterials(
      typeId: _currentTypeId,
      supplierId: _currentSupplierId,
      search: _currentSearch,
      skip: _currentSkip,
      limit: _currentLimit,
    );
  }

  Future<void> addMaterial(MaterialItem material) async {
    try {
      await _repo.createMaterial(material);
      // Thay vì loadMaterials() trống, ta gọi refreshCurrentState()
      await refreshCurrentState();
    } catch (e) {
      emit(MaterialError(e.toString()));
    }
  }

  Future<void> updateMaterial(MaterialItem material) async {
    try {
      await _repo.updateMaterial(material);
      await refreshCurrentState();
    } catch (e) {
      emit(MaterialError(e.toString()));
    }
  }

  Future<void> deleteMaterial(int id) async {
    try {
      await _repo.deleteMaterial(id);
      await refreshCurrentState();
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

      // Bắn state thành công ra cho UI
      emit(MaterialExportSuccess(bytes: bytes, fileName: "Danh_Muc_NVL.xlsx"));

      // Phục hồi lại state hiển thị danh sách
      if (currentState is MaterialLoaded) {
        emit(currentState);
      } else {
        await refreshCurrentState();
      }
    } catch (e) {
      emit(MaterialError(e.toString()));
    }
  }
}
