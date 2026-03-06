import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/po_header_repository.dart';
import '../../domain/po_header_model.dart';

abstract class POHeaderState {}

class POHeaderInitial extends POHeaderState {}

class POHeaderLoading extends POHeaderState {}

class POHeaderLoaded extends POHeaderState {
  final List<PurchaseOrderHeader> pos;
  final int totalCount;
  POHeaderLoaded({required this.pos, required this.totalCount});
}

class POHeaderError extends POHeaderState {
  final String message;
  POHeaderError(this.message);
}

class POHeaderCubit extends Cubit<POHeaderState> {
  final POHeaderRepository _repo;

  int? _currentVendorId;
  int? _currentStatusId; // [MỚI]: Lưu vết bộ lọc trạng thái
  String? _currentSearch;

  POHeaderCubit(this._repo) : super(POHeaderInitial());

  String _parseError(dynamic e) {
    String msg = e.toString();
    if (msg.contains("409")) return "Số PO đã tồn tại trong hệ thống!";
    return msg.replaceAll("Exception: ", "");
  }

  Future<String> getNextPONumber() async {
    return await _repo.getNextPONumber();
  }

  // [ĐÃ SỬA]: Thêm tham số statusId
  Future<void> loadPOs({int? vendorId, int? statusId, String? search}) async {
    _currentVendorId = vendorId;
    _currentStatusId = statusId;
    _currentSearch = search;

    emit(POHeaderLoading());
    try {
      final list = await _repo.getPOs(
        vendorId: vendorId,
        statusId: statusId,
        search: search,
      );
      final total = await _repo.getPOCount(
        vendorId: vendorId,
        statusId: statusId,
        search: search,
      );
      emit(POHeaderLoaded(pos: list, totalCount: total));
    } catch (e) {
      emit(POHeaderError(_parseError(e)));
    }
  }

  Future<void> searchPOs(String keyword) async {
    await loadPOs(
      search: keyword.trim().isEmpty ? null : keyword.trim(),
      vendorId: _currentVendorId,
      statusId: _currentStatusId,
    );
  }

  // [MỚI]: Hàm lọc riêng theo trạng thái
  Future<void> filterByStatus(int? statusId) async {
    await loadPOs(
      search: _currentSearch,
      vendorId: _currentVendorId,
      statusId: statusId,
    );
  }

  Future<void> refreshCurrent() async {
    await loadPOs(
      vendorId: _currentVendorId,
      statusId: _currentStatusId,
      search: _currentSearch,
    );
  }

  Future<void> addPO(PurchaseOrderHeader po) async {
    try {
      await _repo.createPO(po);
      await refreshCurrent();
    } catch (e) {
      emit(POHeaderError(_parseError(e)));
      await Future.delayed(const Duration(milliseconds: 100));
      await refreshCurrent();
    }
  }

  Future<void> updatePO(PurchaseOrderHeader po) async {
    try {
      await _repo.updatePO(po);
      await refreshCurrent();
    } catch (e) {
      emit(POHeaderError(_parseError(e)));
      await Future.delayed(const Duration(milliseconds: 100));
      await refreshCurrent();
    }
  }

  Future<void> deletePO(int id) async {
    try {
      await _repo.deletePO(id);
      await refreshCurrent();
    } catch (e) {
      emit(POHeaderError(_parseError(e)));
      await Future.delayed(const Duration(milliseconds: 100));
      await refreshCurrent();
    }
  }
}
