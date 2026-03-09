import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/material_batch_repository.dart';
import '../../domain/material_batch_model.dart';

abstract class MaterialBatchState {}

class MaterialBatchInitial extends MaterialBatchState {}

class MaterialBatchLoading extends MaterialBatchState {}

class MaterialBatchLoaded extends MaterialBatchState {
  final List<MaterialBatch> batches;
  MaterialBatchLoaded(this.batches);
}

class MaterialBatchError extends MaterialBatchState {
  final String message;
  MaterialBatchError(this.message);
}

class MaterialBatchCubit extends Cubit<MaterialBatchState> {
  final MaterialBatchRepository _repo;

  MaterialBatchCubit(this._repo) : super(MaterialBatchInitial());

  Future<void> loadBatches() async {
    emit(MaterialBatchLoading());
    try {
      final list = await _repo.getBatches();
      emit(MaterialBatchLoaded(list));
    } catch (e) {
      emit(MaterialBatchError(e.toString()));
    }
  }

  Future<void> searchBatches(String keyword) async {
    if (keyword.trim().isEmpty) {
      loadBatches();
      return;
    }
    emit(MaterialBatchLoading());
    try {
      final list = await _repo.searchBatches(keyword);
      emit(MaterialBatchLoaded(list));
    } catch (e) {
      emit(MaterialBatchError(e.toString()));
    }
  }

  Future<void> saveBatch({
    required MaterialBatch batch,
    required bool isEdit,
  }) async {
    try {
      if (isEdit) {
        await _repo.updateBatch(batch);
      } else {
        await _repo.createBatch(batch);
      }
      loadBatches();
    } catch (e) {
      emit(MaterialBatchError("Failed to save material batch: $e"));
    }
  }

  Future<void> deleteBatch(int id) async {
    try {
      await _repo.deleteBatch(id);
      loadBatches();
    } catch (e) {
      emit(MaterialBatchError("Failed to delete: $e"));
    }
  }
}
