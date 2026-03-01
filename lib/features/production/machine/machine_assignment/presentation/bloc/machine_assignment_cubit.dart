import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/machine_assignment_repository.dart';
import '../../domain/machine_assignment_model.dart';

// --- STATES ---
abstract class MachineAssignmentState {}

class MachineAssignmentInitial extends MachineAssignmentState {}

class MachineAssignmentLoading extends MachineAssignmentState {}

class MachineAssignmentLoaded extends MachineAssignmentState {
  final MachineProductHistory? currentRunning;
  final List<MachineProductHistory>
  history; // Lịch sử hiện đang hiển thị trên UI (có thể đã bị filter)
  final List<MachineProductHistory>
  allHistory; // Backup lại toàn bộ lịch sử khi không search

  MachineAssignmentLoaded({
    required this.currentRunning,
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

  // [ĐÃ SỬA]: Xóa biến positional thừa, chỉ giữ lại named parameters trong ngoặc nhọn
  MachineAssignmentCubit({
    required MachineAssignmentRepository repo,
    required this.machineId,
  }) : _repo = repo,
       super(MachineAssignmentInitial());

  // Tải đồng thời cả Sản phẩm hiện tại và Lịch sử
  Future<void> loadMachineData() async {
    emit(MachineAssignmentLoading());
    try {
      final results = await Future.wait([
        _repo.getCurrentProduct(machineId),
        _repo.getHistory(machineId),
      ]);

      emit(
        MachineAssignmentLoaded(
          currentRunning: results[0] as MachineProductHistory?,
          history: results[1] as List<MachineProductHistory>,
          allHistory: results[1] as List<MachineProductHistory>, // Lưu backup
        ),
      );
    } catch (e) {
      emit(MachineAssignmentError("Lỗi tải dữ liệu sản xuất: $e"));
    }
  }

  Future<void> assignProduct(int productId, {String? notes}) async {
    emit(MachineAssignmentLoading());
    try {
      await _repo.assignProduct(machineId, productId, notes: notes);
      await loadMachineData();
    } catch (e) {
      emit(MachineAssignmentError("Không thể gán sản phẩm: $e"));
      await loadMachineData();
    }
  }

  Future<void> stopMachine() async {
    emit(MachineAssignmentLoading());
    try {
      await _repo.stopProduct(machineId);
      await loadMachineData();
    } catch (e) {
      emit(MachineAssignmentError("Lỗi dừng máy: $e"));
      await loadMachineData();
    }
  }

  // ==========================================
  // [MỚI] TÌM KIẾM, SỬA, XÓA TRÊN GIAO DIỆN
  // ==========================================

  Future<void> searchHistory(String keyword) async {
    if (state is! MachineAssignmentLoaded) return;
    final currentState = state as MachineAssignmentLoaded;

    if (keyword.trim().isEmpty) {
      // Trả lại danh sách gốc nếu xóa tìm kiếm
      emit(
        MachineAssignmentLoaded(
          currentRunning: currentState.currentRunning,
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
          currentRunning: currentState.currentRunning,
          history: filteredList, // Hiển thị list tìm kiếm
          allHistory: currentState.allHistory, // Giữ nguyên list gốc
        ),
      );
    } catch (e) {
      emit(MachineAssignmentError("Lỗi tìm kiếm lịch sử: $e"));
      await loadMachineData(); // Fallback
    }
  }

  Future<void> updateHistoryRecord(
    int historyId,
    Map<String, dynamic> updateData,
  ) async {
    emit(MachineAssignmentLoading());
    try {
      await _repo.updateHistory(historyId, updateData);
      await loadMachineData(); // Tải lại toàn bộ để cập nhật UI
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
