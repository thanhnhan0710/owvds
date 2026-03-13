import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:owvds/features/log/data/log_repository.dart';
import 'package:owvds/features/log/domain/log_model.dart';

// ==============================
// 1. STATES
// ==============================
abstract class LogState {}

class LogInitial extends LogState {}

class LogLoading extends LogState {}

class LogLoaded extends LogState {
  final List<LogModel> logs;
  LogLoaded(this.logs);
}

class LogError extends LogState {
  final String message;
  LogError(this.message);
}

class LogRevertSuccess extends LogState {
  final String message;
  LogRevertSuccess(this.message);
}

// ==============================
// 2. CUBIT LOGIC
// ==============================
class LogCubit extends Cubit<LogState> {
  final LogRepository _repo;

  // Lưu trữ các bộ lọc hiện tại để không bị mất khi load lại danh sách sau khi Revert
  String? _lastTargetType;
  int? _lastTargetId;
  DateTime? _lastFromDate;
  DateTime? _lastToDate;

  LogCubit(this._repo) : super(LogInitial());

  // Hàm tải danh sách log
  Future<void> loadLogs({
    String? targetType,
    int? targetId,
    DateTime? fromDate,
    DateTime? toDate,
    bool useCacheFilter = false, // Cờ báo hiệu dùng lại bộ lọc cũ
  }) async {
    // Nếu không yêu cầu dùng cache, cập nhật lại biến lưu trữ bộ lọc
    if (!useCacheFilter) {
      _lastTargetType = targetType;
      _lastTargetId = targetId;
      _lastFromDate = fromDate;
      _lastToDate = toDate;
    }

    emit(LogLoading());
    try {
      final logs = await _repo.getLogs(
        targetType: _lastTargetType,
        targetId: _lastTargetId,
        fromDate: _lastFromDate,
        toDate: _lastToDate,
      );
      emit(LogLoaded(logs));
    } catch (e) {
      emit(LogError(e.toString().replaceAll("Exception: ", "")));
    }
  }

  // Hàm hoàn tác / khôi phục log
  Future<void> revertLogItem(int logId) async {
    final currentState = state; // Lưu state hiện tại (thường là LogLoaded)

    try {
      // Gọi API hoàn tác
      final resultMessage = await _repo.revertLog(logId);

      // Phát trạng thái thành công để UI (BlocConsumer listener) hiện SnackBar
      emit(LogRevertSuccess(resultMessage));

      // Đợi 1 nhịp siêu nhỏ (100ms) để UI kịp bắt sự kiện Listener
      await Future.delayed(const Duration(milliseconds: 100));

      // Tự động tải lại danh sách bằng bộ lọc đã lưu (useCacheFilter = true)
      await loadLogs(useCacheFilter: true);
    } catch (e) {
      // Phát trạng thái lỗi để UI hiện thông báo
      emit(LogError(e.toString().replaceAll("Exception: ", "")));

      // Đợi 1 nhịp để UI bắt lỗi
      await Future.delayed(const Duration(milliseconds: 100));

      // Khôi phục lại danh sách cũ đang xem để tránh màn hình bị trắng bóc
      if (currentState is LogLoaded) {
        emit(currentState);
      } else {
        await loadLogs(useCacheFilter: true);
      }
    }
  }
}
