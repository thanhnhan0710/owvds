import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:owvds/features/production/basket/data/baket_repository.dart';
import 'package:owvds/features/production/basket/doamain/basket_model.dart';

abstract class BasketState {}

class BasketInitial extends BasketState {}

class BasketLoading extends BasketState {}

class BasketLoaded extends BasketState {
  final List<Basket> baskets;
  BasketLoaded(this.baskets);
}

// [MỚI] Thêm 2 state thông báo cho việc Import
class BasketSuccessMsg extends BasketState {
  final String message;
  BasketSuccessMsg(this.message);
}

class BasketErrorMsg extends BasketState {
  final String message;
  BasketErrorMsg(this.message);
}

class BasketError extends BasketState {
  final String message;
  BasketError(this.message);
}

class BasketCubit extends Cubit<BasketState> {
  final BasketRepository _repo;

  BasketCubit(this._repo) : super(BasketInitial());

  Future<void> loadBaskets() async {
    emit(BasketLoading());
    try {
      final list = await _repo.getBaskets();
      emit(BasketLoaded(list));
    } catch (e) {
      emit(BasketError(e.toString()));
    }
  }

  Future<void> searchBaskets(String keyword) async {
    if (keyword.trim().isEmpty) {
      loadBaskets();
      return;
    }
    emit(BasketLoading());
    try {
      final list = await _repo.searchBaskets(keyword);
      emit(BasketLoaded(list));
    } catch (e) {
      emit(BasketError(e.toString()));
    }
  }

  Future<void> saveBasket({
    required Basket basket,
    required bool isEdit,
  }) async {
    try {
      if (isEdit) {
        await _repo.updateBasket(basket);
      } else {
        await _repo.createBasket(basket);
      }
      loadBaskets();
    } catch (e) {
      emit(BasketError("Failed to save data: $e"));
    }
  }

  Future<void> deleteBasket(int id) async {
    try {
      await _repo.deleteBasket(id);
      loadBaskets();
    } catch (e) {
      emit(BasketError("Failed to delete data: $e"));
    }
  }

  // --- HÀM IMPORT EXCEL ---
  Future<void> importExcel(PlatformFile file) async {
    emit(BasketLoading());
    try {
      final result = await _repo.importExcel(file);

      final int successCount = result['success_count'] ?? 0;
      final List errors = result['errors'] ?? [];

      String msg = "Đã import thành công $successCount Rổ.";

      // 1. Phát ra State thông báo cho UI bật Popup
      if (errors.isNotEmpty) {
        msg += "\n\n⚠️ Bỏ qua các dòng lỗi sau:\n${errors.join('\n')}";
        emit(BasketErrorMsg(msg));
      } else {
        emit(BasketSuccessMsg(msg));
      }

      // 2. [QUAN TRỌNG] Đợi 100ms để UI kịp bắt thông báo, sau đó tải lại danh sách
      // và đưa State về lại BasketLoaded để vẽ cái Bảng ra màn hình.
      await Future.delayed(const Duration(milliseconds: 100));
      await loadBaskets();
    } catch (e) {
      // 1. Báo lỗi
      emit(BasketErrorMsg(e.toString().replaceAll("Exception: ", "")));
      // 2. Phục hồi lại dữ liệu cũ để tránh trắng màn hình
      await Future.delayed(const Duration(milliseconds: 100));
      await loadBaskets();
    }
  }
}
