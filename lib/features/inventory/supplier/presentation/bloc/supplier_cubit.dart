import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/supplier_repository.dart';
import '../../domain/supplier_model.dart';

// --- STATES ---
abstract class SupplierState {}

class SupplierInitial extends SupplierState {}

class SupplierLoading extends SupplierState {}

class SupplierLoaded extends SupplierState {
  final List<Supplier> suppliers;
  final int totalCount;

  SupplierLoaded({required this.suppliers, required this.totalCount});
}

class SupplierError extends SupplierState {
  final String message;
  SupplierError(this.message);
}

// --- CUBIT ---
class SupplierCubit extends Cubit<SupplierState> {
  final SupplierRepository _repo;

  // [MỚI] Lưu trữ các biến bộ lọc hiện tại để không bị mất khi Thêm/Sửa/Xóa
  int? _currentCategoryId;
  bool? _currentIsActive;
  String? _currentSearchKeyword;

  SupplierCubit(this._repo) : super(SupplierInitial());

  Future<void> loadSuppliers({
    int? categoryId,
    bool? isActive,
    String? search,
  }) async {
    // Lưu lại bộ lọc
    _currentCategoryId = categoryId;
    _currentIsActive = isActive;
    _currentSearchKeyword = search;

    emit(SupplierLoading());
    try {
      final list = await _repo.getSuppliers(
        categoryId: categoryId,
        isActive: isActive,
        search: search,
      );

      // [SỬA LỖI HIỂN THỊ SỐ 0]: Lấy trực tiếp độ dài danh sách trả về để an toàn tuyệt đối
      int total = list.length;

      emit(SupplierLoaded(suppliers: list, totalCount: total));
    } catch (e) {
      emit(SupplierError(e.toString()));
    }
  }

  // Gom chung logic search vào loadSuppliers để đồng bộ State
  Future<void> searchSuppliers(
    String keyword, {
    int? categoryId,
    bool? isActive,
  }) async {
    await loadSuppliers(
      search: keyword.trim().isEmpty ? null : keyword.trim(),
      categoryId: categoryId,
      isActive: isActive,
    );
  }

  // [MỚI] Hàm tải lại đúng trang & đúng danh mục đang chọn
  Future<void> refreshCurrentState() async {
    await loadSuppliers(
      categoryId: _currentCategoryId,
      isActive: _currentIsActive,
      search: _currentSearchKeyword,
    );
  }

  Future<void> addSupplier(Supplier supplier) async {
    try {
      await _repo.createSupplier(supplier);
      await refreshCurrentState(); // Gọi lại trang hiện tại thay vì loadSuppliers() trống
    } catch (e) {
      emit(SupplierError(e.toString()));
    }
  }

  Future<void> updateSupplier(Supplier supplier) async {
    try {
      await _repo.updateSupplier(supplier);
      await refreshCurrentState();
    } catch (e) {
      emit(SupplierError(e.toString()));
    }
  }

  Future<void> deleteSupplier(int id) async {
    try {
      await _repo.deleteSupplier(id);
      await refreshCurrentState();
    } catch (e) {
      emit(SupplierError(e.toString()));
    }
  }
}
