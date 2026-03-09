import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/warehouse_repository.dart';
import '../../domain/warehouse_model.dart';

// States
abstract class WarehouseState {}

class WarehouseInitial extends WarehouseState {}

class WarehouseLoading extends WarehouseState {}

class WarehouseLoaded extends WarehouseState {
  final List<Warehouse> warehouses;
  WarehouseLoaded(this.warehouses);
}

class WarehouseError extends WarehouseState {
  final String message;
  WarehouseError(this.message);
}

// Cubit
class WarehouseCubit extends Cubit<WarehouseState> {
  final WarehouseRepository _repo;

  WarehouseCubit(this._repo) : super(WarehouseInitial());

  // Load all
  Future<void> loadWarehouses() async {
    emit(WarehouseLoading());
    try {
      final list = await _repo.getWarehouses();
      emit(WarehouseLoaded(list));
    } catch (e) {
      emit(WarehouseError(e.toString()));
    }
  }

  // Search logic
  Future<void> searchWarehouses(String keyword) async {
    if (keyword.trim().isEmpty) {
      loadWarehouses();
      return;
    }
    emit(WarehouseLoading());
    try {
      final list = await _repo.searchWarehouses(keyword);
      emit(WarehouseLoaded(list));
    } catch (e) {
      emit(WarehouseError(e.toString()));
    }
  }

  // Create or Update
  Future<void> saveWarehouse({
    required Warehouse warehouse,
    required bool isEdit,
  }) async {
    try {
      // Vì Warehouse không có upload ảnh nên logic đơn giản hơn Employee
      if (isEdit) {
        await _repo.updateWarehouse(warehouse);
      } else {
        await _repo.createWarehouse(warehouse);
      }

      // Reload lại danh sách sau khi lưu thành công
      loadWarehouses();
    } catch (e) {
      emit(WarehouseError("Failed to save warehouse: $e"));
    }
  }

  // Delete
  Future<void> deleteWarehouse(int id) async {
    try {
      await _repo.deleteWarehouse(id);
      // Reload danh sách sau khi xóa
      loadWarehouses();
    } catch (e) {
      emit(WarehouseError("Failed to delete: $e"));
    }
  }
}