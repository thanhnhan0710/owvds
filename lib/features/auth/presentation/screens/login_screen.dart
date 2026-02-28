import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:owvds/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/widgets/responsive_layout.dart';
import '../../../../core/bloc/language_cubit.dart';

import '../../data/auth_exception.dart';
import '../bloc/auth_cubit.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _rememberMe = false;
  bool _obscurePassword = true; // [MỚI] Biến để ẩn/hiện mật khẩu

  final Color _primaryColor = const Color(0xFF003366);
  final Color _bgLight = const Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  // Tải thông tin đăng nhập đã lưu
  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('remember_me') ?? false;
      if (_rememberMe) {
        _usernameController.text = prefs.getString('saved_username') ?? '';
        _passwordController.text = prefs.getString('saved_password') ?? '';
      }
    });
  }

  // Hàm tiện ích để dịch mã lỗi AuthErrorCode
  String _mapErrorCodeToMessage(AuthErrorCode code, AppLocalizations l10n) {
    switch (code) {
      case AuthErrorCode.loginFailed:
        return l10n.errorLoginFailed;
      case AuthErrorCode.networkError:
        return l10n.errorNetwork;
      case AuthErrorCode.tokenMissing:
      case AuthErrorCode.userFetchFailed:
        return l10n.errorRequired;
      case AuthErrorCode.systemError:
        return l10n.erpSystemName; // Fallback hoặc key lỗi hệ thống
    }
  }

  // Hàm xử lý login chung để gọi từ Button hoặc Enter
  void _performLogin() async {
    if (_formKey.currentState!.validate()) {
      // Lưu hoặc xóa thông tin đăng nhập dựa trên checkbox
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setBool('remember_me', true);
        await prefs.setString('saved_username', _usernameController.text);
        await prefs.setString('saved_password', _passwordController.text);
      } else {
        await prefs.remove('remember_me');
        await prefs.remove('saved_username');
        await prefs.remove('saved_password');
      }

      if (mounted) {
        context.read<AuthCubit>().login(
          _usernameController.text,
          _passwordController.text,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          // [ĐÃ SỬA]: Đổi từ /dashboard sang /admin-dashboard để khớp với app_router.dart
          context.go('/admin-dashboard');
        } else if (state is AuthError) {
          final errorMessage = _mapErrorCodeToMessage(state.code, l10n);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: _bgLight,
        body: ResponsiveLayout(
          mobile: _buildMobileLayout(context, l10n),
          desktop: _buildDesktopLayout(context, l10n),
        ),
      ),
    );
  }

  // --- WIDGET LOGO ---
  Widget _buildLogo({required double height}) {
    return Image.asset(
      'assets/images/logo.png',
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback hiển thị Icon nếu không tìm thấy file logo.png
        return Icon(Icons.business_center, size: height, color: _primaryColor);
      },
    );
  }

  // --- GIAO DIỆN MOBILE ---
  Widget _buildMobileLayout(BuildContext context, AppLocalizations l10n) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: _buildLanguageSelector(context),
              ),
              const SizedBox(height: 40),

              // Khung bao bọc form (Card / Container)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildLogo(height: 70), // Hiển thị Logo
                    const SizedBox(height: 16),
                    Text(
                      l10n.loginSystemHeader,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.loginSubtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildLoginForm(context, l10n),
                  ],
                ),
              ),

              const SizedBox(height: 40),
              Text(
                l10n.copyright,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- GIAO DIỆN DESKTOP ---
  Widget _buildDesktopLayout(BuildContext context, AppLocalizations l10n) {
    return Row(
      children: [
        // Nửa trái: Hình ảnh
        Expanded(
          flex: 5,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.black, // Nền dự phòng
              image: DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1581091226825-a6a2a5aee158?q=80&w=2070&auto=format&fit=crop',
                ),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              // Lớp phủ Gradient đen mờ để làm nổi bật chữ
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _primaryColor.withOpacity(0.9),
                    Colors.black.withOpacity(0.4),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(60),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.precision_manufacturing,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    l10n.companyName.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.erpSystemName,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 20,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Nửa phải: Form đăng nhập
        Expanded(
          flex: 4,
          child: Container(
            color: Colors.white,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: _buildLanguageSelector(context),
                    ),
                    const SizedBox(height: 60),

                    _buildLogo(height: 80), // Hiển thị Logo
                    const SizedBox(height: 24),

                    Text(
                      l10n.loginSystemHeader,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: _primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.loginSubtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 48),

                    Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: _buildLoginForm(context, l10n),
                    ),

                    const SizedBox(height: 60),
                    Text(
                      l10n.copyright,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- WIDGET CHỌN NGÔN NGỮ ---
  Widget _buildLanguageSelector(BuildContext context) {
    final currentLocale = context.watch<LanguageCubit>().state;

    return PopupMenuButton<String>(
      tooltip: 'Select Language',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      offset: const Offset(0, 40),
      onSelected: (String code) {
        context.read<LanguageCubit>().changeLanguage(code);
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'en',
          child: Row(
            children: [
              Text("🇺🇸", style: TextStyle(fontSize: 20)),
              SizedBox(width: 12),
              Text('English', style: TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'vi',
          child: Row(
            children: [
              Text("🇻🇳", style: TextStyle(fontSize: 20)),
              SizedBox(width: 12),
              Text('Tiếng Việt', style: TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(20),
          color: Colors.grey.shade50,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentLocale.languageCode == 'vi' ? "🇻🇳" : "🇺🇸",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(width: 8),
            Text(
              currentLocale.languageCode == 'vi' ? "Tiếng Việt" : "English",
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }

  // --- FORM INPUT ---
  Widget _buildLoginForm(BuildContext context, AppLocalizations l10n) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Trường Tên đăng nhập
          TextFormField(
            controller: _usernameController,
            style: const TextStyle(fontSize: 15),
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: l10n.username,
              labelStyle: TextStyle(color: Colors.grey.shade600),
              prefixIcon: Icon(Icons.person_outline, color: _primaryColor),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _primaryColor, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 18),
            ),
            validator: (v) => v!.isEmpty ? l10n.errorRequired : null,
          ),
          const SizedBox(height: 20),

          // Trường Mật khẩu
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword, // Sử dụng biến trạng thái
            style: const TextStyle(fontSize: 15),
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _performLogin(),
            decoration: InputDecoration(
              labelText: l10n.password,
              labelStyle: TextStyle(color: Colors.grey.shade600),
              prefixIcon: Icon(Icons.lock_outline, color: _primaryColor),
              // Nút ẩn hiện mật khẩu
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey.shade500,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _primaryColor, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 18),
            ),
            validator: (v) => v!.isEmpty ? l10n.errorRequired : null,
          ),

          const SizedBox(height: 16),

          // Checkbox Ghi nhớ đăng nhập & Quên mật khẩu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _rememberMe,
                      activeColor: _primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _rememberMe = value ?? false;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.rememberMe,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                ],
              ),
              // Nút quên mật khẩu (Chỉ là UI cho đẹp, có thể map chức năng sau)
              TextButton(
                onPressed: () {
                  // Chức năng quên mật khẩu (Thêm sau)
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  "Quên mật khẩu?",
                  style: TextStyle(
                    color: _primaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Nút Đăng nhập
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              if (state is AuthLoading) {
                return Center(
                  child: CircularProgressIndicator(color: _primaryColor),
                );
              }
              return SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _performLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ), // Bo góc vuông vức hơn
                  ),
                  child: Text(
                    l10n.btnLogin, // Thay vì toUpperCase, để thường nhìn sang trọng hơn
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
