import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:owvds/core/provider/app_providers.dart';

// Đảm bảo các đường dẫn này đúng với project của bạn (owvds)
import 'package:owvds/l10n/app_localizations.dart';
import 'package:owvds/core/bloc/language_cubit.dart';
import 'package:owvds/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:owvds/features/auth/data/auth_repository.dart';

import 'package:owvds/core/routes/app_router.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => AuthRepository(),
      // [GIẢI PHÁP TRIỆT ĐỂ] Khởi tạo AuthCubit trực tiếp ở đây thay vì nhét trong AppProviders.
      // Việc này giúp đồng nhất đường dẫn import gói AuthCubit, tránh hoàn toàn lỗi ProviderNotFound.
      child: BlocProvider<AuthCubit>(
        create: (context) => AuthCubit(context.read<AuthRepository>()),
        child: MultiBlocProvider(
          providers: AppProviders.providers, // Vẫn giữ các providers còn lại
          child: const AppView(),
        ),
      ),
    );
  }
}

class AppView extends StatefulWidget {
  const AppView({super.key});

  @override
  State<AppView> createState() => _AppViewState();
}

class _AppViewState extends State<AppView> {
  // Biến lưu trữ GoRouter để không bị khởi tạo lại mỗi khi build
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Khởi tạo Router ĐÚNG 1 LẦN trong initState.
    // Lúc này context của AppView đã hoàn toàn nằm dưới BlocProvider<AuthCubit>,
    // đảm bảo 100% sẽ read được AuthCubit mà không bị lỗi.
    final authCubit = context.read<AuthCubit>();
    _router = AppRouter.router(authCubit);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageCubit, Locale>(
      builder: (context, locale) {
        return MaterialApp.router(
          title: 'OWVDS App',
          debugShowCheckedModeBanner: false,
          routerConfig: _router, // Sử dụng router đã khởi tạo
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('vi')],
          theme: ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
            fontFamily: 'Roboto',
            inputDecorationTheme: const InputDecorationTheme(
              filled: true,
              fillColor: Color(0xFFF5F5F5),
            ),
          ),
        );
      },
    );
  }
}
