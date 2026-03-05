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
  final int totalCount;

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

  // Trạng thái lưu bộ lọc
  String _currentKeyword = '';
  int? _currentDepartmentId;
  int? _currentGroupId; // [MỚI] Thêm biến lưu group_id

  EmployeeCubit(this._repo) : super(EmployeeInitial());

  Future<void> loadPage(int page) async {
    emit(EmployeeLoading());
    _currentPage = page;
    try {
      final skip = (_currentPage - 1) * _pageSize;
      List<Employee> list;

      // Ưu tiên chạy bộ lọc theo thứ tự cụ thể hơn: Từ khóa -> Tổ -> Bộ phận
      if (_currentKeyword.isNotEmpty) {
        list = await _repo.searchEmployees(
          _currentKeyword,
          skip: skip,
          limit: _pageSize,
        );
      } else if (_currentGroupId != null) {
        // [MỚI] Lọc theo Tổ
        list = await _repo.getEmployeesByGroup(
          _currentGroupId!,
          skip: skip,
          limit: _pageSize,
        );
      } else if (_currentDepartmentId != null) {
        list = await _repo.getEmployeesByDepartmentId(
          _currentDepartmentId!,
          skip: skip,
          limit: _pageSize,
        );
      } else {
        list = await _repo.getEmployees(skip: skip, limit: _pageSize);
      }

      // Lấy con số chính xác tuyệt đối từ Database (Tính năng cũ bạn yêu cầu)
      // *Lưu ý: Nếu lọc theo Bộ phận/Tổ, số count này cần phải được API BE xử lý lại
      // để đếm chính xác số NV trong bộ phận/tổ đó thay vì toàn xưởng.
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
    _currentGroupId = null; // Reset Group
    _currentKeyword = '';
    await loadPage(_currentPage);
  }

  Future<void> loadEmployeesByDepartment(int departmentId) async {
    _currentDepartmentId = departmentId;
    _currentGroupId = null; // Chọn bộ phận thì reset Tổ
    _currentKeyword = '';
    await loadPage(1);
  }

  // ===========================================
  // [MỚI] Hàm Load nhân viên theo Tổ
  // ===========================================
  Future<void> loadEmployeesByGroup(int groupId) async {
    _currentGroupId = groupId;
    _currentKeyword = '';
    // Lưu ý: Không cần reset _currentDepartmentId để biết đang ở Bộ phận nào
    await loadPage(1);
  }

  Future<void> searchEmployees(String keyword) async {
    _currentKeyword = keyword.trim();
    _currentDepartmentId = null;
    _currentGroupId = null;
    await loadPage(1);
  }

  Future<void> saveEmployee({
    required Employee employee,
    PlatformFile? imageFile,
    required bool isEdit,
  }) async {
    try {
      String finalAvatarUrl = employee.avatarUrl;
      if (imageFile != null) {
        finalAvatarUrl = await _repo.uploadAvatar(imageFile);
      }

      final Employee finalEmployee = Employee(
        id: employee.id,
        fullName: employee.fullName,
        email: employee.email,
        phone: employee.phone,
        address: employee.address,
        position: employee.position,
        departmentId: employee.departmentId,
        groupId: employee.groupId, // [MỚI] Gửi cả groupId lên
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
