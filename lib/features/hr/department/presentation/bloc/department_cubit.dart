import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/department_repository.dart';
import '../../domain/department_model.dart';

// States
abstract class DepartmentState {}

class DepartmentInitial extends DepartmentState {}

class DepartmentLoading extends DepartmentState {}

class DepartmentLoaded extends DepartmentState {
  final List<Department> departments;
  final int totalCount; // [MỚI] Lưu tổng số phòng ban

  DepartmentLoaded({required this.departments, required this.totalCount});
}

class DepartmentError extends DepartmentState {
  final String message;
  DepartmentError(this.message);
}

// Cubit
class DepartmentCubit extends Cubit<DepartmentState> {
  final DepartmentRepository _repo;

  DepartmentCubit(this._repo) : super(DepartmentInitial());

  Future<void> loadDepartments() async {
    emit(DepartmentLoading());
    try {
      final list = await _repo.getDepartments();
      final total = await _repo.getDepartmentCount(); // [MỚI]
      emit(DepartmentLoaded(departments: list, totalCount: total));
    } catch (e) {
      emit(DepartmentError(e.toString()));
    }
  }

  Future<void> searchDepartments(String keyword) async {
    if (keyword.trim().isEmpty) {
      loadDepartments();
      return;
    }
    emit(DepartmentLoading());
    try {
      final list = await _repo.searchDepartments(keyword);
      final total = list.length; // Khi tìm kiếm, số lượng = kết quả trả về
      emit(DepartmentLoaded(departments: list, totalCount: total));
    } catch (e) {
      emit(DepartmentError(e.toString()));
    }
  }

  Future<void> addDepartment(Department dept) async {
    try {
      await _repo.createDepartment(dept);
      loadDepartments();
    } catch (e) {
      emit(DepartmentError(e.toString()));
    }
  }

  Future<void> updateDepartment(Department dept) async {
    try {
      await _repo.updateDepartment(dept);
      loadDepartments();
    } catch (e) {
      emit(DepartmentError(e.toString()));
    }
  }

  Future<void> deleteDepartment(int id) async {
    try {
      await _repo.deleteDepartment(id);
      loadDepartments();
    } catch (e) {
      emit(DepartmentError(e.toString()));
    }
  }
}
