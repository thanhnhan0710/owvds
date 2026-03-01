import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:owvds/features/production/machine/machine_assignment/data/machine_assignment_repository.dart';
import 'package:owvds/features/production/machine/machine_assignment/domain/machine_assignment_model.dart';

abstract class GlobalAssignmentState {}

class GlobalAssignmentInitial extends GlobalAssignmentState {}

class GlobalAssignmentLoading extends GlobalAssignmentState {}

class GlobalAssignmentLoaded extends GlobalAssignmentState {
  final Map<int, MachineProductHistory> activeAssignments;
  final List<MachineProductHistory> globalHistory;

  GlobalAssignmentLoaded({
    required this.activeAssignments,
    required this.globalHistory,
  });
}

class GlobalAssignmentError extends GlobalAssignmentState {
  final String message;
  GlobalAssignmentError(this.message);
}

class GlobalAssignmentCubit extends Cubit<GlobalAssignmentState> {
  final MachineAssignmentRepository _repo;

  GlobalAssignmentCubit(this._repo) : super(GlobalAssignmentInitial());

  Future<void> loadDashboardData({String? historyKeyword}) async {
    emit(GlobalAssignmentLoading());
    try {
      final results = await Future.wait([
        _repo.getAllActiveAssignments(),
        _repo.getGlobalHistory(keyword: historyKeyword),
      ]);

      // ignore: unnecessary_cast
      final activeList = results[0] as List<MachineProductHistory>;
      // ignore: unnecessary_cast
      final historyList = results[1] as List<MachineProductHistory>;

      final Map<int, MachineProductHistory> activeMap = {};
      for (var record in activeList) {
        activeMap[record.machineId] = record;
      }

      emit(
        GlobalAssignmentLoaded(
          activeAssignments: activeMap,
          globalHistory: historyList,
        ),
      );
    } catch (e) {
      emit(GlobalAssignmentError("Lỗi tải dữ liệu điều độ: $e"));
    }
  }

  Future<void> assignProduct(
    int machineId,
    int productId, {
    String? notes,
  }) async {
    try {
      await _repo.assignProduct(machineId, productId, notes: notes);
      await loadDashboardData();
    } catch (e) {
      emit(GlobalAssignmentError("Lỗi gán mã: $e"));
      await loadDashboardData();
    }
  }

  // ==========================================
  // [MỚI] HÀM GÁN HÀNG LOẠT (BATCH ASSIGNMENT)
  // ==========================================
  Future<void> assignProductToMultipleMachines(
    List<int> machineIds,
    int productId, {
    String? notes,
  }) async {
    emit(GlobalAssignmentLoading());
    try {
      // Dùng Future.wait để bắn API gán đồng loạt cho nhiều máy cùng lúc
      await Future.wait(
        machineIds.map(
          (id) => _repo.assignProduct(id, productId, notes: notes),
        ),
      );
      await loadDashboardData(); // Tải lại giao diện sau khi gán xong
    } catch (e) {
      emit(GlobalAssignmentError("Lỗi gán mã hàng loạt: $e"));
      await loadDashboardData();
    }
  }

  Future<void> stopMachine(int machineId) async {
    try {
      await _repo.stopProduct(machineId);
      await loadDashboardData();
    } catch (e) {
      emit(GlobalAssignmentError("Lỗi dừng máy: $e"));
      await loadDashboardData();
    }
  }

  Future<void> updateHistory(
    int historyId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      await _repo.updateHistory(historyId, updateData);
      await loadDashboardData();
    } catch (e) {
      emit(GlobalAssignmentError("Lỗi cập nhật lịch sử: $e"));
      await loadDashboardData();
    }
  }

  Future<void> deleteHistory(int historyId) async {
    try {
      await _repo.deleteHistory(historyId);
      await loadDashboardData();
    } catch (e) {
      emit(GlobalAssignmentError("Lỗi xóa lịch sử: $e"));
      await loadDashboardData();
    }
  }
}
