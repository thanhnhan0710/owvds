import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/material_inventory_repository.dart';
import '../../domain/material_inventory_model.dart';

abstract class MaterialInventoryState {}

class MaterialInventoryInitial extends MaterialInventoryState {}

class MaterialInventoryLoading extends MaterialInventoryState {}

class MaterialInventoryLoaded extends MaterialInventoryState {
  final List<MaterialInventory> inventories;
  MaterialInventoryLoaded(this.inventories);
}

class MaterialInventoryError extends MaterialInventoryState {
  final String message;
  MaterialInventoryError(this.message);
}

class MaterialInventoryCubit extends Cubit<MaterialInventoryState> {
  final MaterialInventoryRepository _repo;

  MaterialInventoryCubit(this._repo) : super(MaterialInventoryInitial());

  // [SỬA LỖI]: Phải khai báo {int? warehouseId} ở đây
  Future<void> loadInventories({
    int skip = 0,
    int limit = 100,
    int? warehouseId,
    int? materialId,
  }) async {
    emit(MaterialInventoryLoading());
    try {
      final list = await _repo.getInventories(
        skip: skip,
        limit: limit,
        warehouseId: warehouseId,
        materialId: materialId,
      );
      emit(MaterialInventoryLoaded(list));
    } catch (e) {
      emit(MaterialInventoryError(e.toString()));
    }
  }

  Future<void> searchInventories(String keyword) async {
    if (keyword.trim().isEmpty) {
      loadInventories();
      return;
    }
    emit(MaterialInventoryLoading());
    try {
      final list = await _repo.searchInventories(keyword);
      emit(MaterialInventoryLoaded(list));
    } catch (e) {
      emit(MaterialInventoryError(e.toString()));
    }
  }

  Future<void> saveInventory({
    required MaterialInventory inventory,
    required bool isEdit,
  }) async {
    try {
      if (isEdit) {
        await _repo.updateInventory(inventory);
      } else {
        await _repo.createInventory(inventory);
      }
      loadInventories();
    } catch (e) {
      emit(MaterialInventoryError("Failed to save material inventory: $e"));
    }
  }

  Future<void> deleteInventory(int id) async {
    try {
      await _repo.deleteInventory(id);
      loadInventories();
    } catch (e) {
      emit(MaterialInventoryError("Failed to delete: $e"));
    }
  }
}
