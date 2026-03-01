import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/machine_status_repository.dart';
import '../../domain/machine_status_model.dart';

abstract class MachineStatusState {}

class MachineStatusInitial extends MachineStatusState {}

class MachineStatusLoading extends MachineStatusState {}

class MachineStatusLoaded extends MachineStatusState {
  final List<MachineStatus> statuses;
  MachineStatusLoaded(this.statuses);
}

class MachineStatusError extends MachineStatusState {
  final String message;
  MachineStatusError(this.message);
}

class MachineStatusCubit extends Cubit<MachineStatusState> {
  final MachineStatusRepository _repo;
  MachineStatusCubit(this._repo) : super(MachineStatusInitial());

  Future<void> loadStatuses() async {
    emit(MachineStatusLoading());
    try {
      final list = await _repo.getStatuses();
      list.sort((a, b) => b.id.compareTo(a.id));
      emit(MachineStatusLoaded(list));
    } catch (e) {
      emit(MachineStatusError(e.toString()));
    }
  }

  // [CẬP NHẬT] Gọi hàm search từ Repository thay vì lọc nội bộ
  Future<void> searchStatuses(String keyword) async {
    if (keyword.trim().isEmpty) return loadStatuses();
    emit(MachineStatusLoading());
    try {
      final list = await _repo.searchStatuses(keyword);
      list.sort((a, b) => b.id.compareTo(a.id));
      emit(MachineStatusLoaded(list));
    } catch (e) {
      emit(MachineStatusError(e.toString()));
    }
  }

  Future<void> saveStatus({
    required MachineStatus status,
    required bool isEdit,
  }) async {
    try {
      isEdit
          ? await _repo.updateStatus(status)
          : await _repo.createStatus(status);
      loadStatuses();
    } catch (e) {
      emit(MachineStatusError(e.toString()));
    }
  }

  Future<void> deleteStatus(int id) async {
    try {
      await _repo.deleteStatus(id);
      loadStatuses();
    } catch (e) {
      emit(MachineStatusError(e.toString()));
    }
  }
}
