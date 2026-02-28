import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';

class LanguageCubit extends Cubit<Locale> {
  // Mặc định là Tiếng Việt
  LanguageCubit() : super(const Locale('vi'));

  void changeLanguage(String code) {
    emit(Locale(code));
  }
}