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

class PurchaseOrderScreen extends StatefulWidget {
  const PurchaseOrderScreen({super.key});

  @override
  State<PurchaseOrderScreen> createState() => _PurchaseOrderScreenState();
}

class _PurchaseOrderScreenState extends State<PurchaseOrderScreen> {
  final Color _primaryColor = const Color(0xFF003366);
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  int? _selectedStatusId; // [MỚI]: State lưu vết đang chọn trạng thái nào
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

  // [MỚI]: Hàm xử lý khi click chọn Trạng thái lọc
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

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F7FA),
      drawer: isMobile ? const Drawer() : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
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
                  IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Quản lý Đơn Mua Hàng (PO)",
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 24,
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                      ),
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
                if (!isMobile)
                  Row(
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

          // TOOLBAR & FILTER
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

                // [MỚI]: Thanh Filter trạng thái (ChoiceChips)
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

          // DANH SÁCH BẢNG
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
