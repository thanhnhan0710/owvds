import 'dart:async';
import 'package:flutter/material.dart' hide MaterialState;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'dart:convert';
import 'dart:html' as html;

import 'package:owvds/features/inventory/material_inventory/domain/material_inventory_model.dart';
import 'package:owvds/features/inventory/material_inventory/presentation/dialogs/inventory_adjustment_dialog.dart';
import 'package:owvds/features/inventory/material_inventory/presentation/dialogs/warehouse_management_dialog.dart';
import 'package:owvds/features/inventory/material_inventory/presentation/dialogs/inventory_create_dialog.dart';

import '../../../../home/presentation/widgets/admin_sidebar.dart';
import '../../../../../core/widgets/responsive_layout.dart';
import '../../../../../core/network/websocket_service.dart';

import '../bloc/material_inventory_cubit.dart';
import '../../../warehouse/presentation/bloc/warehouse_cubit.dart';
import '../../../../inventory/material/presentation/bloc/material_cubit.dart';
import '../../../../inventory/material/domain/material_model.dart';

class MaterialInventoryScreen extends StatefulWidget {
  const MaterialInventoryScreen({super.key});

  @override
  State<MaterialInventoryScreen> createState() =>
      _MaterialInventoryScreenState();
}

class _MaterialInventoryScreenState extends State<MaterialInventoryScreen> {
  final Color _primaryColor = const Color(0xFF003366);
  final Color _bgColor = const Color(0xFFF5F7FA);
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  int? _selectedWarehouseId;

  @override
  void initState() {
    super.initState();
    context.read<MaterialInventoryCubit>().loadInventories();
    context.read<WarehouseCubit>().loadWarehouses();
    context.read<MaterialCubit>().loadMaterials();

    WebSocketService().connect();
    WebSocketService().addListener(_onWebSocketMessage);
  }

  void _onWebSocketMessage(String message) {
    if (!mounted) return;
    if (message == "REFRESH_MATERIAL_INVENTORIES") {
      context.read<MaterialInventoryCubit>().loadInventories(
        warehouseId: _selectedWarehouseId,
      );
    }
  }

