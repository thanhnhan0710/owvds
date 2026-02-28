import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/auth_exception.dart';
import '../../data/auth_repository.dart';
import '../../domain/user_model.dart';

// --- STATES ---
abstract class AuthState {}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {
  final User user;
  AuthAuthenticated(this.user);
}
class AuthError extends AuthState {
  final AuthErrorCode code; 
  final String? detailMessage;

  AuthError(this.code, {this.detailMessage});
}

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repository;

  AuthCubit(this._repository) : super(AuthInitial());

  Future<void> login(String username, String password) async {
    emit(AuthLoading());
    try {
      // Repository sẽ thực hiện 2 bước: 
      // 1. Lấy Token 
      // 2. Gọi /users/me để lấy thông tin User (bao gồm employeeId)
      final user = await _repository.login(username, password);
      
      // User lúc này đã có employeeId
      emit(AuthAuthenticated(user));
    } on AuthException catch (e) {
      emit(AuthError(e.code, detailMessage: e.detail));
    } catch (e) {
      emit(AuthError(AuthErrorCode.systemError, detailMessage: e.toString()));
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    emit(AuthInitial());
  }
  
  // Hàm tiện ích để lấy ID nhân viên hiện tại (nếu có)
  int? get currentEmployeeId {
    if (state is AuthAuthenticated) {
      return (state as AuthAuthenticated).user.employeeId;
    }
    return null;
  }
}