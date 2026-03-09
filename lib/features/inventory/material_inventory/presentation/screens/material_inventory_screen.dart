import 'dart:async';
import 'package:flutter/material.dart' hide MaterialState;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

// [LƯU Ý]: Đảm bảo import đúng đường dẫn model Warehouse của bạn
import 'package:owvds/features/inventory/material_inventory/domain/material_inventory_model.dart';
import 'package:owvds/features/inventory/material_inventory/presentation/dialogs/inventory_adjustment_dialog.dart';
import 'package:owvds/features/inventory/material_inventory/presentation/dialogs/warehouse_management_dialog.dart';

import '../../../../home/presentation/widgets/admin_sidebar.dart';
import '../../../../../core/widgets/responsive_layout.dart';
import '../bloc/material_inventory_cubit.dart';
import '../../../warehouse/presentation/bloc/warehouse_cubit.dart';

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
  }

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isMobile = ResponsiveLayout.isMobile(context);

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
      body: Row(
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
                          onPressed: () {},
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
                      SizedBox(
                        width: isMobile ? double.infinity : 400,
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: _onSearch,
                          decoration: InputDecoration(
                            hintText: "Tìm kiếm mã lô, vị trí...",
                            prefixIcon: const Icon(Icons.search, size: 18),
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
                                          // [SỬA LỖI ID]: Kiểm tra w.id, nếu model của bạn là w.warehouseId thì hãy đổi .id thành .warehouseId nhé
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
                            if (state is MaterialInventoryLoading) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (state is MaterialInventoryError) {
                              return Center(
                                child: Text(
                                  state.message,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              );
                            }
                            if (state is MaterialInventoryLoaded) {
                              if (state.inventories.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
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
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              if (isMobile) {
                                return _buildMobileList(state.inventories);
                              }
                              return _buildDesktopTable(state.inventories);
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
    );
  }

  Widget _buildDesktopTable(List<MaterialInventory> inventories) {
    final numFmt = NumberFormat("#,##0.##", "en_US");
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          // [SỬA LỖI Colors.slate]: Đổi thành Colors.grey
          headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
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
                'Mã Lô',
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
            return DataRow(
              cells: [
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Kho ID: ${inv.warehouseId}",
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
                  Text(
                    "NVL-${inv.materialId}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.purple.shade100),
                    ),
                    child: Text(
                      "Batch-${inv.batchId}",
                      style: TextStyle(
                        color: Colors.purple.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    numFmt.format(inv.quantityKg),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
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
    return ListView.separated(
      itemCount: inventories.length,
      // [SỬA LỖI ĐẶT TÊN BIẾN]: Đổi (_, __) thành (context, index)
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final inv = inventories[index];
        return ListTile(
          contentPadding: const EdgeInsets.all(16),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "NVL-${inv.materialId}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              Text(
                "${numFmt.format(inv.quantityKg)} Kg",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text("Kho: ${inv.warehouseId} | Vị trí: ${inv.location}"),
              Text("Lô: Batch-${inv.batchId} | Cuộn: ${inv.quantityCones}"),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.edit_note, color: Colors.blueGrey),
            onPressed: () => _openAdjustmentDialog(inv),
          ),
        );
      },
    );
  }

  void _openAdjustmentDialog(MaterialInventory inventory) {
    showDialog(
      context: context,
      builder: (ctx) => InventoryAdjustmentDialog(inventory: inventory),
    );
  }
}
