import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/po_status_repository.dart';
import '../../domain/po_status_model.dart';

abstract class POStatusState {}

class POStatusInitial extends POStatusState {}

class POStatusLoading extends POStatusState {}

class POStatusLoaded extends POStatusState {
  final List<POStatus> statuses;
  POStatusLoaded({required this.statuses});
}

class POStatusError extends POStatusState {
  final String message;
  POStatusError(this.message);
}

class POStatusCubit extends Cubit<POStatusState> {
  final POStatusRepository _repo;

  POStatusCubit(this._repo) : super(POStatusInitial());

  String _parseError(dynamic e) {
    String msg = e.toString();
    if (msg.contains("409")) return "Mã Trạng thái đã tồn tại!";
    return msg.replaceAll("Exception: ", "");
  }

  Future<void> loadStatuses() async {
    emit(POStatusLoading());
    try {
      final list = await _repo.getStatuses();
      emit(POStatusLoaded(statuses: list));
    } catch (e) {
      emit(POStatusError(_parseError(e)));
    }
  }

  Future<void> searchStatuses(String keyword) async {
    emit(POStatusLoading());
    try {
      final list = await _repo.getStatuses(search: keyword.trim());
      emit(POStatusLoaded(statuses: list));
    } catch (e) {
      emit(POStatusError(_parseError(e)));
    }
  }

  Future<void> addStatus(POStatus status) async {
    try {
      await _repo.createStatus(status);
      await loadStatuses();
    } catch (e) {
      emit(POStatusError(_parseError(e)));
      await Future.delayed(const Duration(milliseconds: 100));
      await loadStatuses();
    }
  }

  Future<void> updateStatus(POStatus status) async {
    try {
      await _repo.updateStatus(status);
      await loadStatuses();
    } catch (e) {
      emit(POStatusError(_parseError(e)));
      await Future.delayed(const Duration(milliseconds: 100));
      await loadStatuses();
    }
  }

  Future<void> deleteStatus(int id) async {
    try {
      await _repo.deleteStatus(id);
      await loadStatuses();
    } catch (e) {
      emit(POStatusError(_parseError(e)));
      await Future.delayed(const Duration(milliseconds: 100));
      await loadStatuses();
    }
  }
}
