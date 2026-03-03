import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/work_schedule_repository.dart';
import '../../domain/work_schedule_model.dart';

abstract class WorkScheduleState {}
class WorkScheduleInitial extends WorkScheduleState {}
class WorkScheduleLoading extends WorkScheduleState {}
class WorkScheduleLoaded extends WorkScheduleState {
  final List<WorkSchedule> schedules;
  WorkScheduleLoaded(this.schedules);
}
class WorkScheduleError extends WorkScheduleState {
  final String message;
  WorkScheduleError(this.message);
}

class WorkScheduleCubit extends Cubit<WorkScheduleState> {
  final WorkScheduleRepository _repo;

  WorkScheduleCubit(this._repo) : super(WorkScheduleInitial());

  Future<void> loadSchedules() async {
    emit(WorkScheduleLoading());
    try {
      final list = await _repo.getSchedules();
      emit(WorkScheduleLoaded(list));
    } catch (e) {
      emit(WorkScheduleError(e.toString()));
    }
  }

  Future<void> searchSchedules(String keyword) async {
    if (keyword.trim().isEmpty) {
      loadSchedules();
      return;
    }
    emit(WorkScheduleLoading());
    try {
      final list = await _repo.searchSchedules(keyword);
      emit(WorkScheduleLoaded(list));
    } catch (e) {
      emit(WorkScheduleError(e.toString()));
    }
  }

  Future<void> saveSchedule({required WorkSchedule schedule, required bool isEdit}) async {
    try {
      if (isEdit) {
        await _repo.updateSchedule(schedule);
      } else {
        await _repo.createSchedule(schedule);
      }
      loadSchedules();
    } catch (e) {
      emit(WorkScheduleError("Failed to save data: $e"));
    }
  }

  Future<void> deleteSchedule(int id) async {
    try {
      await _repo.deleteSchedule(id);
      loadSchedules();
    } catch (e) {
      emit(WorkScheduleError("Failed to delete data: $e"));
    }
  }
}