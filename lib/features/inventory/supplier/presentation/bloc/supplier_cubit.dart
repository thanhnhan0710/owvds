import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/supplier_repository.dart';
import '../../domain/supplier_model.dart';

// --- STATES ---
abstract class SupplierState {}

class SupplierInitial extends SupplierState {}

class SupplierLoading extends SupplierState {}

class SupplierLoaded extends SupplierState {
  final List<Supplier> suppliers;
  final int totalCount;

  SupplierLoaded({required this.suppliers, required this.totalCount});
}

class SupplierError extends SupplierState {
  final String message;
  SupplierError(this.message);
}

// --- CUBIT ---
class SupplierCubit extends Cubit<SupplierState> {
  final SupplierRepository _repo;

  SupplierCubit(this._repo) : super(SupplierInitial());

  Future<void> loadSuppliers({int? categoryId, bool? isActive}) async {
    emit(SupplierLoading());
    try {
      final list = await _repo.getSuppliers(
        categoryId: categoryId,
        isActive: isActive,
      );
      final total = await _repo.getSupplierCount();
      emit(SupplierLoaded(suppliers: list, totalCount: total));
    } catch (e) {
      emit(SupplierError(e.toString()));
    }
  }

  Future<void> searchSuppliers(
    String keyword, {
    int? categoryId,
    bool? isActive,
  }) async {
    if (keyword.trim().isEmpty) {
      loadSuppliers(categoryId: categoryId, isActive: isActive);
      return;
    }
    emit(SupplierLoading());
    try {
      final list = await _repo.getSuppliers(
        search: keyword,
        categoryId: categoryId,
        isActive: isActive,
      );
      final total = list.length;
      emit(SupplierLoaded(suppliers: list, totalCount: total));
    } catch (e) {
      emit(SupplierError(e.toString()));
    }
  }

  Future<void> addSupplier(Supplier supplier) async {
    try {
      await _repo.createSupplier(supplier);
      loadSuppliers();
    } catch (e) {
      emit(SupplierError(e.toString()));
    }
  }

  Future<void> updateSupplier(Supplier supplier) async {
    try {
      await _repo.updateSupplier(supplier);
      loadSuppliers();
    } catch (e) {
      emit(SupplierError(e.toString()));
    }
  }

  Future<void> deleteSupplier(int id) async {
    try {
      await _repo.deleteSupplier(id);
      loadSuppliers();
    } catch (e) {
      emit(SupplierError(e.toString()));
    }
  }
}
