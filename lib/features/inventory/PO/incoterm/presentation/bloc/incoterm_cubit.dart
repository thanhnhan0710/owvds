import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/incoterm_repository.dart';
import '../../domain/incoterm_model.dart';

abstract class IncotermState {}

class IncotermInitial extends IncotermState {}

class IncotermLoading extends IncotermState {}

class IncotermLoaded extends IncotermState {
  final List<Incoterm> incoterms;
  IncotermLoaded({required this.incoterms});
}

class IncotermError extends IncotermState {
  final String message;
  IncotermError(this.message);
}

class IncotermCubit extends Cubit<IncotermState> {
  final IncotermRepository _repo;

  IncotermCubit(this._repo) : super(IncotermInitial());

  String _parseError(dynamic e) {
    String msg = e.toString();
    if (msg.contains("409")) return "Mã Incoterm đã tồn tại!";
    return msg.replaceAll("Exception: ", "");
  }

  Future<void> loadIncoterms() async {
    emit(IncotermLoading());
    try {
      final list = await _repo.getIncoterms();
      emit(IncotermLoaded(incoterms: list));
    } catch (e) {
      emit(IncotermError(_parseError(e)));
    }
  }

  Future<void> searchIncoterms(String keyword) async {
    emit(IncotermLoading());
    try {
      final list = await _repo.getIncoterms(search: keyword.trim());
      emit(IncotermLoaded(incoterms: list));
    } catch (e) {
      emit(IncotermError(_parseError(e)));
    }
  }

  Future<void> addIncoterm(Incoterm incoterm) async {
    try {
      await _repo.createIncoterm(incoterm);
      await loadIncoterms();
    } catch (e) {
      emit(IncotermError(_parseError(e)));
      await Future.delayed(const Duration(milliseconds: 100));
      await loadIncoterms();
    }
  }

  Future<void> updateIncoterm(Incoterm incoterm) async {
    try {
      await _repo.updateIncoterm(incoterm);
      await loadIncoterms();
    } catch (e) {
      emit(IncotermError(_parseError(e)));
      await Future.delayed(const Duration(milliseconds: 100));
      await loadIncoterms();
    }
  }

  Future<void> deleteIncoterm(int id) async {
    try {
      await _repo.deleteIncoterm(id);
      await loadIncoterms();
    } catch (e) {
      emit(IncotermError(_parseError(e)));
      await Future.delayed(const Duration(milliseconds: 100));
      await loadIncoterms();
    }
  }
}
