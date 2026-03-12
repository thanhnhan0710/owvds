import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:owvds/features/production/basket/data/baket_repository.dart';
import 'package:owvds/features/production/basket/doamain/basket_model.dart';
import 'package:owvds/features/production/machine/machine/data/machine_repository.dart';
import 'package:owvds/features/production/machine/machine/domain/machine_model.dart';

// Import các Repository và Model
import '../../../weaving/domain/weaving_model.dart';
import '../../../weaving/data/weaving_repository.dart';

// =======================
// STATE
// =======================
abstract class MachineOpState {}

class MachineOpInitial extends MachineOpState {}

class MachineOpLoading extends MachineOpState {}

class MachineOpLoaded extends MachineOpState {
  final List<Machine> machines;
  final Map<String, WeavingTicket> activeTickets;
  final List<Basket> readyBaskets;

  MachineOpLoaded({
    required this.machines,
    required this.activeTickets,
    required this.readyBaskets,
  });
}

class MachineOpError extends MachineOpState {
  final String message;
  MachineOpError(this.message);
}

// =======================
// CUBIT
// =======================
class MachineOperationCubit extends Cubit<MachineOpState> {
  final MachineRepository _machineRepo;
  final WeavingRepository _weavingRepo;
  final BasketRepository _basketRepo;

  MachineOperationCubit(this._machineRepo, this._weavingRepo, this._basketRepo)
    : super(MachineOpInitial());

  // --- LOAD DASHBOARD ---
  Future<void> loadMachines() async {
    await loadDashboard();
  }

  Future<void> loadDashboard() async {
    emit(MachineOpLoading());
    try {
      final machines = await _machineRepo.getMachines();

      final allBaskets = await _basketRepo.getBaskets();
      final readyBaskets = allBaskets
          .where((b) => b.status == 'READY')
          .toList();

      final allTickets = await _weavingRepo.getTickets();
      final activeTicketsList = allTickets
          .where((t) => t.timeOut == null)
          .toList();

      final Map<String, WeavingTicket> activeMap = {};
      for (var t in activeTicketsList) {
        final key = "${t.machineId}_${t.machineLine}";
        activeMap[key] = t;
      }

      emit(
        MachineOpLoaded(
          machines: machines,
          activeTickets: activeMap,
          readyBaskets: readyBaskets,
        ),
      );
    } catch (e) {
      emit(MachineOpError(e.toString()));
    }
  }

  // --- CẬP NHẬT THÔNG TIN PHIẾU ---
  Future<void> updateTicketInfo({
    required int ticketId,
    required int basketId,
    required int standardId,
    required int employeeInId,
  }) async {
    try {
      final tickets = await _weavingRepo.getTickets();
      final oldTicket = tickets.firstWhere((t) => t.id == ticketId);

      final updatedTicket = WeavingTicket(
        id: oldTicket.id,
        code: oldTicket.code,
        machineId: oldTicket.machineId,
        machineLine: oldTicket.machineLine,
        yarnLoadDate: oldTicket.yarnLoadDate,
        productId: oldTicket.productId,
        yarns: oldTicket.yarns,
        basketId: basketId,
        standardId: standardId,
        employeeInId: employeeInId,
        timeIn: DateTime.now().toIso8601String(),
        timeOut: oldTicket.timeOut,
        employeeOutId: oldTicket.employeeOutId,
        grossWeight: oldTicket.grossWeight,
        netWeight: oldTicket.netWeight,
        lengthMeters: oldTicket.lengthMeters,
        numberOfKnots: oldTicket.numberOfKnots,
        basketCode: oldTicket.basketCode,
      );

      await _weavingRepo.updateTicket(updatedTicket);

      final basketList = await _basketRepo.getBaskets();
      final selectedBasket = basketList.firstWhere((b) => b.id == basketId);

      final updatedBasket = Basket(
        id: selectedBasket.id,
        code: selectedBasket.code,
        tareWeight: selectedBasket.tareWeight,
        status: "IN_USE",
        note: selectedBasket.note,
      );
      await _basketRepo.updateBasket(updatedBasket);

      loadDashboard();
    } catch (e) {
      emit(MachineOpError("Lỗi gán rổ: $e"));
      loadDashboard();
    }
  }

  // --- KẾT THÚC PHIẾU ---
  Future<void> finishTicket({
    required WeavingTicket ticket,
    required int employeeOutId,
    required double grossWeight,
    required double length,
    required int numberOfKnots,
  }) async {
    try {
      final updatedTicket = WeavingTicket(
        id: ticket.id,
        code: ticket.code,
        productId: ticket.productId,
        standardId: ticket.standardId,
        machineId: ticket.machineId,
        machineLine: ticket.machineLine,
        yarnLoadDate: ticket.yarnLoadDate,
        yarns: ticket.yarns,
        basketId: ticket.basketId,
        timeIn: ticket.timeIn,
        employeeInId: ticket.employeeInId,
        timeOut: DateTime.now().toIso8601String(),
        employeeOutId: employeeOutId,
        grossWeight: grossWeight,
        lengthMeters: length,
        numberOfKnots: numberOfKnots,
        netWeight: 0,
      );

      await _weavingRepo.updateTicket(updatedTicket);

      final basketList = await _basketRepo.getBaskets();
      final currentBasket = basketList
          .where((b) => b.id == ticket.basketId)
          .firstOrNull;

      if (currentBasket != null) {
        final updatedBasket = Basket(
          id: currentBasket.id,
          code: currentBasket.code,
          tareWeight: currentBasket.tareWeight,
          status: "READY",
          note: currentBasket.note,
        );
        await _basketRepo.updateBasket(updatedBasket);
      }

      loadDashboard();
    } catch (e) {
      emit(MachineOpError("Lỗi kết thúc phiếu: $e"));
      loadDashboard();
    }
  }

  // --- [FIXED] CẬP NHẬT TRẠNG THÁI MÁY ---
  // Nhận XFile từ UI -> Chuyển thành File -> Gửi cho Repo
  Future<void> updateMachineStatus({
    required int machineId,
    required String status,
    String? reason,
    XFile? imageFile, // Nhận XFile từ ImagePicker
  }) async {
    try {
      File? fileToSend;

      // Chuyển đổi XFile sang File (dart:io)
      if (imageFile != null) {
        fileToSend = File(imageFile.path);
      }

      // Gọi Repository với File thực thụ
      await _machineRepo.updateMachineStatus(
        machineId,
        status,
        reason: reason,
        imageFile: fileToSend, // [QUAN TRỌNG] Gửi File object
      );

      // Cập nhật UI ngay lập tức (Optimistic Update)
      if (state is MachineOpLoaded) {
        final currentMachines = (state as MachineOpLoaded).machines;
        final index = currentMachines.indexWhere((m) => m.id == machineId);

        if (index != -1) {
          final updatedMachines = List<Machine>.from(currentMachines);
          updatedMachines[index] = updatedMachines[index].copyWith(
            statusName: status, // Optimistic update bằng tên chuỗi
          );

          emit(
            MachineOpLoaded(
              machines: updatedMachines,
              activeTickets: (state as MachineOpLoaded).activeTickets,
              readyBaskets: (state as MachineOpLoaded).readyBaskets,
            ),
          );
        }
      }

      // Có thể gọi loadDashboard() để đồng bộ chuẩn với server nếu cần
      // loadDashboard();
    } catch (e) {
      emit(MachineOpError("Lỗi cập nhật trạng thái: $e"));
      loadDashboard();
    }
  }
}
