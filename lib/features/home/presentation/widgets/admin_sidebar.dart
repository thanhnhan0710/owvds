import 'package:flutter/material.dart';
import 'package:owvds/l10n/app_localizations.dart';

// ─── DESIGN TOKENS ────────────────────────────────────────────────────────────
const _kSidebarBg = Color(0xFF0A1628);
const _kSidebarBg2 = Color(0xFF0F1F3A);
const _kAccent = Color(0xFF2563EB);
const _kAccentLight = Color(0xFF60A5FA);
const _kTextPrimary = Colors.white;
const _kTextMuted = Color(0x66FFFFFF); // 40 % white
const _kDivider = Color(0x12FFFFFF); // 7 % white
const _kActiveOverlay = Color(0x382563EB); // 22 % accent

class AdminSidebar extends StatelessWidget {
  final String currentPath;
  final bool isAdmin;
  final Function(String) onNavigate;
  final String userName;
  final String userRole;

  const AdminSidebar({
    super.key,
    required this.currentPath,
    required this.isAdmin,
    required this.onNavigate,
    this.userName = 'Admin',
    this.userRole = 'ADMIN',
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: 248,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kSidebarBg, _kSidebarBg2, _kSidebarBg],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Column(
        children: [
          _buildLogo(l10n),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── MAIN ──────────────────────────────────────────────
                  _SectionLabel('MAIN'),
                  _NavItem(
                    icon: Icons.grid_view_rounded,
                    label: l10n.dashboard,
                    route: '/admin-dashboard',
                    currentPath: currentPath,
                    onTap: onNavigate,
                  ),

                  // ── INVENTORY ─────────────────────────────────────────
                  _SectionLabel('INVENTORY'),
                  _NavGroup(
                    icon: Icons.inventory_2_rounded,
                    label: l10n.inventory,
                    childRoutes: const ['/warehouse-dashboard'],
                    currentPath: currentPath,
                    children: [
                      _NavItem(
                        icon: Icons.dashboard_customize_rounded,
                        label: 'Tổng quan Kho NVL',
                        route: '/warehouse-dashboard',
                        currentPath: currentPath,
                        onTap: onNavigate,
                        isChild: true,
                      ),
                    ],
                  ),

                  // ── PRODUCTION ────────────────────────────────────────
                  _SectionLabel('PRODUCTION'),
                  _NavGroup(
                    icon: Icons.precision_manufacturing_rounded,
                    label: l10n.production,
                    childRoutes: const ['/production-dashboard'],
                    currentPath: currentPath,
                    children: [
                      _NavItem(
                        icon: Icons.dashboard_customize_rounded,
                        label: 'Bảng ĐK Sản xuất',
                        route: '/production-dashboard',
                        currentPath: currentPath,
                        onTap: onNavigate,
                        isChild: true,
                      ),
                    ],
                  ),

                  // ── QUALITY CONTROL ───────────────────────────────────
                  _SectionLabel('QUALITY CONTROL'),
                  _NavGroup(
                    icon: Icons.verified_rounded,
                    label: 'Quản lý Chất lượng',
                    childRoutes: const ['/qc-dashboard'],
                    currentPath: currentPath,
                    children: [
                      _NavItem(
                        icon: Icons.dashboard_customize_rounded,
                        label: 'Tổng quan QC',
                        route: '/qc-dashboard',
                        currentPath: currentPath,
                        onTap: onNavigate,
                        isChild: true,
                      ),
                    ],
                  ),

                  // ── MANAGEMENT ────────────────────────────────────────
                  _SectionLabel('MANAGEMENT'),
                  _NavGroup(
                    icon: Icons.people_alt_rounded,
                    label: l10n.hr,
                    childRoutes: const ['/hr-dashboard'],
                    currentPath: currentPath,
                    children: [
                      _NavItem(
                        icon: Icons.dashboard_customize_rounded,
                        label: 'Tổng quan Nhân sự',
                        route: '/hr-dashboard',
                        currentPath: currentPath,
                        onTap: onNavigate,
                        isChild: true,
                      ),
                    ],
                  ),

                  // ── SYSTEM (admin only) ───────────────────────────────
                  if (isAdmin) ...[
                    _SectionLabel('SYSTEM'),
                    _NavGroup(
                      icon: Icons.admin_panel_settings_rounded,
                      label: l10n.adminTitle,
                      childRoutes: const ['/users', '/logs'],
                      currentPath: currentPath,
                      children: [
                        _NavItem(
                          icon: Icons.manage_accounts_rounded,
                          label: l10n.userManagementTitle,
                          route: '/users',
                          currentPath: currentPath,
                          onTap: onNavigate,
                          isChild: true,
                        ),
                        _NavItem(
                          icon: Icons.history_rounded,
                          label: l10n.activityLog,
                          route: '/logs',
                          currentPath: currentPath,
                          onTap: onNavigate,
                          isChild: true,
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          _buildUserFooter(),
        ],
      ),
    );
  }

  // ── Logo header ─────────────────────────────────────────────────────────────
  Widget _buildLogo(AppLocalizations l10n) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _kDivider)),
      ),
      child: Row(
        children: [
          // Brand mark
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_kAccent, _kAccentLight],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Text(
              'OWV',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.oppermannHeader,
                style: const TextStyle(
                  color: _kTextPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 0.4,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                l10n.erpSystemShort,
                style: const TextStyle(
                  color: _kTextMuted,
                  fontSize: 10,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── User footer ─────────────────────────────────────────────────────────────
  Widget _buildUserFooter() {
    final initials = userName.isNotEmpty ? userName[0].toUpperCase() : 'A';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _kDivider)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_kAccent, _kAccentLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: const TextStyle(
                      color: _kTextPrimary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    userRole.toUpperCase(),
                    style: const TextStyle(
                      color: _kTextMuted,
                      fontSize: 9.5,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── SECTION LABEL ────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 6),
      child: Text(
        text,
        style: const TextStyle(
          color: _kTextMuted,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

// ─── NAV ITEM ─────────────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final String currentPath;
  final Function(String) onTap;
  final bool isChild;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.currentPath,
    required this.onTap,
    this.isChild = false,
  });

  bool get _isActive => currentPath == route || currentPath.startsWith(route);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(isChild ? 20 : 8, 1, 8, 1),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          onTap: () => onTap(route),
          borderRadius: BorderRadius.circular(9),
          splashColor: Colors.white.withOpacity(0.05),
          highlightColor: Colors.white.withOpacity(0.03),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.symmetric(
              horizontal: isChild ? 10 : 10,
              vertical: isChild ? 8 : 9,
            ),
            decoration: BoxDecoration(
              color: _isActive ? _kActiveOverlay : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
              border: _isActive
                  ? Border.all(color: _kAccent.withOpacity(0.4), width: 1)
                  : null,
            ),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: isChild ? 26 : 30,
                  height: isChild ? 26 : 30,
                  decoration: BoxDecoration(
                    color: _isActive
                        ? _kAccent.withOpacity(0.35)
                        : Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(isChild ? 6 : 8),
                  ),
                  child: Icon(
                    icon,
                    color: _isActive ? _kAccentLight : const Color(0x99FFFFFF),
                    size: isChild ? 14 : 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: _isActive ? Colors.white : const Color(0x99FFFFFF),
                      fontSize: isChild ? 12 : 13,
                      fontWeight: _isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_isActive && !isChild)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: _kAccentLight,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── NAV GROUP (expandable) ───────────────────────────────────────────────────
class _NavGroup extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<String> childRoutes;
  final String currentPath;
  final List<Widget> children;

  const _NavGroup({
    required this.icon,
    required this.label,
    required this.childRoutes,
    required this.currentPath,
    required this.children,
  });

  bool get _isExpanded => childRoutes.any((r) => currentPath.startsWith(r));

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        splashColor: Colors.white.withOpacity(0.04),
        highlightColor: Colors.transparent,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: ExpansionTile(
            initiallyExpanded: _isExpanded,
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 0,
            ),
            childrenPadding: const EdgeInsets.only(bottom: 4),
            leading: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: _isExpanded
                    ? _kAccent.withOpacity(0.3)
                    : Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: _isExpanded ? _kAccentLight : const Color(0x99FFFFFF),
                size: 16,
              ),
            ),
            title: Text(
              label,
              style: TextStyle(
                color: _isExpanded ? Colors.white : const Color(0x99FFFFFF),
                fontSize: 13,
                fontWeight: _isExpanded ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            iconColor: const Color(0x66FFFFFF),
            collapsedIconColor: const Color(0x66FFFFFF),
            backgroundColor: Colors.white.withOpacity(0.03),
            collapsedBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
            children: children,
          ),
        ),
      ),
    );
  }
}
