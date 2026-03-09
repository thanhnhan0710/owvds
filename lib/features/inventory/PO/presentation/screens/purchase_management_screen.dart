import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/network/websocket_service.dart';
import '../../../../../core/widgets/responsive_layout.dart';

import '../../incoterm/presentation/bloc/incoterm_cubit.dart';
import '../../po_status/presentation/bloc/po_status_cubit.dart';
import '../../../../inventory/supplier/presentation/bloc/supplier_cubit.dart';
import '../../po_header/presentation/bloc/po_header_cubit.dart';

import '../widgets/po_list_view.dart';
import '../widgets/po_detail_drawer.dart';
import '../dialogs/incoterm_management_dialog.dart';
import '../dialogs/po_status_management_dialog.dart';

class PurchaseManagementScreen extends StatefulWidget {
  const PurchaseManagementScreen({super.key});

  @override
  State<PurchaseManagementScreen> createState() =>
      _PurchaseManagementScreenState();
}

class _PurchaseManagementScreenState extends State<PurchaseManagementScreen> {
  final Color _primaryColor = const Color(0xFF003366);
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  int? _selectedStatusId;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    context.read<POHeaderCubit>().loadPOs();
    context.read<SupplierCubit>().loadSuppliers();
    context.read<IncotermCubit>().loadIncoterms();
    context.read<POStatusCubit>().loadStatuses();

    WebSocketService().connect();
    WebSocketService().addListener(_onWsMessage);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    WebSocketService().removeListener(_onWsMessage);
    super.dispose();
  }

  void _onWsMessage(String message) {
    if (!mounted) return;
    if (message == "REFRESH_PURCHASE_ORDERS") {
      context.read<POHeaderCubit>().refreshCurrent();
    } else if (message == "REFRESH_INCOTERMS") {
      context.read<IncotermCubit>().loadIncoterms();
    } else if (message == "REFRESH_PO_STATUSES") {
      context.read<POStatusCubit>().loadStatuses();
    }
  }

  void _onSearch(String val) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<POHeaderCubit>().searchPOs(val);
    });
  }

  void _onStatusFilterChanged(int? statusId) {
    setState(() => _selectedStatusId = statusId);
    context.read<POHeaderCubit>().filterByStatus(statusId);
  }

  void _openPODrawer() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "PODrawer",
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: ResponsiveLayout.isMobile(context) ? double.infinity : 900,
              height: double.infinity,
              child: const PODetailDrawer(po: null),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        );
      },
    );
  }

  // [MỚI]: Hàm tạo giao diện Drawer cho Mobile
  Widget _buildMobileDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: _primaryColor),
            child: const SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.shopping_cart_checkout,
                    color: Colors.white,
                    size: 36,
                  ),
                  SizedBox(height: 12),
                  Text(
                    "Danh mục Đơn hàng",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Cấu hình dữ liệu PO",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.settings_input_component,
              color: Colors.blueGrey,
            ),
            title: const Text(
              'Quản lý Incoterms',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            trailing: const Icon(Icons.chevron_right, size: 16),
            onTap: () {
              Navigator.pop(context); // Đóng menu trượt
              showDialog(
                context: context,
                builder: (_) => const IncotermManagementDialog(),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.local_offer, color: Colors.blueGrey),
            title: const Text(
              'Quản lý Trạng thái PO',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            trailing: const Icon(Icons.chevron_right, size: 16),
            onTap: () {
              Navigator.pop(context); // Đóng menu trượt
              showDialog(
                context: context,
                builder: (_) => const POStatusManagementDialog(),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F7FA),
      // [ĐÃ SỬA]: Gọi hàm _buildMobileDrawer thay vì const Drawer() trống
      drawer: isMobile ? _buildMobileDrawer(context) : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==========================================
          // HEADER (ĐÃ SỬA LỖI OVERFLOW FLEX)
          // ==========================================
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isMobile)
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    ),
                  ),

                // [ĐÃ SỬA]: Bọc Tiêu đề bằng Expanded để nó tự động co ngắn chữ lại khi màn hình thiếu không gian
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Quản lý Đơn Mua Hàng (PO)",
                        style: TextStyle(
                          fontSize: isMobile ? 18 : 24,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      BlocBuilder<POHeaderCubit, POHeaderState>(
                        builder: (context, state) {
                          int count = (state is POHeaderLoaded)
                              ? state.totalCount
                              : 0;
                          return Text(
                            "Tổng cộng: $count đơn hàng",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  width: 16,
                ), // Khoảng cách giữa Tiêu đề và Nút bấm
                // Khối nút thao tác
                if (!isMobile)
                  Row(
                    mainAxisSize: MainAxisSize
                        .min, // Đảm bảo Row này chỉ chiếm đúng phần không gian cần thiết
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(
                          Icons.settings_input_component,
                          size: 16,
                        ),
                        label: const Text("Incoterms"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                        ),
                        onPressed: () => showDialog(
                          context: context,
                          builder: (_) => const IncotermManagementDialog(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.local_offer, size: 16),
                        label: const Text("Trạng thái"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                        ),
                        onPressed: () => showDialog(
                          context: context,
                          builder: (_) => const POStatusManagementDialog(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text("Thêm PO Mới"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _openPODrawer,
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // ==========================================
          // TOOLBAR & FILTER
          // ==========================================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: isMobile ? double.infinity : 350,
                  child: _buildSearchBar(),
                ),
                const SizedBox(height: 16),

                // Thanh Filter trạng thái (ChoiceChips)
                BlocBuilder<POStatusCubit, POStatusState>(
                  builder: (context, state) {
                    if (state is POStatusLoaded) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: const Text("Tất cả PO"),
                                selected: _selectedStatusId == null,
                                selectedColor: _primaryColor.withOpacity(0.1),
                                labelStyle: TextStyle(
                                  fontWeight: _selectedStatusId == null
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: _selectedStatusId == null
                                      ? _primaryColor
                                      : Colors.black87,
                                ),
                                onSelected: (val) =>
                                    _onStatusFilterChanged(null),
                              ),
                            ),
                            ...state.statuses.map(
                              (s) => Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  label: Text(s.statusCode),
                                  selected: _selectedStatusId == s.statusId,
                                  selectedColor: _primaryColor.withOpacity(0.1),
                                  labelStyle: TextStyle(
                                    fontWeight: _selectedStatusId == s.statusId
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: _selectedStatusId == s.statusId
                                        ? _primaryColor
                                        : Colors.black87,
                                  ),
                                  onSelected: (val) =>
                                      _onStatusFilterChanged(s.statusId),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ],
            ),
          ),

          // ==========================================
          // DANH SÁCH BẢNG
          // ==========================================
          const Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: POListView(),
            ),
          ),
        ],
      ),
      floatingActionButton: isMobile
          ? FloatingActionButton(
              backgroundColor: _primaryColor,
              onPressed: _openPODrawer,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchCtrl,
      onChanged: _onSearch,
      decoration: InputDecoration(
        hintText: 'Tìm kiếm theo số PO...',
        prefixIcon: const Icon(Icons.search, size: 18),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}
