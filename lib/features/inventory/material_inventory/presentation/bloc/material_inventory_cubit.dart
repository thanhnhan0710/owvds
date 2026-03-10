import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:typed_data';
import '../../data/material_inventory_repository.dart';
import '../../domain/material_inventory_model.dart';

abstract class MaterialInventoryState {}

class MaterialInventoryInitial extends MaterialInventoryState {}

class MaterialInventoryLoading extends MaterialInventoryState {}

// State chứa đầy đủ dữ liệu hiển thị (Có thêm cờ isLowStockFilter)
class MaterialInventoryLoaded extends MaterialInventoryState {
  final List<MaterialInventory> inventories;
  final int currentPage;
  final bool hasNextPage;
  final bool isLowStockFilter;

  MaterialInventoryLoaded({
    required this.inventories,
    required this.currentPage,
    required this.hasNextPage,
    required this.isLowStockFilter,
  });
}

class MaterialInventoryError extends MaterialInventoryState {
  final String message;
  MaterialInventoryError(this.message);
}

class MaterialInventoryExportSuccess extends MaterialInventoryState {
  final Uint8List bytes;
  final String fileName;
  MaterialInventoryExportSuccess({required this.bytes, required this.fileName});
}

class MaterialInventoryCubit extends Cubit<MaterialInventoryState> {
  final MaterialInventoryRepository _repo;

  // Các biến lưu trạng thái của bộ lọc và phân trang
  int? _currentWarehouseId;
  String _currentKeyword = '';
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _isLowStock = false; // Trạng thái bộ lọc "Sắp hết hàng"

  MaterialInventoryCubit(this._repo) : super(MaterialInventoryInitial());

  // Load mặc định
  Future<void> loadInventories({
    int? warehouseId,
    bool isRefresh = false,
  }) async {
    if (warehouseId != _currentWarehouseId) {
      _currentWarehouseId = warehouseId;
      _currentPage = 1; // Reset về trang 1 nếu đổi kho
    }
    _currentKeyword = '';
    await _fetchData(isRefresh: isRefresh);
  }

  // Tìm kiếm
  Future<void> searchInventories(String keyword) async {
    _currentKeyword = keyword;
    _currentPage = 1; // Reset về trang 1 khi search mới
    await _fetchData();
  }

  // Bật/tắt bộ lọc Sắp hết hàng
  Future<void> toggleLowStockFilter(bool value) async {
    _isLowStock = value;
    _currentPage = 1;
    await _fetchData();
  }

  // Chuyển trang
  Future<void> changePage(int newPage) async {
    if (newPage < 1) return;
    _currentPage = newPage;
    await _fetchData(
      isRefresh: true,
    ); // isRefresh = true để không hiện loading toàn màn hình
  }

  // Hàm gọi API cốt lõi xử lý skip/limit
  Future<void> _fetchData({bool isRefresh = false}) async {
    if (!isRefresh) emit(MaterialInventoryLoading());

    try {
      int skip = (_currentPage - 1) * _pageSize;
      List<MaterialInventory> list;

      if (_currentKeyword.trim().isNotEmpty) {
        // Phân trang Local cho kết quả Search
        final searchList = await _repo.searchInventories(_currentKeyword);

        // Tự động lọc local nếu đang bật cờ "Sắp hết hàng"
        list = searchList;

        bool hasNext = list.length > skip + _pageSize;
        var displayList = list.skip(skip).take(_pageSize).toList();

        emit(
          MaterialInventoryLoaded(
            inventories: displayList,
            currentPage: _currentPage,
            hasNextPage: hasNext,
            isLowStockFilter: _isLowStock,
          ),
        );
        return;
      }

      // Phân trang Database (Lấy dư 1 phần tử để check xem có trang tiếp theo không)
      list = await _repo.getInventories(
        skip: skip,
        limit: _pageSize + 1,
        warehouseId: _currentWarehouseId,
        isLowStock: _isLowStock,
      );

      bool hasNext = list.length > _pageSize;
      List<MaterialInventory> displayList = hasNext
          ? list.sublist(0, _pageSize)
          : list;

      emit(
        MaterialInventoryLoaded(
          inventories: displayList,
          currentPage: _currentPage,
          hasNextPage: hasNext,
          isLowStockFilter: _isLowStock,
        ),
      );
    } catch (e) {
      emit(MaterialInventoryError(e.toString()));
    }
  }

  // Xuất Excel
  Future<void> exportExcel() async {
    try {
      final currentState = state;
      if (currentState is MaterialInventoryLoaded)
        emit(MaterialInventoryLoading());

      final bytes = await _repo.exportExcel(
        warehouseId: _currentWarehouseId,
        isLowStock: _isLowStock,
      );

      emit(
        MaterialInventoryExportSuccess(bytes: bytes, fileName: "BaoCaoTonKho"),
      );

      // Phục hồi lại danh sách sau khi xuất xong
      if (currentState is MaterialInventoryLoaded) {
        emit(currentState);
      } else {
        await _fetchData(isRefresh: true);
      }
    } catch (e) {
      emit(MaterialInventoryError("Không thể xuất file Excel: $e"));
      await Future.delayed(const Duration(milliseconds: 500));
      await _fetchData(isRefresh: true);
    }
  }

  // Sửa/Cập nhật tồn kho
  Future<void> saveInventory({
    required MaterialInventory inventory,
    required bool isEdit,
  }) async {
    try {
      if (isEdit) {
        await _repo.updateInventory(inventory);
      } else {
        await _repo.createInventory(inventory);
      }
      await _fetchData(isRefresh: true);
    } catch (e) {
      emit(MaterialInventoryError("Lỗi lưu tồn kho: $e"));
    }
  }

  // Thêm tồn kho đầu kỳ
  Future<void> initStock(Map<String, dynamic> data) async {
    try {
      await _repo.initStock(data);
      await _fetchData(isRefresh: true);
    } catch (e) {
      emit(MaterialInventoryError("Lỗi thêm tồn kho: $e"));
      await Future.delayed(const Duration(seconds: 1));
      await _fetchData(isRefresh: true);
    }
  }

  // Xóa
  Future<void> deleteInventory(int id) async {
    try {
      await _repo.deleteInventory(id);
      await _fetchData(isRefresh: true);
    } catch (e) {
      emit(MaterialInventoryError("Lỗi xóa tồn kho: $e"));
    }
  }
}
