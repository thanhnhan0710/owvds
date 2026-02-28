import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/user_repository.dart';
import '../../domain/user_model.dart';

// --- STATES ---
abstract class UserState {}

class UserInitial extends UserState {}
class UserLoading extends UserState {}
class UserLoaded extends UserState {
  final List<User> users;
  UserLoaded(this.users);
}
class UserError extends UserState {
  final String message;
  UserError(this.message);
}

// --- CUBIT ---
class UserCubit extends Cubit<UserState> {
  final UserRepository _repository;

  UserCubit(this._repository) : super(UserInitial());

  // Load danh sách
  Future<void> loadUsers() async {
    emit(UserLoading());
    try {
      final users = await _repository.getUsers();
      emit(UserLoaded(users));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  // Tìm kiếm
  Future<void> searchUsers(String query) async {
    emit(UserLoading());
    try {
      final users = await _repository.getUsers(search: query);
      emit(UserLoaded(users));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  // Tạo mới
  Future<void> createUser(User user, String password) async {
    try {
      // Optimistic update hoặc reload lại list
      await _repository.createUser(user, password);
      await loadUsers(); // Reload lại danh sách sau khi tạo
    } catch (e) {
      emit(UserError(e.toString()));
      // Sau khi báo lỗi, có thể cần load lại state cũ hoặc giữ nguyên
      // Ở đây gọi lại loadUsers để reset về trạng thái ổn định
      loadUsers();
    }
  }

  // Cập nhật
  Future<void> updateUser(User user, {String? newPassword}) async {
    try {
      await _repository.updateUser(user.id, user, password: newPassword);
      await loadUsers();
    } catch (e) {
      emit(UserError(e.toString()));
      loadUsers();
    }
  }

  // Xóa
  Future<void> deleteUser(int userId) async {
    try {
      await _repository.deleteUser(userId);
      await loadUsers();
    } catch (e) {
      emit(UserError(e.toString()));
      loadUsers();
    }
  }
}