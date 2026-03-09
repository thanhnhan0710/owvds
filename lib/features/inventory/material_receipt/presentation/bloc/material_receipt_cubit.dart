import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/material_receipt_repository.dart';
import '../../domain/material_receipt_model.dart';

abstract class MaterialReceiptState {}

class MaterialReceiptInitial extends MaterialReceiptState {}

class MaterialReceiptLoading extends MaterialReceiptState {}

class MaterialReceiptLoaded extends MaterialReceiptState {
  final List<MaterialReceipt> receipts;
  MaterialReceiptLoaded(this.receipts);
}

class MaterialReceiptError extends MaterialReceiptState {
  final String message;
  MaterialReceiptError(this.message);
}

class MaterialReceiptCubit extends Cubit<MaterialReceiptState> {
  final MaterialReceiptRepository _repo;

  MaterialReceiptCubit(this._repo) : super(MaterialReceiptInitial());

  Future<void> loadReceipts() async {
    emit(MaterialReceiptLoading());
    try {
      final list = await _repo.getReceipts();
      emit(MaterialReceiptLoaded(list));
    } catch (e) {
      emit(MaterialReceiptError(e.toString()));
    }
  }

  Future<void> searchReceipts(String keyword) async {
    if (keyword.trim().isEmpty) {
      loadReceipts();
      return;
    }
    emit(MaterialReceiptLoading());
    try {
      final list = await _repo.searchReceipts(keyword);
      emit(MaterialReceiptLoaded(list));
    } catch (e) {
      emit(MaterialReceiptError(e.toString()));
    }
  }

  Future<void> saveReceipt({
    required MaterialReceipt receipt,
    required bool isEdit,
  }) async {
    try {
      if (isEdit) {
        await _repo.updateReceipt(receipt);
      } else {
        await _repo.createReceipt(receipt);
      }
      loadReceipts();
    } catch (e) {
      emit(MaterialReceiptError("Failed to save material receipt: $e"));
    }
  }

  Future<void> completeReceipt(int id) async {
    try {
      // Mock data update to trigger backend Completed status
      await _repo.updateReceipt(
        MaterialReceipt(
          id: id,
          receiptNumber: '',
          receiptDate: '',
          poHeaderId: 0,
          warehouseId: 0,
          containerNo: '',
          sealNo: '',
          status: 'Completed',
          note: '',
          createdBy: '',
          details: [],
        ),
      );
      loadReceipts();
    } catch (e) {
      emit(MaterialReceiptError("Failed to complete material receipt: $e"));
    }
  }

  Future<void> deleteReceipt(int id) async {
    try {
      await _repo.deleteReceipt(id);
      loadReceipts();
    } catch (e) {
      emit(MaterialReceiptError("Failed to delete: $e"));
    }
  }
}
