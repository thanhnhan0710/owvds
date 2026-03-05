import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/employee_group_repository.dart';
import '../../domain/employee_group_model.dart';

// --- STATES ---
abstract class EmployeeGroupState {}

class EmployeeGroupInitial extends EmployeeGroupState {}

class EmployeeGroupLoading extends EmployeeGroupState {}

class EmployeeGroupLoaded extends EmployeeGroupState {
  final List<EmployeeGroup> groups;
  EmployeeGroupLoaded(this.groups);
}

class EmployeeGroupError extends EmployeeGroupState {
  final String message;
  EmployeeGroupError(this.message);
}

// --- CUBIT ---
class EmployeeGroupCubit extends Cubit<EmployeeGroupState> {
  final EmployeeGroupRepository _repo;

  EmployeeGroupCubit(this._repo) : super(EmployeeGroupInitial());

  // Load tất cả các tổ
  Future<void> loadGroups() async {
    emit(EmployeeGroupLoading());
    try {
      final list = await _repo.getGroups();
      emit(EmployeeGroupLoaded(list));
    } catch (e) {
      emit(EmployeeGroupError(e.toString()));
    }
  }

  // Load tổ theo ID phòng ban (Rất hữu ích khi chọn phòng ban xong thì chỉ hiển thị tổ của phòng đó)
  Future<void> loadGroupsByDepartment(int departmentId) async {
    emit(EmployeeGroupLoading());
    try {
      final list = await _repo.getGroupsByDepartment(departmentId);
      emit(EmployeeGroupLoaded(list));
    } catch (e) {
      emit(EmployeeGroupError(e.toString()));
    }
  }

  Future<void> searchGroups(String keyword) async {
    if (keyword.trim().isEmpty) {
      loadGroups();
      return;
    }
    emit(EmployeeGroupLoading());
    try {
      final list = await _repo.searchGroups(keyword);
      emit(EmployeeGroupLoaded(list));
    } catch (e) {
      emit(EmployeeGroupError(e.toString()));
    }
  }

  Future<void> saveGroup(EmployeeGroup group, {required bool isEdit}) async {
    try {
      if (isEdit) {
        await _repo.updateGroup(group);
      } else {
        await _repo.createGroup(group);
      }
      // Sau khi lưu thành công, tải lại danh sách
      await loadGroups();
    } catch (e) {
      emit(EmployeeGroupError(e.toString()));
    }
  }

  Future<void> deleteGroup(int id) async {
    try {
      await _repo.deleteGroup(id);
      await loadGroups();
    } catch (e) {
      emit(EmployeeGroupError(e.toString()));
    }
  }
}
