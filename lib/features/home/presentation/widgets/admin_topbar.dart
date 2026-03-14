import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:owvds/l10n/app_localizations.dart';
import 'package:owvds/features/auth/presentation/bloc/auth_cubit.dart';

// ─── DESIGN TOKENS ────────────────────────────────────────────────────────────
const _kNavy = Color(0xFF0A1628);
const _kAccent = Color(0xFF2563EB);
const _kLight = Color(0xFF60A5FA);
const _kBorder = Color(0xFFE3E8F0);
const _kBg = Color(0xFFF4F7FB);
const _kMuted = Color(0xFF9BA8BB);

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
    final initials = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: Row(
        children: [
          // ── Search ─────────────────────────────────────────────────────────
          _SearchBar(hintText: l10n.searchPlaceholder),

          const Spacer(),

          // ── Notification bell ───────────────────────────────────────────────
          _NotifBell(),
          const SizedBox(width: 12),

          const _VDivider(),
          const SizedBox(width: 12),

          // ── User dropdown ───────────────────────────────────────────────────
          PopupMenuButton<String>(
            offset: const Offset(0, 54),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: Colors.white,
            shadowColor: Colors.black.withOpacity(0.08),
            onSelected: (value) {
              if (value == 'logout') context.read<AuthCubit>().logout();
            },
            itemBuilder: (context) => [
              // User info header (disabled, display only)
              PopupMenuItem(
                enabled: false,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _kNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userRole.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        color: _kMuted,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Divider(height: 1, color: Colors.grey.shade100),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.logout_rounded,
                        color: Colors.red.shade500,
                        size: 15,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      l10n.logout,
                      style: TextStyle(
                        color: Colors.red.shade600,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            child: _UserChip(
              initials: initials,
              userName: userName,
              userRole: userRole,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SEARCH BAR ───────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final String hintText;
  const _SearchBar({required this.hintText});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 38,
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              style: const TextStyle(fontSize: 13, color: _kNavy),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: hintText,
                hintStyle: const TextStyle(fontSize: 13, color: _kMuted),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EDF5),
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Text(
              '⌘K',
              style: TextStyle(
                fontSize: 10,
                color: _kMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── NOTIFICATION BELL ────────────────────────────────────────────────────────
class _NotifBell extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _kBg,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: _kBorder),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              size: 17,
              color: Color(0xFF6B7A94),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── USER CHIP ────────────────────────────────────────────────────────────────
class _UserChip extends StatelessWidget {
  final String initials;
  final String userName;
  final String userRole;

  const _UserChip({
    required this.initials,
    required this.userName,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_kAccent, _kLight],
              ),
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kNavy,
                ),
              ),
              Text(
                userRole.toUpperCase(),
                style: const TextStyle(
                  fontSize: 9.5,
                  color: _kMuted,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 16,
            color: _kMuted,
          ),
        ],
      ),
    );
  }
}

// ─── THIN DIVIDER ─────────────────────────────────────────────────────────────
class _VDivider extends StatelessWidget {
  const _VDivider();
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 24, color: _kBorder);
}
