import 'package:flutter/material.dart';
import 'package:owvds/l10n/app_localizations.dart';

class AdminSidebar extends StatelessWidget {
  final String currentPath;
  final bool isAdmin;
  final Function(String) onNavigate;

  const AdminSidebar({
    super.key,
    required this.currentPath,
    required this.isAdmin,
    required this.onNavigate,
  });

  final Color _primaryColor = const Color(0xFF003366);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: _primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // HEADER LOGO
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.15),
              border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.apartment,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.oppermannHeader,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        l10n.erpSystemShort,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // DANH SÁCH MENU
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  _buildMenuItem(
                    Icons.dashboard_rounded,
                    l10n.dashboard,
                    '/admin-dashboard',
                  ),

                  _buildSectionDivider('INVENTORY'),
                  _buildExpansionGroup(
                    context: context,
                    icon: Icons.inventory_2_rounded,
                    title: l10n.inventory,
                    childrenRoutes: [
                      '/warehouse-dashboard',
                      '/warehouses',
                      '/materials',
                      '/suppliers',
                      '/products',
                      '/units',
                      '/dye-colors',
                      '/import-declarations',
                      '/purchase-orders',
                      '/stock-in',
                      '/material-exports',
                      '/inventorys',
                      '/batches',
                    ],
                    children: [
                      _buildSubMenuItem(
                        Icons.dashboard_customize,
                        "Tổng quan Kho",
                        '/warehouse-dashboard',
                      ),
                      _buildSubMenuItem(
                        Icons.storefront_rounded,
                        l10n.generalInfo,
                        '#info',
                        isDummy: true,
                      ),
                      _buildLevel3MenuItem(
                        Icons.store_mall_directory,
                        l10n.warehouseTitle,
                        '/warehouses',
                      ),
                      _buildLevel3MenuItem(
                        Icons.layers,
                        l10n.materialTitle,
                        '/materials',
                      ),
                      _buildLevel3MenuItem(
                        Icons.local_shipping,
                        l10n.supplierTitle,
                        '/suppliers',
                      ),
                      _buildLevel3MenuItem(
                        Icons.shopping_bag,
                        l10n.productTitle,
                        '/products',
                      ),

                      _buildSubMenuItem(
                        Icons.receipt_long_rounded,
                        l10n.materialPurchaseOrders,
                        '#po',
                        isDummy: true,
                      ),
                      _buildLevel3MenuItem(
                        Icons.description,
                        l10n.importDeclarationTitle,
                        '/import-declarations',
                      ),
                      _buildLevel3MenuItem(
                        Icons.shopping_cart_checkout,
                        l10n.purchaseOrderTitle,
                        '/purchase-orders',
                      ),

                      _buildSubMenuItem(
                        Icons.swap_horiz_rounded,
                        l10n.importExport,
                        '#ie',
                        isDummy: true,
                      ),
                      _buildLevel3MenuItem(
                        Icons.move_to_inbox,
                        l10n.stockInTitle,
                        '/stock-in',
                      ),
                      _buildLevel3MenuItem(
                        Icons.output,
                        l10n.materialExport,
                        '/material-exports',
                      ),

                      _buildSubMenuItem(
                        Icons.grid_view_rounded,
                        l10n.inventoryStock,
                        '/inventorys',
                      ),
                      _buildSubMenuItem(
                        Icons.fact_check_rounded,
                        l10n.batchManagement,
                        '/batches',
                      ),
                    ],
                  ),

                  _buildSectionDivider('PRODUCTION'),
                  _buildExpansionGroup(
                    context: context,
                    icon: Icons.precision_manufacturing_rounded,
                    title: l10n.production,
                    // Bổ sung '/production-dashboard' vào danh sách active
                    childrenRoutes: [
                      '/production-dashboard',
                      '/machines',
                      '/baskets',
                      '/machine-operation',
                      '/boms',
                      '/standards',
                    ],
                    children: [
                      // Nút trỏ về màn hình Production Dashboard
                      _buildSubMenuItem(
                        Icons.dashboard_customize,
                        "Bảng ĐK Sản xuất",
                        '/production-dashboard',
                      ),
                      _buildSubMenuItem(
                        Icons.settings_input_component,
                        l10n.machineTitle,
                        '/machines',
                      ),
                      _buildSubMenuItem(
                        Icons.all_inbox,
                        l10n.basketTitle,
                        '/baskets',
                      ),
                      _buildSubMenuItem(
                        Icons.auto_mode_rounded,
                        l10n.machineBasketInfo,
                        '/machine-operation',
                      ),
                    ],
                  ),

                  _buildExpansionGroup(
                    context: context,
                    icon: Icons.verified_rounded,
                    title: "QC / Standards",
                    childrenRoutes: ['/boms', '/standards'],
                    children: [
                      _buildSubMenuItem(
                        Icons.account_tree,
                        l10n.bomTitle,
                        '/boms',
                      ),
                      _buildSubMenuItem(
                        Icons.assignment,
                        l10n.standardTitle,
                        '/standards',
                      ),
                    ],
                  ),

                  _buildSectionDivider('MANAGEMENT'),
                  _buildExpansionGroup(
                    context: context,
                    icon: Icons.people_alt_rounded,
                    title: l10n.hr,
                    childrenRoutes: [
                      '/hr-dashboard', // [MỚI] Thêm đường dẫn cho HR Dashboard
                      '/departments',
                      '/employees',
                      '/shifts',
                      '/schedules',
                    ],
                    children: [
                      // [MỚI] Nút trỏ về màn hình HR Dashboard
                      _buildSubMenuItem(
                        Icons.dashboard_customize,
                        "Tổng quan Nhân sự",
                        '/hr-dashboard',
                      ),
                      _buildSubMenuItem(
                        Icons.domain,
                        l10n.departmentTitle,
                        '/departments',
                      ),
                      _buildSubMenuItem(
                        Icons.badge,
                        l10n.employeeTitle,
                        '/employees',
                      ),
                      _buildSubMenuItem(
                        Icons.access_time,
                        l10n.shiftTitle,
                        '/shifts',
                      ),
                      _buildSubMenuItem(
                        Icons.calendar_month,
                        l10n.scheduleTitle,
                        '/schedules',
                      ),
                    ],
                  ),

                  if (isAdmin) ...[
                    _buildSectionDivider('SYSTEM'),
                    _buildExpansionGroup(
                      context: context,
                      icon: Icons.admin_panel_settings_rounded,
                      title: l10n.adminTitle,
                      childrenRoutes: ['/users', '/logs'],
                      children: [
                        _buildSubMenuItem(
                          Icons.manage_accounts,
                          l10n.userManagementTitle,
                          '/users',
                        ),
                        _buildSubMenuItem(
                          Icons.history,
                          l10n.activityLog,
                          '/logs',
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPERS ---
  Widget _buildSectionDivider(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 24, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String route) {
    final isActive = route != '#' && currentPath == route;
    return _SidebarItem(
      icon: icon,
      title: title,
      isActive: isActive,
      onTap: () => onNavigate(route),
      paddingLeft: 20,
    );
  }

  Widget _buildSubMenuItem(
    IconData icon,
    String title,
    String route, {
    bool isDummy = false,
  }) {
    final isActive = !isDummy && currentPath.startsWith(route);
    return _SidebarItem(
      icon: icon,
      title: title,
      isActive: isActive,
      onTap: () => isDummy ? null : onNavigate(route),
      paddingLeft: 40,
      iconSize: 18,
      fontSize: 13,
      isSubItem: true,
      textColor: isDummy ? Colors.white54 : null,
    );
  }

  Widget _buildLevel3MenuItem(IconData icon, String title, String route) {
    final isActive = currentPath.startsWith(route);
    return _SidebarItem(
      icon: icon,
      title: title,
      isActive: isActive,
      onTap: () => onNavigate(route),
      paddingLeft: 60,
      iconSize: 16,
      fontSize: 12,
      isSubItem: true,
    );
  }

  Widget _buildExpansionGroup({
    required BuildContext context,
    required IconData icon,
    required String title,
    required List<String> childrenRoutes,
    required List<Widget> children,
  }) {
    final isExpanded = childrenRoutes.any((r) => currentPath.startsWith(r));

    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        splashColor: Colors.white.withOpacity(0.05),
        highlightColor: Colors.transparent,
      ),
      child: ExpansionTile(
        initiallyExpanded: isExpanded,
        leading: Icon(
          icon,
          color: isExpanded ? Colors.white : Colors.white70,
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isExpanded ? Colors.white : Colors.white70,
            fontWeight: isExpanded ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        iconColor: Colors.white,
        collapsedIconColor: Colors.white70,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        tilePadding: const EdgeInsets.symmetric(horizontal: 20),
        children: children,
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isActive;
  final VoidCallback onTap;
  final double paddingLeft;
  final double iconSize;
  final double fontSize;
  final bool isSubItem;
  final Color? textColor;

  const _SidebarItem({
    required this.icon,
    required this.title,
    required this.isActive,
    required this.onTap,
    this.paddingLeft = 20,
    this.iconSize = 22,
    this.fontSize = 14,
    this.isSubItem = false,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isActive
                ? Colors.white.withOpacity(0.1)
                : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: isActive && !isSubItem
                    ? Colors.white
                    : Colors.transparent,
                width: 4,
              ),
            ),
          ),
          padding: EdgeInsets.only(
            left: isActive && !isSubItem ? paddingLeft - 4 : paddingLeft,
            right: 20,
            top: 12,
            bottom: 12,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isActive ? Colors.white : (textColor ?? Colors.white70),
                size: iconSize,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isActive
                        ? Colors.white
                        : (textColor ?? Colors.white70),
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    fontSize: fontSize,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