  @override
  void dispose() {
    WebSocketService().removeListener(_onWebSocketMessage);
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String keyword) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<MaterialInventoryCubit>().searchInventories(keyword);
    });
  }

  void _onNavigate(String route) {
    if (ResponsiveLayout.isMobile(context) &&
        _scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.pop(context);
    }
    if (route != '#') context.go(route);
  }

  void _onWarehouseSelected(int? warehouseId) {
    setState(() => _selectedWarehouseId = warehouseId);
    context.read<MaterialInventoryCubit>().loadInventories(
      warehouseId: warehouseId,
    );
  }

  void _saveExcelFile(List<int> bytes, String fileName) {
    try {
      final base64data = base64Encode(bytes);
      final a =
          html.AnchorElement(
              href:
                  'data:application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;base64,$base64data',
            )
            ..setAttribute("download", "$fileName.xlsx")
            ..target = "blank";

      html.document.body?.append(a);
      a.click();
      a.remove();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Xuất file Excel thành công! Đang tải xuống...'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi tải file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  MaterialItem? _getMaterialInfo(int id) {
    final state = context.read<MaterialCubit>().state;
    if (state is MaterialLoaded) {
      return state.materials.where((x) => x.materialId == id).firstOrNull;
    }
    return null;
  }

  String _getWarehouseName(int id) {
    final state = context.read<WarehouseCubit>().state;
    if (state is WarehouseLoaded) {
      return state.warehouses
              .where((x) => x.warehouseId == id)
              .firstOrNull
              ?.name ??
          'Kho: $id';
    }
    return 'Kho: $id';
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isMobile = ResponsiveLayout.isMobile(context);

    context.watch<MaterialCubit>();
    context.watch<WarehouseCubit>();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _bgColor,
      appBar: isDesktop
          ? null
          : AppBar(
              title: const Text(
                "Tồn Kho NVL",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              backgroundColor: Colors.white,
              foregroundColor: _primaryColor,
              elevation: 0.5,
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'add') {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (ctx) => const InventoryCreateDialog(),
                      );
                    } else if (value == 'export') {
                      context.read<MaterialInventoryCubit>().exportExcel();
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'add',
                          child: Row(
                            children: [
                              Icon(
                                Icons.add_to_photos,
                                color: Colors.teal,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text('Thêm Tồn kho'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'export',
                          child: Row(
                            children: [
                              Icon(
                                Icons.file_download,
                                color: Colors.green,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text('Xuất Excel'),
                            ],
                          ),
                        ),
                      ],
                ),
              ],
            ),
      drawer: isDesktop
          ? null
          : Drawer(
              child: AdminSidebar(
                currentPath: '/inventorys',
                isAdmin: true,
                onNavigate: _onNavigate,
              ),
            ),

      body: BlocListener<MaterialInventoryCubit, MaterialInventoryState>(
        listener: (context, state) {
          if (state is MaterialInventoryExportSuccess) {
            _saveExcelFile(state.bytes, state.fileName);
          } else if (state is MaterialInventoryError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isDesktop)
              AdminSidebar(
                currentPath: '/inventorys',
                isAdmin: true,
                onNavigate: _onNavigate,
              ),
            Expanded(
              child: Column(
                children: [
                  if (isDesktop)
                    Container(
                      height: 64,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            "Quản Lý Tồn Kho NVL",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: _primaryColor,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(
                              Icons.refresh,
                              color: Colors.blueGrey,
                            ),
                            onPressed: () {
                              context
                                  .read<MaterialInventoryCubit>()
                                  .loadInventories(
                                    warehouseId: _selectedWarehouseId,
                                  );
                              context.read<WarehouseCubit>().loadWarehouses();
                            },
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: () => showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (ctx) => const InventoryCreateDialog(),
                            ),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text("Thêm Tồn Kho"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () => context
                                .read<MaterialInventoryCubit>()
                                .exportExcel(),
                            icon: const Icon(Icons.download, size: 16),
                            label: const Text("Xuất Excel"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                  Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: isMobile ? 1 : 0,
                              child: SizedBox(
                                width: isMobile ? double.infinity : 400,
                                child: TextField(
                                  controller: _searchCtrl,
                                  onChanged: _onSearch,
                                  decoration: InputDecoration(
                                    hintText: "Tìm kiếm mã lô, vị trí...",
                                    prefixIcon: const Icon(
                                      Icons.search,
                                      size: 18,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 0,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),

                            // BỘ LỌC CẢNH BÁO TỒN KHO TỐI THIỂU
                            BlocBuilder<
                              MaterialInventoryCubit,
                              MaterialInventoryState
                            >(
                              buildWhen: (previous, current) =>
                                  current is MaterialInventoryLoaded,
                              builder: (context, state) {
                                bool isLowStockActive = false;
                                if (state is MaterialInventoryLoaded) {
                                  isLowStockActive = state.isLowStockFilter;
                                }

                                return FilterChip(
                                  avatar: Icon(
                                    isLowStockActive
                                        ? Icons.warning
                                        : Icons.warning_amber_rounded,
                                    color: isLowStockActive
                                        ? Colors.red.shade700
                                        : Colors.red.shade400,
                                    size: 18,
                                  ),
                                  label: Text(
                                    isMobile ? "Sắp hết" : "Sắp hết hàng",
                                    style: TextStyle(
                                      color: isLowStockActive
                                          ? Colors.red.shade900
                                          : Colors.red.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  selected: isLowStockActive,
                                  selectedColor: Colors.red.shade50,
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(
                                      color: isLowStockActive
                                          ? Colors.red
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                  onSelected: (val) {
                                    context
                                        .read<MaterialInventoryCubit>()
                                        .toggleLowStockFilter(val);
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: BlocBuilder<WarehouseCubit, WarehouseState>(
                                builder: (context, state) {
                                  if (state is WarehouseLoaded) {
                                    return SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              right: 8.0,
                                            ),
                                            child: ChoiceChip(
                                              label: const Text("Tất cả kho"),
                                              selected:
                                                  _selectedWarehouseId == null,
                                              selectedColor: _primaryColor
                                                  .withOpacity(0.1),
                                              labelStyle: TextStyle(
                                                fontWeight:
                                                    _selectedWarehouseId == null
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                                color:
                                                    _selectedWarehouseId == null
                                                    ? _primaryColor
                                                    : Colors.black87,
                                              ),
                                              onSelected: (_) =>
                                                  _onWarehouseSelected(null),
                                            ),
                                          ),
                                          ...state.warehouses.map((w) {
                                            final currentId = w.warehouseId;
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                right: 8.0,
                                              ),
                                              child: ChoiceChip(
                                                label: Text(w.name),
                                                selected:
                                                    _selectedWarehouseId ==
                                                    currentId,
                                                selectedColor: _primaryColor
                                                    .withOpacity(0.1),
                                                labelStyle: TextStyle(
                                                  fontWeight:
                                                      _selectedWarehouseId ==
                                                          currentId
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                  color:
                                                      _selectedWarehouseId ==
                                                          currentId
                                                      ? _primaryColor
                                                      : Colors.black87,
                                                ),
                                                onSelected: (_) =>
                                                    _onWarehouseSelected(
                                                      currentId,
                                                    ),
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                    );
                                  }
                                  return const SizedBox(
                                    height: 32,
                                    child: Text("Đang tải danh sách kho..."),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () => showDialog(
                                context: context,
                                builder: (ctx) =>
                                    const WarehouseManagementDialog(),
                              ),
                              icon: const Icon(Icons.settings, size: 16),
                              label: isMobile
                                  ? const SizedBox()
                                  : const Text("Quản lý Kho"),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 8 : 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 24,
                      ).copyWith(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child:
                          BlocBuilder<
                            MaterialInventoryCubit,
                            MaterialInventoryState
                          >(
                            builder: (context, state) {
                              if (state is MaterialInventoryLoading)
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );

                              if (state is MaterialInventoryLoaded) {
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // NỘI DUNG DANH SÁCH
                                    Expanded(
                                      child: state.inventories.isEmpty
                                          ? Center(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.inventory_2_outlined,
                                                    size: 64,
                                                    color: Colors.grey.shade300,
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Text(
                                                    "Không có dữ liệu tồn kho cho bộ lọc này.",
                                                    style: TextStyle(
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : (isMobile
                                                ? _buildMobileList(
                                                    state.inventories,
                                                  )
                                                : _buildDesktopTable(
                                                    state.inventories,
                                                  )),
                                    ),

                                    // THANH PHÂN TRANG
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          top: BorderSide(
                                            color: Colors.grey.shade200,
                                          ),
                                        ),
                                        color: Colors.grey.shade50,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            "Trang ${state.currentPage}",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          OutlinedButton(
                                            onPressed: state.currentPage > 1
                                                ? () => context
                                                      .read<
                                                        MaterialInventoryCubit
                                                      >()
                                                      .changePage(
                                                        state.currentPage - 1,
                                                      )
                                                : null,
                                            child: const Text("Trước"),
                                          ),
                                          const SizedBox(width: 8),
                                          OutlinedButton(
                                            onPressed: state.hasNextPage
                                                ? () => context
                                                      .read<
                                                        MaterialInventoryCubit
                                                      >()
                                                      .changePage(
                                                        state.currentPage + 1,
                                                      )
                                                : null,
                                            child: const Text("Sau"),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }
                              return const SizedBox();
                            },
                          ),
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

  Widget _buildDesktopTable(List<MaterialInventory> inventories) {
    final numFmt = NumberFormat("#,##0.##", "en_US");
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
          dataRowMaxHeight: 60,
          columns: const [
            DataColumn(
              label: Text(
                'Kho / Vị trí',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Mã NVL',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Lô / PO / Pallet',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Khả dụng (Kg)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Khả dụng (Cuộn)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Giữ chỗ (Kg)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Thao tác',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: inventories.map((inv) {
            final matInfo = _getMaterialInfo(inv.materialId);
            final matCode = matInfo?.materialCode ?? 'ID: ${inv.materialId}';
            bool isLowStock = false;

            if (matInfo != null && matInfo.minStockLevel > 0) {
              if (inv.quantityKg < matInfo.minStockLevel) {
                isLowStock = true;
              }
            }

            return DataRow(
              cells: [
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getWarehouseName(inv.warehouseId),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        "Bin: ${inv.location}",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        matCode,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                      if (isLowStock) ...[
                        const SizedBox(width: 8),
                        Tooltip(
                          message:
                              "Cảnh báo: Dưới mức tồn kho tối thiểu (${matInfo!.minStockLevel} Kg)",
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.red,
                            size: 18,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        inv.batchCode ?? "Batch-${inv.batchId}",
                        style: TextStyle(
                          color: Colors.purple.shade700,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "PO: ${inv.poNumber ?? 'N/A'} | Plt: ${inv.numberOfPallets ?? 0}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(
                  Text(
                    "${numFmt.format(inv.quantityKg)} Kg",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isLowStock ? Colors.red : Colors.green,
                    ),
                  ),
                ),
                DataCell(Text(numFmt.format(inv.quantityCones))),
                DataCell(
                  Text(
                    numFmt.format(inv.reservedQuantityKg),
                    style: const TextStyle(color: Colors.orange),
                  ),
                ),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.edit_note, color: Colors.blueGrey),
                    tooltip: "Điều chỉnh / Chuyển vị trí",
                    onPressed: () => _openAdjustmentDialog(inv),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMobileList(List<MaterialInventory> inventories) {
    final numFmt = NumberFormat("#,##0.##", "en_US");

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: inventories.length,
      itemBuilder: (context, index) {
        final inv = inventories[index];
        final matInfo = _getMaterialInfo(inv.materialId);
        final matCode = matInfo?.materialCode ?? 'ID: ${inv.materialId}';
        bool isLowStock = false;

        if (matInfo != null && matInfo.minStockLevel > 0) {
          if (inv.quantityKg < matInfo.minStockLevel) {
            isLowStock = true;
          }
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isLowStock ? Colors.red.shade200 : Colors.grey.shade200,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            children: [
                              Text(
                                matCode,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.blue,
                                ),
                              ),
                              if (isLowStock)
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.red,
                                  size: 18,
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Kho: ${_getWarehouseName(inv.warehouseId)}",
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.edit_note,
                        color: Colors.blueGrey,
                        size: 28,
                      ),
                      onPressed: () => _openAdjustmentDialog(inv),
                    ),
                  ],
                ),
                const Divider(height: 24),

                Wrap(
                  spacing: 24,
                  runSpacing: 12,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Khả dụng (Kg)",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blueGrey,
                          ),
                        ),
                        Text(
                          numFmt.format(inv.quantityKg),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isLowStock ? Colors.red : Colors.green,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Cuộn",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blueGrey,
                          ),
                        ),
                        Text(
                          numFmt.format(inv.quantityCones),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Giữ chỗ",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blueGrey,
                          ),
                        ),
                        Text(
                          "${numFmt.format(inv.reservedQuantityKg)} kg",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          _buildInfoItem(
                            Icons.qr_code,
                            "Lô:",
                            inv.batchCode ?? inv.batchId.toString(),
                          ),
                          _buildInfoItem(
                            Icons.shopping_cart_outlined,
                            "PO:",
                            inv.poNumber ?? 'N/A',
                          ),
                          _buildInfoItem(
                            Icons.place_outlined,
                            "Vị trí:",
                            inv.location,
                          ),
                          _buildInfoItem(
                            Icons.inventory_2_outlined,
                            "Pallet:",
                            (inv.numberOfPallets ?? 0).toString(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (isLowStock) ...[
                  const SizedBox(height: 12),
                  Text(
                    "⚠️ Cảnh báo: Số lượng dưới mức tối thiểu (${matInfo!.minStockLevel} Kg)",
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          "$label ",
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }

  void _openAdjustmentDialog(MaterialInventory inventory) {
    showDialog(
      context: context,
      builder: (ctx) => InventoryAdjustmentDialog(inventory: inventory),
    );
  }
}
