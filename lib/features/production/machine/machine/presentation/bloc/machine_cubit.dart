import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_saver/file_saver.dart';
import '../../data/machine_repository.dart';
import '../../domain/machine_model.dart';

abstract class MachineState {}

class MachineInitial extends MachineState {}

class MachineLoading extends MachineState {}

class MachineLoaded extends MachineState {
  final List<Machine> allMachines; // Dùng để đếm số lượng trên thanh Sidebar
  final List<Machine> displayedMachines; // Dùng để hiển thị lưới
  MachineLoaded({required this.allMachines, required this.displayedMachines});
}

class MachineError extends MachineState {
  final String message;
  MachineError(this.message);
}

class MachineCubit extends Cubit<MachineState> {
  final MachineRepository _repo;
  List<Machine> _allMachinesCache = [];

  MachineCubit(this._repo) : super(MachineInitial());

  Future<void> loadMachines({
    int? filterAreaId,
    int? filterStatusId,
    bool forceRefresh = false,
  }) async {
    emit(MachineLoading());
    try {
      if (_allMachinesCache.isEmpty || forceRefresh) {
        _allMachinesCache = await _repo.getMachines();
        _allMachinesCache.sort(
          (a, b) => b.id.compareTo(a.id),
        ); // Sắp xếp mới nhất
      }

      // Lọc nhanh trên RAM
      List<Machine> filtered = _allMachinesCache;
      if (filterAreaId != null) {
        filtered = filtered.where((m) => m.areaId == filterAreaId).toList();
      }
      if (filterStatusId != null) {
        filtered = filtered.where((m) => m.statusId == filterStatusId).toList();
      }

      emit(
        MachineLoaded(
          allMachines: _allMachinesCache,
          displayedMachines: filtered,
        ),
      );
    } catch (e) {
      emit(MachineError(e.toString()));
    }
  }

  Future<void> searchMachines(String keyword) async {
    if (keyword.trim().isEmpty) return loadMachines();
    emit(MachineLoading());
    try {
      final list = await _repo.searchMachines(keyword);
      list.sort((a, b) => b.id.compareTo(a.id));
      emit(
        MachineLoaded(allMachines: _allMachinesCache, displayedMachines: list),
      );
    } catch (e) {
      emit(MachineError(e.toString()));
    }
  }

  Future<void> saveMachine({
    required Machine machine,
    required bool isEdit,
  }) async {
    try {
      isEdit
          ? await _repo.updateMachine(machine)
          : await _repo.createMachine(machine);
      loadMachines(forceRefresh: true);
    } catch (e) {
      emit(MachineError("Lỗi lưu máy: $e"));
    }
  }

  Future<void> deleteMachine(int id) async {
    try {
      await _repo.deleteMachine(id);
      loadMachines(forceRefresh: true);
    } catch (e) {
      emit(MachineError("Lỗi xóa: $e"));
    }
  }

  Future<void> importExcel(PlatformFile file) async {
    emit(MachineLoading());
    try {
      final result = await _repo.importExcel(file);
      await loadMachines(forceRefresh: true);
      if (result['errors'] != null && (result['errors'] as List).isNotEmpty) {
        emit(
          MachineError(
            "Import thành công ${result['success_count']} dòng. Lỗi:\n${(result['errors'] as List).join('\n')}",
          ),
        );
      }
    } catch (e) {
      emit(MachineError(e.toString()));
    }
  }

  Future<void> exportExcel() async {
    try {
      final bytes = await _repo.exportExcel();
      await FileSaver.instance.saveFile(
        name: 'Danh_Muc_May_Moc_${DateTime.now().millisecondsSinceEpoch}.xlsx',
        bytes: bytes,
        mimeType: MimeType.microsoftExcel,
      );
    } catch (e) {
      emit(MachineError("Lỗi xuất file: $e"));
    }
  }
}
