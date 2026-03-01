import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/machine_type_repository.dart';
import '../../domain/machine_type_model.dart';

abstract class MachineTypeState {}

class MachineTypeInitial extends MachineTypeState {}

class MachineTypeLoading extends MachineTypeState {}

class MachineTypeLoaded extends MachineTypeState {
  final List<MachineType> types;
  MachineTypeLoaded(this.types);
}

class MachineTypeError extends MachineTypeState {
  final String message;
  MachineTypeError(this.message);
}

class MachineTypeCubit extends Cubit<MachineTypeState> {
  final MachineTypeRepository _repo;
  MachineTypeCubit(this._repo) : super(MachineTypeInitial());

  Future<void> loadTypes() async {
    emit(MachineTypeLoading());
    try {
      final list = await _repo.getTypes();
      list.sort((a, b) => b.id.compareTo(a.id));
      emit(MachineTypeLoaded(list));
    } catch (e) {
      emit(MachineTypeError(e.toString()));
    }
  }

  Future<void> searchTypes(String keyword) async {
    if (keyword.trim().isEmpty) return loadTypes();
    emit(MachineTypeLoading());
    try {
      final list = await _repo.searchTypes(keyword);
      list.sort((a, b) => b.id.compareTo(a.id));
      emit(MachineTypeLoaded(list));
    } catch (e) {
      emit(MachineTypeError(e.toString()));
    }
  }

  Future<void> saveType({
    required MachineType type,
    required bool isEdit,
  }) async {
    try {
      isEdit ? await _repo.updateType(type) : await _repo.createType(type);
      loadTypes();
    } catch (e) {
      emit(MachineTypeError(e.toString()));
    }
  }

  Future<void> deleteType(int id) async {
    try {
      await _repo.deleteType(id);
      loadTypes();
    } catch (e) {
      emit(MachineTypeError(e.toString()));
    }
  }
}
