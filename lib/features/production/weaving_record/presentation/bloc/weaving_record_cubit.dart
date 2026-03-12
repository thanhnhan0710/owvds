import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:owvds/features/production/weaving_record/data/weaving_record_repository.dart';
import 'package:owvds/features/production/weaving_record/domain/weaving_record_model.dart';

// --- STATES ---
abstract class WeavingRecordState {}

class WeavingRecordInitial extends WeavingRecordState {}

class WeavingRecordLoading extends WeavingRecordState {}

class WeavingRecordLoaded extends WeavingRecordState {
  final List<WeavingRecord> records;
  WeavingRecordLoaded(this.records);
}

class WeavingRecordError extends WeavingRecordState {
  final String message;
  WeavingRecordError(this.message);
}

// --- CUBIT ---
class WeavingRecordCubit extends Cubit<WeavingRecordState> {
  final WeavingRecordRepository _repo;

  WeavingRecordCubit(this._repo) : super(WeavingRecordInitial());

  Future<void> loadRecords() async {
    emit(WeavingRecordLoading());
    try {
      final list = await _repo.getRecords();
      emit(WeavingRecordLoaded(list));
    } catch (e) {
      emit(WeavingRecordError(e.toString()));
    }
  }

  Future<void> saveRecord({
    required WeavingRecord item,
    required bool isEdit,
  }) async {
    try {
      print("📤 Sending Record: ${item.toJson()}");
      if (isEdit) {
        await _repo.updateRecord(item);
      } else {
        await _repo.createRecord(item);
      }
      loadRecords();
    } catch (e) {
      print("❌ Save Failed: $e");
      emit(WeavingRecordError(e.toString().replaceAll("Exception: ", "")));
    }
  }

  Future<void> deleteRecord(int id) async {
    try {
      await _repo.deleteRecord(id);
      loadRecords();
    } catch (e) {
      emit(WeavingRecordError("Failed to delete: $e"));
    }
  }

  Future<List<WeavingRecord>> getRecordsByTicketId(int ticketId) async {
    try {
      return await _repo.getRecordsByTicketId(ticketId);
    } catch (e) {
      print("Cubit Error fetching by ticket: $e");
      return [];
    }
  }
}
