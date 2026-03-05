import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:owvds/features/inventory/supplier_category/data/supplier_category_repository.dart';
import '../../domain/supplier_category_model.dart';

// --- STATES ---
abstract class SupplierCategoryState {}

class SupplierCategoryInitial extends SupplierCategoryState {}

class SupplierCategoryLoading extends SupplierCategoryState {}

class SupplierCategoryLoaded extends SupplierCategoryState {
  final List<SupplierCategory> categories;
  final int totalCount;

  SupplierCategoryLoaded({required this.categories, required this.totalCount});
}

class SupplierCategoryError extends SupplierCategoryState {
  final String message;
  SupplierCategoryError(this.message);
}

// --- CUBIT ---
class SupplierCategoryCubit extends Cubit<SupplierCategoryState> {
  final SupplierCategoryRepository _repo;

  SupplierCategoryCubit(this._repo) : super(SupplierCategoryInitial());

  Future<void> loadCategories() async {
    emit(SupplierCategoryLoading());
    try {
      final list = await _repo.getCategories();
      final total = await _repo.getCategoryCount();
      emit(SupplierCategoryLoaded(categories: list, totalCount: total));
    } catch (e) {
      emit(SupplierCategoryError(e.toString()));
    }
  }

  Future<void> searchCategories(String keyword) async {
    if (keyword.trim().isEmpty) {
      loadCategories();
      return;
    }
    emit(SupplierCategoryLoading());
    try {
      final list = await _repo.getCategories(search: keyword);
      final total = list.length;
      emit(SupplierCategoryLoaded(categories: list, totalCount: total));
    } catch (e) {
      emit(SupplierCategoryError(e.toString()));
    }
  }

  Future<void> addCategory(SupplierCategory category) async {
    try {
      await _repo.createCategory(category);
      loadCategories();
    } catch (e) {
      emit(SupplierCategoryError(e.toString()));
    }
  }

  Future<void> updateCategory(SupplierCategory category) async {
    try {
      await _repo.updateCategory(category);
      loadCategories();
    } catch (e) {
      emit(SupplierCategoryError(e.toString()));
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      await _repo.deleteCategory(id);
      loadCategories();
    } catch (e) {
      emit(SupplierCategoryError(e.toString()));
    }
  }
}
