import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:owvds/l10n/app_localizations.dart';
import 'package:owvds/core/bloc/language_cubit.dart';
import 'package:owvds/features/auth/presentation/bloc/auth_cubit.dart';

class AdminTopBar extends StatelessWidget {
  final String userName;
  final String userRole;
  final Color primaryColor;

  const AdminTopBar({
    super.key,
    required this.userName,
    required this.userRole,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Khung tìm kiếm
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: l10n.searchPlaceholder,
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  icon: Icon(Icons.search_rounded, color: Colors.grey.shade500),
                ),
              ),
            ),
          ),

          const SizedBox(width: 20),

          // Nút Đổi Ngôn Ngữ
          _buildLanguageIcon(context),

          const SizedBox(width: 20),
          Container(height: 30, width: 1, color: Colors.grey.shade200),
          const SizedBox(width: 20),

          // Thông tin User & Menu Đăng xuất
          PopupMenuButton<String>(
            offset: const Offset(0, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              if (value == 'logout') {
                context.read<AuthCubit>().logout();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      color: Colors.red.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      l10n.logout,
                      style: TextStyle(color: Colors.red.shade600),
                    ),
                  ],
                ),
              ),
            ],
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: primaryColor.withOpacity(0.1),
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : "U",
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      userRole.toUpperCase(),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageIcon(BuildContext context) {
    final currentLocale = context.watch<LanguageCubit>().state;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        final newCode = currentLocale.languageCode == 'vi' ? 'en' : 'vi';
        context.read<LanguageCubit>().changeLanguage(newCode);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Text(
              currentLocale.languageCode == 'vi' ? "🇻🇳" : "🇺🇸",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 8),
            Text(
              currentLocale.languageCode == 'vi' ? "VI" : "EN",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
