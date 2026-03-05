import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/material_type_repository.dart';
import '../../domain/material_type_model.dart';

// --- STATES ---
abstract class MaterialTypeState {}

class MaterialTypeInitial extends MaterialTypeState {}

class MaterialTypeLoading extends MaterialTypeState {}

class MaterialTypeLoaded extends MaterialTypeState {
  final List<MaterialType> types;
  final int totalCount;

  MaterialTypeLoaded({required this.types, required this.totalCount});
}

class MaterialTypeError extends MaterialTypeState {
  final String message;
  MaterialTypeError(this.message);
}

// --- CUBIT ---
class MaterialTypeCubit extends Cubit<MaterialTypeState> {
  final MaterialTypeRepository _repo;

  MaterialTypeCubit(this._repo) : super(MaterialTypeInitial());

  Future<void> loadTypes() async {
    emit(MaterialTypeLoading());
    try {
      final list = await _repo.getTypes();
      final total = await _repo.getTypeCount();
      emit(MaterialTypeLoaded(types: list, totalCount: total));
    } catch (e) {
      emit(MaterialTypeError(e.toString()));
    }
  }

  Future<void> searchTypes(String keyword) async {
    if (keyword.trim().isEmpty) {
      loadTypes();
      return;
    }
    emit(MaterialTypeLoading());
    try {
      final list = await _repo.getTypes(search: keyword);
      final total = list.length;
      emit(MaterialTypeLoaded(types: list, totalCount: total));
    } catch (e) {
      emit(MaterialTypeError(e.toString()));
    }
  }

  Future<void> addType(MaterialType type) async {
    try {
      await _repo.createType(type);
      loadTypes();
    } catch (e) {
      emit(MaterialTypeError(e.toString()));
    }
  }

  Future<void> updateType(MaterialType type) async {
    try {
      await _repo.updateType(type);
      loadTypes();
    } catch (e) {
      emit(MaterialTypeError(e.toString()));
    }
  }

  Future<void> deleteType(int id) async {
    try {
      await _repo.deleteType(id);
      loadTypes();
    } catch (e) {
      emit(MaterialTypeError(e.toString()));
    }
  }
}
