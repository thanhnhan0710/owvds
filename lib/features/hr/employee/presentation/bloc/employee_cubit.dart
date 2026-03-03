import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/employee_repository.dart';
import '../../domain/employee_model.dart';
import 'package:file_saver/file_saver.dart';

// --- STATES ---
abstract class EmployeeState {}

class EmployeeInitial extends EmployeeState {}

class EmployeeLoading extends EmployeeState {}

class EmployeeLoaded extends EmployeeState {
  final List<Employee> employees;
  final int currentPage;
  final bool hasMore;
  final int totalCount; // [MỚI] Lưu tổng số lượng chính xác

  EmployeeLoaded({
    required this.employees,
    required this.currentPage,
    required this.hasMore,
    required this.totalCount,
  });
}

class EmployeeError extends EmployeeState {
  final String message;
  EmployeeError(this.message);
}

// --- CUBIT ---
class EmployeeCubit extends Cubit<EmployeeState> {
  final EmployeeRepository _repo;

  int _currentPage = 1;
  final int _pageSize = 20;
  String _currentKeyword = '';
  int? _currentDepartmentId;

  EmployeeCubit(this._repo) : super(EmployeeInitial());

  Future<void> loadPage(int page) async {
    emit(EmployeeLoading());
    _currentPage = page;
    try {
      final skip = (_currentPage - 1) * _pageSize;
      List<Employee> list;

      if (_currentDepartmentId != null) {
        list = await _repo.getEmployeesByDepartmentId(
          _currentDepartmentId!,
          skip: skip,
          limit: _pageSize,
        );
      } else if (_currentKeyword.isNotEmpty) {
        list = await _repo.searchEmployees(
          _currentKeyword,
          skip: skip,
          limit: _pageSize,
        );
      } else {
        list = await _repo.getEmployees(skip: skip, limit: _pageSize);
      }

      // [MỚI] Lấy con số chính xác tuyệt đối từ Database
      final exactTotal = await _repo.getEmployeeCount();

      emit(
        EmployeeLoaded(
          employees: list,
          currentPage: _currentPage,
          hasMore: list.length == _pageSize,
          totalCount: exactTotal,
        ),
      );
    } catch (e) {
      emit(EmployeeError(e.toString()));
    }
  }

  Future<void> loadEmployees() async {
    _currentDepartmentId = null;
    _currentKeyword = '';
    await loadPage(_currentPage);
  }

  Future<void> loadEmployeesByDepartment(int departmentId) async {
    _currentDepartmentId = departmentId;
    _currentKeyword = '';
    await loadPage(1);
  }

  Future<void> searchEmployees(String keyword) async {
    _currentKeyword = keyword.trim();
    _currentDepartmentId = null;
    await loadPage(1);
  }

  Future<void> saveEmployee({
    required Employee employee,
    PlatformFile? imageFile,
    required bool isEdit,
  }) async {
    try {
      String finalAvatarUrl = employee.avatarUrl;
      if (imageFile != null)
        finalAvatarUrl = await _repo.uploadAvatar(imageFile);

      final Employee finalEmployee = Employee(
        id: employee.id,
        fullName: employee.fullName,
        email: employee.email,
        phone: employee.phone,
        address: employee.address,
        position: employee.position,
        departmentId: employee.departmentId,
        note: employee.note,
        avatarUrl: finalAvatarUrl,
      );

      if (isEdit) {
        await _repo.updateEmployee(finalEmployee);
      } else {
        await _repo.createEmployee(finalEmployee);
      }

      await loadPage(_currentPage);
    } catch (e) {
      emit(EmployeeError("Failed to save employee: $e"));
      await loadPage(_currentPage);
    }
  }

  Future<void> deleteEmployee(int id) async {
    try {
      await _repo.deleteEmployee(id);
      await loadPage(_currentPage);
    } catch (e) {
      emit(EmployeeError(e.toString()));
      await loadPage(_currentPage);
    }
  }

  Future<void> importExcel(PlatformFile file) async {
    emit(EmployeeLoading());
    try {
      final result = await _repo.importExcel(file);
      await loadPage(1);
      if (result['errors'] != null && (result['errors'] as List).isNotEmpty) {
        emit(
          EmployeeError(
            "Đã import ${result['success_count']} dòng. Lỗi:\n${(result['errors'] as List).join('\n')}",
          ),
        );
      }
    } catch (e) {
      emit(EmployeeError(e.toString().replaceAll("Exception: ", "")));
      await loadPage(_currentPage);
    }
  }

  Future<void> exportExcel() async {
    try {
      final bytes = await _repo.exportExcel();
      await FileSaver.instance.saveFile(
        name: 'EMPLOYEES_${DateTime.now().millisecondsSinceEpoch}.xlsx',
        bytes: bytes,
        mimeType: MimeType.microsoftExcel,
      );
    } catch (e) {
      emit(
        EmployeeError(
          "Lỗi xuất file: ${e.toString().replaceAll("Exception: ", "")}",
        ),
      );
      await loadPage(_currentPage);
    }
  }
}
