import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/machine_assignment_repository.dart';
import '../../domain/machine_assignment_model.dart';

// --- STATES ---
abstract class MachineAssignmentState {}

class MachineAssignmentInitial extends MachineAssignmentState {}

class MachineAssignmentLoading extends MachineAssignmentState {}

class MachineAssignmentLoaded extends MachineAssignmentState {
  // [ĐÃ SỬA LỖI]: Đổi currentRunning thành danh sách currentRunningLines
  final List<MachineProductHistory> currentRunningLines;
  final List<MachineProductHistory> history;
  final List<MachineProductHistory> allHistory;

  MachineAssignmentLoaded({
    required this.currentRunningLines,
    required this.history,
    required this.allHistory,
  });
}

class MachineAssignmentError extends MachineAssignmentState {
  final String message;
  MachineAssignmentError(this.message);
}

// --- CUBIT ---
class MachineAssignmentCubit extends Cubit<MachineAssignmentState> {
  final MachineAssignmentRepository _repo;
  final int machineId;

  MachineAssignmentCubit({
    required MachineAssignmentRepository repo,
    required this.machineId,
  }) : _repo = repo,
       super(MachineAssignmentInitial());

  Future<void> loadMachineData() async {
    emit(MachineAssignmentLoading());
    try {
      final results = await Future.wait([
        _repo.getCurrentProductLines(machineId), // Lấy danh sách lines
        _repo.getHistory(machineId),
      ]);

      emit(
        MachineAssignmentLoaded(
          currentRunningLines: results[0] as List<MachineProductHistory>,
          history: results[1] as List<MachineProductHistory>,
          allHistory: results[1] as List<MachineProductHistory>,
        ),
      );
    } catch (e) {
      emit(MachineAssignmentError("Lỗi tải dữ liệu sản xuất: $e"));
    }
  }

  Future<void> assignProduct(
    int productId,
    int lineNumber, {
    String? notes,
  }) async {
    emit(MachineAssignmentLoading());
    try {
      await _repo.assignProduct(machineId, productId, lineNumber, notes: notes);
      await loadMachineData();
    } catch (e) {
      emit(MachineAssignmentError("Không thể gán sản phẩm: $e"));
      await loadMachineData();
    }
  }

  Future<void> stopMachine(int lineNumber) async {
    emit(MachineAssignmentLoading());
    try {
      await _repo.stopProduct(machineId, lineNumber);
      await loadMachineData();
    } catch (e) {
      emit(MachineAssignmentError("Lỗi dừng máy: $e"));
      await loadMachineData();
    }
  }

  Future<void> searchHistory(String keyword) async {
    if (state is! MachineAssignmentLoaded) return;
    final currentState = state as MachineAssignmentLoaded;

    if (keyword.trim().isEmpty) {
      emit(
        MachineAssignmentLoaded(
          currentRunningLines: currentState.currentRunningLines, // [ĐÃ SỬA]
          history: currentState.allHistory,
          allHistory: currentState.allHistory,
        ),
      );
      return;
    }

    emit(MachineAssignmentLoading());
    try {
      final filteredList = await _repo.searchHistory(machineId, keyword);
      emit(
        MachineAssignmentLoaded(
          currentRunningLines: currentState.currentRunningLines, // [ĐÃ SỬA]
          history: filteredList,
          allHistory: currentState.allHistory,
        ),
      );
    } catch (e) {
      emit(MachineAssignmentError("Lỗi tìm kiếm lịch sử: $e"));
      await loadMachineData();
    }
  }

  Future<void> updateHistoryRecord(
    int historyId,
    Map<String, dynamic> updateData,
  ) async {
    emit(MachineAssignmentLoading());
    try {
      await _repo.updateHistory(historyId, updateData);
      await loadMachineData();
    } catch (e) {
      emit(MachineAssignmentError("Lỗi cập nhật lịch sử: $e"));
      await loadMachineData();
    }
  }

  Future<void> deleteHistoryRecord(int historyId) async {
    emit(MachineAssignmentLoading());
    try {
      await _repo.deleteHistory(historyId);
      await loadMachineData();
    } catch (e) {
      emit(MachineAssignmentError("Lỗi xóa lịch sử: $e"));
      await loadMachineData();
    }
  }
}
