import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart'; // [MỚI]
import 'package:intl/intl.dart';
import 'package:owvds/core/network/websocket_service.dart';
import 'package:owvds/core/widgets/responsive_layout.dart';
import 'package:owvds/features/production/loom_state/product/presentation/bloc/product_cubit.dart';
import 'package:owvds/l10n/app_localizations.dart';

// Domain & Bloc
import '../../domain/bom_model.dart';
import '../bloc/bom_cubit.dart';

// Screens
import 'bom_detail_screen.dart';
import 'create_bom_screen.dart';

class BOMScreen extends StatefulWidget {
  final int? filterProductId;
  const BOMScreen({super.key, this.filterProductId});

  @override
  State<BOMScreen> createState() => _BOMScreenState();
}

class _BOMScreenState extends State<BOMScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  final Color _primaryColor = const Color(0xFF003366);
  final Color _bgLight = const Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    _loadData();
    context.read<ProductCubit>().loadProducts();

    // [MỚI] Đăng ký WebSocket
    WebSocketService().connect();
    WebSocketService().addListener(_onWebSocketMessage);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();

    // [MỚI] Hủy WebSocket
    WebSocketService().removeListener(_onWebSocketMessage);
    super.dispose();
  }

  // [MỚI] Xử lý Event WebSocket
  void _onWebSocketMessage(String message) {
    if (message == "REFRESH_BOMS") {
      debugPrint("WebSocket: Làm mới danh sách BOM.");
      if (mounted) _loadData();
    }
  }

  void _loadData() {
    context.read<BOMCubit>().loadBOMHeaders();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<BOMCubit>().searchBOMs(query);
    });
  }

  void _navigateToCreateOrEdit({BOMHeader? bom}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateBOMScreen(existingBOM: bom)),
    );

    if (result == true || result != null) {
      _loadData();
    }
  }

  void _navigateToDetailView(BOMHeader bom) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BOMDetailScreen(bomId: bom.bomId)),
    ).then((_) => _loadData());
  }

  // [MỚI] Xử lý chọn năm và Import file Excel
  void _onImportExcelPressed() async {
    // 1. Hiện popup hỏi "Năm áp dụng"
    final int currentYear = DateTime.now().year;
    final yearController = TextEditingController(text: currentYear.toString());

    final int? selectedYear = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Import BOM Excel"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Vui lòng nhập Năm áp dụng cho toàn bộ dữ liệu trong file:",
            ),
            const SizedBox(height: 12),
            TextField(
              controller: yearController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Năm áp dụng",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(yearController.text);
              if (val != null && val > 2000) {
                Navigator.pop(ctx, val);
              }
            },
            child: const Text("Next"),
          ),
        ],
      ),
    );

    if (selectedYear == null || !mounted) return;

    // 2. Mở hộp thoại chọn file
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xls', 'xlsx'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty && mounted) {
      // 3. Gửi lên Cubit
      context.read<BOMCubit>().importExcel(result.files.first, selectedYear);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _bgLight,
      body: SelectionArea(
        child: BlocConsumer<BOMCubit, BOMState>(
          listener: (context, state) {
            if (state is BOMError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
            if (state is BOMOperationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
          builder: (context, state) {
            List<BOMHeader> boms = [];
            bool isLoading = false;

            if (state is BOMLoading) {
              isLoading = true;
            } else if (state is BOMListLoaded) {
              boms = state.boms;
              if (widget.filterProductId != null) {
                boms = boms
                    .where((b) => b.productId == widget.filterProductId)
                    .toList();
              }
            } else if (state is BOMDetailViewLoaded) {
              return Center(
                child: CircularProgressIndicator(color: _primaryColor),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- HEADER SECTION ---
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.indigo.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.layers,
                              color: Colors.indigo.shade800,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              loc.bomTitle,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                                height: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          if (isDesktop) ...[
                            // [MỚI] NÚT EXPORT EXCEL
                            OutlinedButton.icon(
                              onPressed: () {
                                context.read<BOMCubit>().exportExcel();
                              },
                              icon: const Icon(Icons.download, size: 18),
                              label: const Text('EXPORT EXCEL'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.green.shade700,
                                side: BorderSide(color: Colors.green.shade700),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // [MỚI] NÚT IMPORT EXCEL
                            OutlinedButton.icon(
                              onPressed: _onImportExcelPressed,
                              icon: const Icon(Icons.upload_file, size: 18),
                              label: const Text('IMPORT EXCEL'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _primaryColor,
                                side: BorderSide(color: _primaryColor),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // NÚT CREATE
                            ElevatedButton.icon(
                              onPressed: () =>
                                  _navigateToCreateOrEdit(bom: null),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text("CREATE BOM"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),

                      // --- SEARCH BAR ---
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: _bgLight,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: TextField(
                                controller: _searchController,
                                textInputAction: TextInputAction.search,
                                onChanged: _onSearchChanged,
                                decoration: InputDecoration(
                                  hintText:
                                      "Search Year (e.g. 2026) or Product Code...",
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: Colors.grey.shade500,
                                    size: 20,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(
                                            Icons.clear,
                                            size: 18,
                                          ),
                                          onPressed: () {
                                            _searchController.clear();
                                            _onSearchChanged('');
                                            setState(() {});
                                          },
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: () =>
                                context.read<BOMCubit>().loadBOMHeaders(),
                            icon: const Icon(Icons.refresh, color: Colors.grey),
                            tooltip: "Refresh",
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(height: 1, color: Colors.grey.shade200),

                // --- CONTENT ---
                Expanded(
                  child: isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: _primaryColor,
                          ),
                        )
                      : boms.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.layers_clear,
                                size: 60,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                loc.noBOMFound,
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        )
                      : isDesktop
                      ? _buildDesktopTable(context, boms, loc)
                      : _buildMobileList(context, boms, loc),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: !isDesktop
          ? FloatingActionButton(
              backgroundColor: _primaryColor,
              onPressed: () => _navigateToCreateOrEdit(bom: null),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  // --- DESKTOP TABLE ---
  Widget _buildDesktopTable(
    BuildContext context,
    List<BOMHeader> items,
    AppLocalizations loc,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(
                      const Color(0xFFF9FAFB),
                    ),
                    horizontalMargin: 24,
                    columnSpacing: 24,
                    dataRowMinHeight: 60,
                    dataRowMaxHeight: 60,
                    columns: [
                      DataColumn(label: Text("YEAR", style: _headerStyle)),
                      DataColumn(label: Text("PRODUCT", style: _headerStyle)),
                      DataColumn(
                        label: Text("DESCRIPTION", style: _headerStyle),
                      ),
                      DataColumn(
                        label: Text("TARGET (g/m)", style: _headerStyle),
                      ),
                      DataColumn(
                        label: Text("WIDTH (mm)", style: _headerStyle),
                      ),
                      DataColumn(
                        label: Text(
                          loc.version.toUpperCase(),
                          style: _headerStyle,
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          loc.status.toUpperCase(),
                          style: _headerStyle,
                        ),
                      ),
                      DataColumn(label: Text("UPDATED", style: _headerStyle)),
                      DataColumn(
                        label: Text(
                          loc.actions.toUpperCase(),
                          style: _headerStyle,
                        ),
                      ),
                    ],
                    rows: items.map((bom) {
                      return DataRow(
                        onSelectChanged: (_) => _navigateToDetailView(bom),
                        cells: [
                          DataCell(
                            Text(
                              "${bom.applicableYear}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          DataCell(
                            BlocBuilder<ProductCubit, ProductState>(
                              builder: (context, pState) {
                                if (pState is ProductLoaded) {
                                  final p = pState.allProducts
                                      .where((e) => e.id == bom.productId)
                                      .firstOrNull;
                                  if (p != null) {
                                    return Text(
                                      p.itemCode,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  }
                                }
                                return Text("ID: ${bom.productId}");
                              },
                            ),
                          ),
                          DataCell(
                            Text(
                              bom.displayName ?? "-",
                              style: const TextStyle(color: Colors.black87),
                            ),
                          ),
                          DataCell(Text(bom.targetWeightGm.toStringAsFixed(2))),
                          DataCell(
                            Text(bom.widthBehindLoom?.toString() ?? "-"),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "v${bom.version}",
                                style: TextStyle(
                                  color: Colors.blue.shade800,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          DataCell(_buildStatusBadge(bom.isActive, loc)),
                          DataCell(
                            Text(
                              bom.updatedAt != null
                                  ? DateFormat(
                                      'dd/MM/yyyy',
                                    ).format(bom.updatedAt!)
                                  : "-",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    color: Colors.orange,
                                    size: 20,
                                  ),
                                  tooltip: "Edit BOM",
                                  onPressed: () =>
                                      _navigateToCreateOrEdit(bom: bom),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.redAccent,
                                    size: 20,
                                  ),
                                  onPressed: () => _confirmDelete(context, bom),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  TextStyle get _headerStyle => TextStyle(
    color: Colors.grey.shade600,
    fontWeight: FontWeight.bold,
    fontSize: 12,
    letterSpacing: 0.5,
  );

  Widget _buildStatusBadge(bool isActive, AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isActive ? Colors.green.shade200 : Colors.grey.shade300,
        ),
      ),
      child: Text(
        isActive ? loc.active : loc.inactive,
        style: TextStyle(
          color: isActive ? Colors.green.shade700 : Colors.grey.shade600,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // --- MOBILE LIST ---
  Widget _buildMobileList(
    BuildContext context,
    List<BOMHeader> items,
    AppLocalizations loc,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, sep) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final bom = items[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _navigateToDetailView(bom),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Year: ${bom.applicableYear}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      _buildStatusBadge(bom.isActive, loc),
                    ],
                  ),
                  const SizedBox(height: 8),
                  BlocBuilder<ProductCubit, ProductState>(
                    builder: (context, pState) {
                      String pName = "PID: ${bom.productId}";
                      if (pState is ProductLoaded) {
                        final p = pState.allProducts
                            .where((e) => e.id == bom.productId)
                            .firstOrNull;
                        if (p != null) pName = p.itemCode;
                      }
                      return Row(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 16,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            pName,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.scale, size: 16, color: Colors.grey.shade500),
                      const SizedBox(width: 6),
                      Text(
                        "Target: ${bom.targetWeightGm} g/m",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.straighten,
                        size: 16,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Width: ${bom.widthBehindLoom ?? '-'} mm",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, BOMHeader item) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.deleteBOM),
        content: Text("Confirm delete BOM for Year ${item.applicableYear}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () {
              context.read<BOMCubit>().deleteBOMHeader(item.bomId);
              Navigator.pop(ctx);
            },
            child: Text(loc.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
