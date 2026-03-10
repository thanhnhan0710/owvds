import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:owvds/features/production/machine/machine_assignment/data/machine_assignment_repository.dart';
import 'package:owvds/features/production/machine/machine_assignment/domain/machine_assignment_model.dart';

abstract class GlobalAssignmentState {}

class GlobalAssignmentInitial extends GlobalAssignmentState {}

class GlobalAssignmentLoading extends GlobalAssignmentState {}

class GlobalAssignmentLoaded extends GlobalAssignmentState {
  final Map<int, List<MachineProductHistory>> activeAssignments;
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

      final activeList = results[0] as List<MachineProductHistory>;
      final historyList = results[1] as List<MachineProductHistory>;

      final Map<int, List<MachineProductHistory>> activeMap = {};
      for (var record in activeList) {
        if (!activeMap.containsKey(record.machineId)) {
          activeMap[record.machineId] = [];
        }
        activeMap[record.machineId]!.add(record);
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
    int productId,
    int lineNumber, {
    String? notes,
  }) async {
    try {
      await _repo.assignProduct(machineId, productId, lineNumber, notes: notes);
      await loadDashboardData();
    } catch (e) {
      emit(GlobalAssignmentError("Lỗi gán mã: $e"));
      await loadDashboardData();
    }
  }

  // [ĐÃ CẢI TIẾN]: Nhận Map chứa danh sách Line của từng máy
  Future<void> assignProductToMultipleMachines(
    Map<int, Set<int>> machineLines,
    int productId, {
    String? notes,
  }) async {
    emit(GlobalAssignmentLoading());
    try {
      List<Future> tasks = [];

      // Duyệt qua từng máy và từng line được chọn để tạo các tác vụ gọi API
      machineLines.forEach((machineId, lines) {
        for (var lineNumber in lines) {
          tasks.add(
            _repo.assignProduct(machineId, productId, lineNumber, notes: notes),
          );
        }
      });

      await Future.wait(tasks); // Chạy đồng loạt tất cả các line
      await loadDashboardData();
    } catch (e) {
      emit(GlobalAssignmentError("Lỗi gán mã hàng loạt: $e"));
      await loadDashboardData();
    }
  }

  Future<void> stopMachine(int machineId, int lineNumber) async {
    try {
      await _repo.stopProduct(machineId, lineNumber);
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
