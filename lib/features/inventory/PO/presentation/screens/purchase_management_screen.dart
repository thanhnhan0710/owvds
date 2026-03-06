import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_saver/file_saver.dart'; // [MỚI]: Thư viện lưu file
import 'package:owvds/features/inventory/PO/incoterm/presentation/bloc/incoterm_cubit.dart';
import 'package:owvds/features/inventory/PO/po_header/presentation/bloc/po_header_cubit.dart';
import 'package:owvds/features/inventory/PO/po_status/presentation/bloc/po_status_cubit.dart';

import '../../../../../core/network/websocket_service.dart';
import '../../../../../core/widgets/responsive_layout.dart';

import '../../../../inventory/supplier/presentation/bloc/supplier_cubit.dart';

import '../widgets/po_list_view.dart';
import '../widgets/po_detail_drawer.dart';
import '../dialogs/incoterm_management_dialog.dart';
import '../dialogs/po_status_management_dialog.dart';

class POManagementScreen extends StatefulWidget {
  const POManagementScreen({super.key});

  @override
  State<POManagementScreen> createState() => _POManagementScreenState();
}

class _POManagementScreenState extends State<POManagementScreen> {
  final Color _primaryColor = const Color(0xFF003366);
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  String _timeFilter = 'Hôm nay';
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
    context.read<POHeaderCubit>().loadPOs(statusId: statusId);
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
              width: ResponsiveLayout.isMobile(context)
                  ? double.infinity
                  : 1100, // Tăng nhẹ size do thêm cột
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

    // [ĐÃ SỬA]: Thêm BlocListener bọc toàn bộ Scaffold để hứng sự kiện tải file
    return BlocListener<POHeaderCubit, POHeaderState>(
      listener: (context, state) async {
        if (state is POHeaderExportSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Đang tải file Excel...")),
          );
          try {
            await FileSaver.instance.saveFile(
              name:
                  '${state.fileName}_${DateTime.now().millisecondsSinceEpoch}.xlsx',
              bytes: state.bytes,
              mimeType: MimeType.microsoftExcel,
            );
            if (mounted)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Tải Excel thành công!"),
                  backgroundColor: Colors.green,
                ),
              );
          } catch (e) {
            if (mounted)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Lỗi lưu file: $e"),
                  backgroundColor: Colors.red,
                ),
              );
          }
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF5F7FA),
        drawer: isMobile ? const Drawer() : null,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (isMobile)
                        Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: IconButton(
                            icon: const Icon(Icons.menu),
                            onPressed: () =>
                                _scaffoldKey.currentState?.openDrawer(),
                          ),
                        ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Quản lý Đơn Mua Hàng",
                            style: TextStyle(
                              fontSize: isMobile ? 20 : 24,
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
                          icon: const Icon(Icons.tag, size: 16),
                          label: const Text("Trạng thái PO"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey.shade700,
                          ),
                          onPressed: () => showDialog(
                            context: context,
                            builder: (_) => const POStatusManagementDialog(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text("Thêm PO Mới"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                          onPressed: _openPODrawer,
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // --- BỘ LỌC ---
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Flex(
                direction: isMobile ? Axis.vertical : Axis.horizontal,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: isMobile
                    ? CrossAxisAlignment.stretch
                    : CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: isMobile ? double.infinity : 350,
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: _onSearch,
                      decoration: InputDecoration(
                        hintText: 'Tìm theo Số PO, NCC...',
                        prefixIcon: const Icon(Icons.search, size: 18),
                        filled: true,
                        fillColor: Colors.white,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                  ),
                  if (isMobile) const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children:
                            [
                              'Hôm nay',
                              'Tuần này',
                              'Tháng này',
                              'Quý này',
                              'Năm nay',
                            ].map((time) {
                              bool isActive = _timeFilter == time;
                              return InkWell(
                                onTap: () => setState(() => _timeFilter = time),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? Colors.white
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: isActive
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.05,
                                              ),
                                              blurRadius: 4,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Text(
                                    time,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isActive
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isActive
                                          ? _primaryColor
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- TABS & EXPORT ---
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: BlocBuilder<POStatusCubit, POStatusState>(
                      builder: (context, state) {
                        if (state is POStatusLoaded) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildStatusPill(null, "Tất cả", true),
                                ...state.statuses.map(
                                  (s) => _buildStatusPill(
                                    s.statusId,
                                    s.statusCode,
                                    false,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  if (!isMobile)
                    ElevatedButton.icon(
                      // [ĐÃ SỬA]: Gọi sự kiện tải Excel
                      onPressed: () =>
                          context.read<POHeaderCubit>().exportExcel(),
                      icon: const Icon(Icons.file_download, size: 16),
                      label: const Text("Xuất Excel"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade50,
                        foregroundColor: Colors.green.shade700,
                        elevation: 0,
                        side: BorderSide(color: Colors.green.shade200),
                      ),
                    ),
                ],
              ),
            ),

            // --- DANH SÁCH BẢNG ---
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
      ),
    );
  }

  Widget _buildStatusPill(int? statusId, String label, bool isAll) {
    bool isSelected = _selectedStatusId == statusId;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: () => _onStatusFilterChanged(statusId),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isAll
                      ? _primaryColor.withOpacity(0.1)
                      : Colors.orange.shade50)
                : Colors.white,
            border: Border.all(
              color: isSelected
                  ? (isAll
                        ? _primaryColor.withOpacity(0.3)
                        : Colors.orange.shade200)
                  : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? (isAll ? _primaryColor : Colors.orange.shade700)
                  : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }
}
