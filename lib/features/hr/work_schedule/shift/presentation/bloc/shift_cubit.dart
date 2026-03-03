import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/shift_repository.dart';
import '../../domain/shift_model.dart';

abstract class ShiftState {}
class ShiftInitial extends ShiftState {}
class ShiftLoading extends ShiftState {}
class ShiftLoaded extends ShiftState {
  final List<Shift> shifts;
  ShiftLoaded(this.shifts);
}
class ShiftError extends ShiftState {
  final String message;
  ShiftError(this.message);
}

class ShiftCubit extends Cubit<ShiftState> {
  final ShiftRepository _repo;

  ShiftCubit(this._repo) : super(ShiftInitial());

  Future<void> loadShifts() async {
    emit(ShiftLoading());
    try {
      final list = await _repo.getShifts();
      emit(ShiftLoaded(list));
    } catch (e) {
      emit(ShiftError(e.toString()));
    }
  }

  Future<void> searchShifts(String keyword) async {
    if (keyword.trim().isEmpty) {
      loadShifts();
      return;
    }
    emit(ShiftLoading());
    try {
      final list = await _repo.searchShifts(keyword);
      emit(ShiftLoaded(list));
    } catch (e) {
      emit(ShiftError(e.toString()));
    }
  }

  Future<void> saveShift({required Shift shift, required bool isEdit}) async {
    try {
      if (isEdit) {
        await _repo.updateShift(shift);
      } else {
        await _repo.createShift(shift);
      }
      loadShifts();
    } catch (e) {
      emit(ShiftError("Failed to save data: $e"));
    }
  }

  Future<void> deleteShift(int id) async {
    try {
      await _repo.deleteShift(id);
      loadShifts();
    } catch (e) {
      emit(ShiftError("Failed to delete data: $e"));
    }
  }
}