import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/area_repository.dart';
import '../../domain/area_model.dart';

abstract class AreaState {}

class AreaInitial extends AreaState {}

class AreaLoading extends AreaState {}

class AreaLoaded extends AreaState {
  final List<Area> areas;
  AreaLoaded(this.areas);
}

class AreaError extends AreaState {
  final String message;
  AreaError(this.message);
}

class AreaCubit extends Cubit<AreaState> {
  final AreaRepository _repo;
  AreaCubit(this._repo) : super(AreaInitial());

  Future<void> loadAreas() async {
    emit(AreaLoading());
    try {
      final list = await _repo.getAreas();
      list.sort((a, b) => b.id.compareTo(a.id)); // Mới nhất lên đầu
      emit(AreaLoaded(list));
    } catch (e) {
      emit(AreaError(e.toString()));
    }
  }

  Future<void> searchAreas(String keyword) async {
    if (keyword.trim().isEmpty) return loadAreas();
    emit(AreaLoading());
    try {
      final list = await _repo.searchAreas(keyword);
      list.sort((a, b) => b.id.compareTo(a.id));
      emit(AreaLoaded(list));
    } catch (e) {
      emit(AreaError(e.toString()));
    }
  }

  Future<void> saveArea({required Area area, required bool isEdit}) async {
    try {
      isEdit ? await _repo.updateArea(area) : await _repo.createArea(area);
      loadAreas();
    } catch (e) {
      emit(AreaError("Lỗi lưu khu vực: $e"));
    }
  }

  Future<void> deleteArea(int id) async {
    try {
      await _repo.deleteArea(id);
      loadAreas();
    } catch (e) {
      emit(AreaError("Lỗi xóa: $e"));
    }
  }
}
