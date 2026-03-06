import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:owvds/features/inventory/PO/po_detail/data/po_detail_repository.dart';
import 'package:owvds/features/inventory/PO/po_detail/domain/po_detail_model.dart';

abstract class PODetailState {}

class PODetailInitial extends PODetailState {}

class PODetailLoading extends PODetailState {}

class PODetailSuccess extends PODetailState {}

class PODetailError extends PODetailState {
  final String message;
  PODetailError(this.message);
}

class PODetailCubit extends Cubit<PODetailState> {
  final PODetailRepository _repo;

  PODetailCubit(this._repo) : super(PODetailInitial());

  Future<void> addDetail(int poId, PurchaseOrderDetail detail) async {
    emit(PODetailLoading());
    try {
      await _repo.createDetail(poId, detail);
      emit(PODetailSuccess());
    } catch (e) {
      emit(PODetailError(e.toString().replaceAll("Exception: ", "")));
    }
  }

  Future<void> updateDetail(int detailId, Map<String, dynamic> data) async {
    emit(PODetailLoading());
    try {
      await _repo.updateDetail(detailId, data);
      emit(PODetailSuccess());
    } catch (e) {
      emit(PODetailError(e.toString().replaceAll("Exception: ", "")));
    }
  }

  Future<void> deleteDetail(int detailId) async {
    emit(PODetailLoading());
    try {
      await _repo.deleteDetail(detailId);
      emit(PODetailSuccess());
    } catch (e) {
      emit(PODetailError(e.toString().replaceAll("Exception: ", "")));
    }
  }
}
