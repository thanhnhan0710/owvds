import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/weaving_repository.dart';
import '../../domain/weaving_model.dart';

abstract class WeavingState {}
class WeavingInitial extends WeavingState {}
class WeavingLoading extends WeavingState {}
class WeavingLoaded extends WeavingState {
  final List<WeavingTicket> tickets;
  final WeavingTicket? selectedTicket;
  final List<WeavingInspection> inspections;
  
  WeavingLoaded({
    required this.tickets, 
    this.selectedTicket, 
    this.inspections = const []
  });
}
class WeavingError extends WeavingState {
  final String message;
  WeavingError(this.message);
}

class WeavingCubit extends Cubit<WeavingState> {
  final WeavingRepository _repo;

  WeavingCubit(this._repo) : super(WeavingInitial());

  Future<void> loadTickets() async {
    emit(WeavingLoading());
    try {
      final tickets = await _repo.getTickets();
      emit(WeavingLoaded(tickets: tickets));
    } catch (e) {
      emit(WeavingError(e.toString()));
    }
  }

  Future<void> selectTicket(WeavingTicket ticket) async {
    List<WeavingTicket> currentTickets = [];
    if (state is WeavingLoaded) {
      currentTickets = (state as WeavingLoaded).tickets;
    }
    
    emit(WeavingLoading());
    try {
      final inspections = await _repo.getInspections(ticket.id);
      emit(WeavingLoaded(
        tickets: currentTickets,
        selectedTicket: ticket,
        inspections: inspections,
      ));
    } catch (e) {
      emit(WeavingError(e.toString()));
    }
  }
  Future<void> loadInspections(int ticketId) async {
    // Lưu lại danh sách ticket hiện tại để không bị mất dữ liệu dashboard
    List<WeavingTicket> currentTickets = [];
    WeavingTicket? currentSelected;
    
    if (state is WeavingLoaded) {
      currentTickets = (state as WeavingLoaded).tickets;
      currentSelected = (state as WeavingLoaded).selectedTicket;
    }

    emit(WeavingLoading());
    try {
      final inspections = await _repo.getInspections(ticketId);
      emit(WeavingLoaded(
        tickets: currentTickets,
        selectedTicket: currentSelected,
        inspections: inspections,
      ));
    } catch (e) {
      emit(WeavingError("Không thể tải lịch sử kiểm tra: $e"));
    }
  }

  Future<void> saveTicket({required WeavingTicket ticket, required bool isEdit}) async {
    try {
      if (isEdit) {
        await _repo.updateTicket(ticket);
      } else {
        await _repo.createTicket(ticket);
      }
      loadTickets(); // Reload list
    } catch (e) {
      emit(WeavingError("Failed to save ticket: $e"));
    }
  }
  
  Future<void> deleteTicket(int id) async {
    try {
      await _repo.deleteTicket(id);
      loadTickets(); // Reload list, clear selection
    } catch (e) {
      emit(WeavingError("Failed to delete ticket: $e"));
    }
  }

  Future<void> saveInspection(WeavingInspection inspection) async {
    try {
      await _repo.createInspection(inspection);
      // Reload inspections for current ticket
      if (state is WeavingLoaded && (state as WeavingLoaded).selectedTicket != null) {
         selectTicket((state as WeavingLoaded).selectedTicket!);
      }
    } catch (e) {
      emit(WeavingError("Failed to save inspection: $e"));
    }
  }
}