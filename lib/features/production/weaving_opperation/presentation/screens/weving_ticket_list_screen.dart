import 'package:excel/excel.dart'
    show
        Excel,
        CellStyle,
        CellIndex,
        TextCellValue,
        ExcelColor,
        HorizontalAlign,
        TextWrapping;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:owvds/features/production/loom_state/product/presentation/bloc/product_cubit.dart';
import 'package:owvds/features/production/weaving/domain/weaving_model.dart';
import 'package:owvds/features/production/weaving/presentation/bloc/weaving_cubit.dart';
import 'package:owvds/features/production/weaving_opperation/presentation/bloc/machine_operation_cubit.dart';
import 'package:owvds/features/production/weaving_opperation/weaving_ticket_detail/weaving_ticket_detail_screen.dart';

// ============================================================
// ENUMS & MODELS
// ============================================================

enum DateFilterMode { all, date, month, quarter, year }

class _DateFilter {
  final DateFilterMode mode;
  final DateTime? specificDate;
  final int? month;
  final int? quarter;
  final int? year;

  const _DateFilter({
    this.mode = DateFilterMode.all,
    this.specificDate,
    this.month,
    this.quarter,
    this.year,
  });

  _DateFilter copyWith({
    DateFilterMode? mode,
    DateTime? specificDate,
    int? month,
    int? quarter,
    int? year,
  }) {
    return _DateFilter(
      mode: mode ?? this.mode,
      specificDate: specificDate ?? this.specificDate,
      month: month ?? this.month,
      quarter: quarter ?? this.quarter,
      year: year ?? this.year,
    );
  }
}

// ============================================================
// MAIN SCREEN
// ============================================================

class WeavingTicketListScreen extends StatefulWidget {
  const WeavingTicketListScreen({super.key});

  @override
  State<WeavingTicketListScreen> createState() =>
      _WeavingTicketListScreenState();
}

class _WeavingTicketListScreenState extends State<WeavingTicketListScreen> {
  // ── Màu chủ đạo (giữ nguyên theme xanh navy của project) ──
  static const Color kPrimary = Color(0xFF003366);
  static const Color kPrimaryLight = Color(0xFF1A5299);
  static const Color kBg = Color(0xFFF5F7FA);
  static const Color kSurface = Colors.white;
  static const Color kGreen = Color(0xFF16A34A);
  static const Color kAmber = Color(0xFFD97706);
  static const Color kRed = Color(0xFFDC2626);

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchText = '';
  String _statusFilter = 'all'; // 'all' | 'done' | 'inprogress'
  bool _isExporting = false;

  final now = DateTime.now();
  late _DateFilter _dateFilter;

  @override
  void initState() {
    super.initState();
    _dateFilter = _DateFilter(
      mode: DateFilterMode.all,
      specificDate: DateTime.now(),
      month: DateTime.now().month,
      quarter: ((DateTime.now().month - 1) ~/ 3) + 1,
      year: DateTime.now().year,
    );
    context.read<WeavingCubit>().loadTickets();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Lọc danh sách ──────────────────────────────────────────
  List<WeavingTicket> _applyFilters(List<WeavingTicket> all) {
    return all.where((t) {
      // Text search
      final q = _searchText.toLowerCase();
      final matchSearch =
          q.isEmpty ||
          t.code.toLowerCase().contains(q) ||
          (t.productItemCode ?? '').toLowerCase().contains(q) ||
          (t.employeeInName ?? '').toLowerCase().contains(q) ||
          (t.basketCode ?? '').toLowerCase().contains(q);

      // Status
      final matchStatus =
          _statusFilter == 'all' ||
          (_statusFilter == 'done' && t.timeOut != null) ||
          (_statusFilter == 'inprogress' && t.timeOut == null);

      // Date filter (dựa trên timeIn)
      bool matchDate = true;
      if (t.timeIn.isNotEmpty && _dateFilter.mode != DateFilterMode.all) {
        try {
          final dt = DateTime.parse(t.timeIn).toLocal();
          switch (_dateFilter.mode) {
            case DateFilterMode.date:
              final ref = _dateFilter.specificDate!;
              matchDate =
                  dt.year == ref.year &&
                  dt.month == ref.month &&
                  dt.day == ref.day;
              break;
            case DateFilterMode.month:
              matchDate =
                  dt.year == _dateFilter.year && dt.month == _dateFilter.month;
              break;
            case DateFilterMode.quarter:
              final q = ((dt.month - 1) ~/ 3) + 1;
              matchDate =
                  dt.year == _dateFilter.year && q == _dateFilter.quarter;
              break;
            case DateFilterMode.year:
              matchDate = dt.year == _dateFilter.year;
              break;
            case DateFilterMode.all:
              break;
          }
        } catch (_) {}
      }

      return matchSearch && matchStatus && matchDate;
    }).toList();
  }

  // ── Xuất Excel ─────────────────────────────────────────────
  Future<void> _exportExcel(
    List<WeavingTicket> tickets,
    MachineOpState machineState,
  ) async {
    setState(() => _isExporting = true);
    try {
      final excel = Excel.createExcel();
      // Lấy sheet mặc định và đổi tên an toàn
      final defaultSheetName = excel.getDefaultSheet() ?? 'Sheet1';
      excel.rename(defaultSheetName, 'Phieu_Ro_Det');
      final sheet = excel['Phieu_Ro_Det'];

      // Style header
      final headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#003366'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: HorizontalAlign.Center,
        textWrapping: TextWrapping.WrapText,
      );

      final headers = [
        'Mã Phiếu',
        'Sản Phẩm',
        'Tên Máy',
        'Line',
        'Ngày Lên Sợi',
        'Rổ',
        'Giờ Vào',
        'NV Vào',
        'Giờ Ra',
        'NV Ra',
        'TL Bì (kg)',
        'TL Thực (kg)',
        'Dài (m)',
        'Số Nút',
        'Lô Sợi (BatCode | NCC | Loại | SL)',
        'Trạng Thái',
      ];

      // Ghi header
      for (var i = 0; i < headers.length; i++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
        sheet.setColumnWidth(i, i == 14 ? 40 : (i < 6 ? 16 : 14));
      }

      // Ghi dữ liệu
      for (var ri = 0; ri < tickets.length; ri++) {
        final t = tickets[ri];
        final isEven = ri % 2 == 0;
        final rowBg = isEven ? '#FFFFFF' : '#F0F4FF';
        final rowStyle = CellStyle(
          backgroundColorHex: ExcelColor.fromHexString(rowBg),
        );

        // Tra tên máy từ MachineOperationCubit state
        String machineName = 'M${t.machineId}';
        if (machineState is MachineOpLoaded) {
          final m = machineState.machines
              .where((e) => e.id == t.machineId)
              .toList();
          if (m.isNotEmpty) machineName = m.first.machineName;
        }

        // Lô sợi: ưu tiên internalBatchCode, fallback batchId
        final yarnsStr = t.yarns
            .map((y) {
              final batchCode =
                  (y.internalBatchCode != null &&
                      y.internalBatchCode!.isNotEmpty)
                  ? y.internalBatchCode!
                  : 'Lô#${y.batchId}';
              final ncc = y.supplierShortName ?? '—';
              return '$batchCode | $ncc | ${y.componentType} | ${y.quantity}kg';
            })
            .join(' / ');

        final row = [
          (t.code.isEmpty || t.code.toUpperCase() == 'AUTO')
              ? '#${t.id}'
              : t.code,
          t.productItemCode ?? '',
          machineName,
          t.machineLine,
          t.yarnLoadDate,
          t.basketCode ?? '',
          _fmtDateTime(t.timeIn),
          t.employeeInName ?? '—',
          t.timeOut != null ? _fmtDateTime(t.timeOut!) : '—',
          t.employeeOutName ?? '—',
          t.grossWeight.toString(),
          t.netWeight.toString(),
          t.lengthMeters.toString(),
          t.numberOfKnots.toString(),
          yarnsStr,
          t.timeOut != null ? 'Hoàn thành' : 'Đang xử lý',
        ];

        for (var ci = 0; ci < row.length; ci++) {
          final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: ci, rowIndex: ri + 1),
          );
          cell.value = TextCellValue(row[ci].toString());
          cell.cellStyle = rowStyle;
        }
      }

      // Xuất file trực tiếp trên web qua dart:html
      final bytes = excel.encode()!;
      final fileName =
          'Phieu_Ro_Det_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';

      final blob = html.Blob([
        Uint8List.fromList(bytes),
      ], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      html.Url.revokeObjectUrl(url);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xuất file $fileName'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xuất Excel: $e'), backgroundColor: kRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  String _fmtDateTime(String iso) {
    try {
      return DateFormat('dd/MM HH:mm').format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }

  String _fmtDateLabel() {
    switch (_dateFilter.mode) {
      case DateFilterMode.all:
        return 'Tất cả';
      case DateFilterMode.date:
        return DateFormat('dd/MM/yyyy').format(_dateFilter.specificDate!);
      case DateFilterMode.month:
        return 'Tháng ${_dateFilter.month}/${_dateFilter.year}';
      case DateFilterMode.quarter:
        return 'Q${_dateFilter.quarter}/${_dateFilter.year}';
      case DateFilterMode.year:
        return 'Năm ${_dateFilter.year}';
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: _buildAppBar(),
      body: BlocBuilder<WeavingCubit, WeavingState>(
        builder: (context, state) {
          if (state is WeavingLoading) {
            return const Center(
              child: CircularProgressIndicator(color: kPrimary),
            );
          }
          if (state is WeavingError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: kRed, size: 48),
                  const SizedBox(height: 12),
                  Text(state.message, style: const TextStyle(color: kRed)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.read<WeavingCubit>().loadTickets(),
                    style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
                    child: const Text(
                      'Thử lại',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          }

          final allTickets = state is WeavingLoaded
              ? state.tickets
              : <WeavingTicket>[];
          final filtered = _applyFilters(allTickets);

          return Column(
            children: [
              // ── Thanh lọc ──────────────────────────────────
              _buildFilterSection(filtered, allTickets),

              // ── Thống kê nhanh ─────────────────────────────
              _buildStatsRow(filtered),

              // ── Danh sách ──────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => _buildTicketCard(filtered[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── AppBar ──────────────────────────────────────────────────
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: kPrimary,
      foregroundColor: Colors.white,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quản lý Phiếu Rổ Dệt',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            'Weaving Basket Tickets',
            style: TextStyle(fontSize: 11, color: Colors.white70),
          ),
        ],
      ),
      actions: [
        BlocBuilder<WeavingCubit, WeavingState>(
          builder: (context, state) {
            final allTickets = state is WeavingLoaded
                ? state.tickets
                : <WeavingTicket>[];
            final filtered = _applyFilters(allTickets);
            return _isExporting
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.file_download_outlined),
                    tooltip: 'Xuất Excel (${filtered.length} phiếu)',
                    onPressed: () {
                      final ms = context.read<MachineOperationCubit>().state;
                      _exportExcel(filtered, ms);
                    },
                  );
          },
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Tải lại',
          onPressed: () => context.read<WeavingCubit>().loadTickets(),
        ),
      ],
    );
  }

  // ── Khu vực lọc ─────────────────────────────────────────────
  Widget _buildFilterSection(
    List<WeavingTicket> filtered,
    List<WeavingTicket> all,
  ) {
    return Container(
      color: kSurface,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        children: [
          // Thanh tìm kiếm
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Tìm theo mã phiếu, sản phẩm, nhân viên, rổ...',
              hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
              prefixIcon: const Icon(
                Icons.search,
                size: 20,
                color: Colors.grey,
              ),
              suffixIcon: _searchText.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchText = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: kBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: kPrimary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              isDense: true,
            ),
            style: const TextStyle(fontSize: 13),
            onChanged: (v) => setState(() => _searchText = v),
          ),
          const SizedBox(height: 10),

          // Bộ lọc thời gian + Trạng thái
          Row(
            children: [
              // Nút lọc thời gian
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 15),
                  label: Text(
                    _fmtDateLabel(),
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _dateFilter.mode != DateFilterMode.all
                        ? kPrimary
                        : Colors.grey[600],
                    side: BorderSide(
                      color: _dateFilter.mode != DateFilterMode.all
                          ? kPrimary
                          : const Color(0xFFE2E8F0),
                      width: _dateFilter.mode != DateFilterMode.all ? 1.5 : 1,
                    ),
                    backgroundColor: _dateFilter.mode != DateFilterMode.all
                        ? const Color(0xFFEFF6FF)
                        : kSurface,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => _showDateFilterSheet(),
                ),
              ),
              const SizedBox(width: 8),

              // Filter Trạng thái
              _StatusToggle(
                value: _statusFilter,
                onChanged: (v) => setState(() => _statusFilter = v),
              ),
            ],
          ),

          // Badge xóa lọc nếu đang lọc ngày
          if (_dateFilter.mode != DateFilterMode.all) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.filter_alt,
                        size: 13,
                        color: kPrimaryLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Đang lọc: ${_fmtDateLabel()} · ${filtered.length} phiếu',
                        style: const TextStyle(
                          fontSize: 11,
                          color: kPrimaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => setState(
                          () => _dateFilter = _dateFilter.copyWith(
                            mode: DateFilterMode.all,
                          ),
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: kPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Thống kê nhanh ──────────────────────────────────────────
  Widget _buildStatsRow(List<WeavingTicket> tickets) {
    final done = tickets.where((t) => t.timeOut != null).length;
    final inProg = tickets.where((t) => t.timeOut == null).length;
    final totalNet = tickets
        .where((t) => t.timeOut != null)
        .fold<double>(0, (s, t) => s + t.netWeight);

    return Container(
      color: kSurface,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Row(
        children: [
          _StatChip(label: 'Tổng', value: '${tickets.length}', color: kPrimary),
          const SizedBox(width: 8),
          _StatChip(label: 'Hoàn thành', value: '$done', color: kGreen),
          const SizedBox(width: 8),
          _StatChip(label: 'Đang xử lý', value: '$inProg', color: kAmber),
          const SizedBox(width: 8),
          _StatChip(
            label: 'TL thực',
            value: '${totalNet.toStringAsFixed(1)}kg',
            color: const Color(0xFF7C3AED),
          ),
        ],
      ),
    );
  }

  // ── Card phiếu ──────────────────────────────────────────────
  Widget _buildTicketCard(WeavingTicket ticket) {
    final isDone = ticket.timeOut != null;
    final statusColor = isDone ? kGreen : kAmber;
    final statusBg = isDone ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7);
    final statusText = isDone ? 'Hoàn thành' : 'Đang xử lý';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDone ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      color: kSurface,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WeavingTicketDetailScreen(ticket: ticket),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hàng 1: Mã phiếu + Badge trạng thái ──
              Row(
                children: [
                  Expanded(
                    child: Text(
                      (ticket.code.isEmpty ||
                              ticket.code.toUpperCase() == 'AUTO')
                          ? '#${ticket.id}'
                          : ticket.code,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: kPrimary,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isDone ? Icons.check_circle : Icons.timelapse,
                          size: 12,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ── Hàng 2: Sản phẩm + Máy + Rổ (dùng Cubit giống detail screen) ──
              Row(
                children: [
                  // Mã sản phẩm — lấy từ ProductCubit
                  BlocBuilder<ProductCubit, ProductState>(
                    builder: (context, productState) {
                      String productText = ticket.productItemCode ?? '...';
                      if (productText == '...' || productText.isEmpty) {
                        if (productState is ProductLoaded) {
                          final product = productState.allProducts
                              .where((e) => e.id == ticket.productId)
                              .firstOrNull;
                          productText =
                              product?.itemCode ?? 'ID:${ticket.productId}';
                        }
                      }
                      return _InfoChip(
                        icon: Icons.inventory_2_outlined,
                        text: productText,
                        color: kPrimary,
                      );
                    },
                  ),
                  const SizedBox(width: 6),
                  // Tên máy + line — lấy từ MachineOperationCubit
                  BlocBuilder<MachineOperationCubit, MachineOpState>(
                    builder: (context, machineState) {
                      String machineText = 'Line ${ticket.machineLine}';
                      if (machineState is MachineOpLoaded) {
                        final machine = machineState.machines
                            .where((e) => e.id == ticket.machineId)
                            .firstOrNull;
                        if (machine != null) {
                          machineText =
                              '${machine.machineName} · Line${ticket.machineLine}';
                        }
                      }
                      return _InfoChip(
                        icon: Icons.precision_manufacturing_outlined,
                        text: machineText,
                        color: Colors.grey[700]!,
                      );
                    },
                  ),
                  const SizedBox(width: 6),
                  _InfoChip(
                    icon: Icons.shopping_basket_outlined,
                    text: ticket.basketCode ?? '—',
                    color: Colors.grey[700]!,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ── Hàng 3: Thời gian ──
              Row(
                children: [
                  const Icon(Icons.login, size: 13, color: kGreen),
                  const SizedBox(width: 4),
                  Text(
                    _fmtDateTime(ticket.timeIn),
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '·',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.logout, size: 13, color: Colors.blueAccent),
                  const SizedBox(width: 4),
                  Text(
                    ticket.timeOut != null
                        ? _fmtDateTime(ticket.timeOut!)
                        : '—',
                    style: TextStyle(
                      fontSize: 12,
                      color: ticket.timeOut != null
                          ? Colors.black54
                          : Colors.grey[400],
                    ),
                  ),
                ],
              ),

              // ── Hàng 4: Sợi & kết quả (nếu đã xong) ──
              if (ticket.yarns.isNotEmpty || isDone) ...[
                const SizedBox(height: 8),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Hiển thị lô sợi: loại + mã lô + NCC
                    Expanded(
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: ticket.yarns.map((y) {
                          final c = _componentColor(y.componentType);
                          final batchLabel =
                              y.internalBatchCode ?? 'Lô#${y.batchId}';
                          final ncc = y.supplierShortName ?? '';
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: c.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: c.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Badge loại sợi
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: c,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    y.componentType.isNotEmpty
                                        ? y.componentType
                                        : '?',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                // Mã lô
                                Text(
                                  batchLabel,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: c,
                                  ),
                                ),
                                // NCC
                                if (ncc.isNotEmpty) ...[
                                  const SizedBox(width: 3),
                                  Text(
                                    '[$ncc]',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: c.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // Kết quả TL (nếu hoàn thành)
                    if (isDone)
                      Row(
                        children: [
                          _ResultBadge(
                            label: 'Net',
                            value: '${ticket.netWeight.toStringAsFixed(1)}kg',
                            color: kGreen,
                          ),
                          const SizedBox(width: 6),
                          _ResultBadge(
                            label: 'Dài',
                            value: '${ticket.lengthMeters.toStringAsFixed(0)}m',
                            color: kPrimaryLight,
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Empty state ──────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Không có phiếu nào phù hợp',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thử thay đổi bộ lọc hoặc từ khóa tìm kiếm',
            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  // ── Bottom sheet chọn bộ lọc thời gian ─────────────────────
  void _showDateFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DateFilterSheet(
        initial: _dateFilter,
        onApply: (f) => setState(() => _dateFilter = f),
      ),
    );
  }

  Color _componentColor(String type) {
    switch (type) {
      case 'GROUND':
        return const Color(0xFF2563EB);
      case 'FILLING':
        return const Color(0xFF059669);
      case 'BINDER':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF7C3AED);
    }
  }
}

// ============================================================
// DATE FILTER BOTTOM SHEET
// ============================================================

class _DateFilterSheet extends StatefulWidget {
  final _DateFilter initial;
  final void Function(_DateFilter) onApply;

  const _DateFilterSheet({required this.initial, required this.onApply});

  @override
  State<_DateFilterSheet> createState() => _DateFilterSheetState();
}

class _DateFilterSheetState extends State<_DateFilterSheet> {
  static const Color kPrimary = Color(0xFF003366);

  late _DateFilter _filter;
  final now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _filter = widget.initial;
  }

  List<int> get _yearList => List.generate(5, (i) => now.year - i);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            const Row(
              children: [
                Icon(Icons.calendar_today, size: 18, color: kPrimary),
                SizedBox(width: 8),
                Text(
                  'Lọc theo thời gian',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Chọn mode
            const Text(
              'Chế độ lọc',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _ModeChip(
                  label: 'Tất cả',
                  selected: _filter.mode == DateFilterMode.all,
                  onTap: () => setState(
                    () => _filter = _filter.copyWith(mode: DateFilterMode.all),
                  ),
                ),
                _ModeChip(
                  label: 'Ngày',
                  selected: _filter.mode == DateFilterMode.date,
                  onTap: () => setState(
                    () => _filter = _filter.copyWith(mode: DateFilterMode.date),
                  ),
                ),
                _ModeChip(
                  label: 'Tháng',
                  selected: _filter.mode == DateFilterMode.month,
                  onTap: () => setState(
                    () =>
                        _filter = _filter.copyWith(mode: DateFilterMode.month),
                  ),
                ),
                _ModeChip(
                  label: 'Quý',
                  selected: _filter.mode == DateFilterMode.quarter,
                  onTap: () => setState(
                    () => _filter = _filter.copyWith(
                      mode: DateFilterMode.quarter,
                    ),
                  ),
                ),
                _ModeChip(
                  label: 'Năm',
                  selected: _filter.mode == DateFilterMode.year,
                  onTap: () => setState(
                    () => _filter = _filter.copyWith(mode: DateFilterMode.year),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Chọn giá trị theo mode
            if (_filter.mode == DateFilterMode.date) ...[
              const Text(
                'Chọn ngày',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _filter.specificDate ?? now,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    builder: (_, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(primary: kPrimary),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) {
                    setState(
                      () => _filter = _filter.copyWith(specificDate: picked),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: kPrimary),
                    borderRadius: BorderRadius.circular(10),
                    color: const Color(0xFFEFF6FF),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event, color: kPrimary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat(
                          'dd/MM/yyyy',
                        ).format(_filter.specificDate ?? now),
                        style: const TextStyle(
                          color: kPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            if (_filter.mode == DateFilterMode.month) ...[
              const Text(
                'Chọn tháng và năm',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown<int>(
                      value: _filter.month ?? now.month,
                      items: List.generate(
                        12,
                        (i) => DropdownMenuItem(
                          value: i + 1,
                          child: Text('Tháng ${i + 1}'),
                        ),
                      ),
                      onChanged: (v) =>
                          setState(() => _filter = _filter.copyWith(month: v)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildDropdown<int>(
                      value: _filter.year ?? now.year,
                      items: _yearList
                          .map(
                            (y) =>
                                DropdownMenuItem(value: y, child: Text('$y')),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _filter = _filter.copyWith(year: v)),
                    ),
                  ),
                ],
              ),
            ],

            if (_filter.mode == DateFilterMode.quarter) ...[
              const Text(
                'Chọn quý và năm',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [1, 2, 3, 4].map((q) {
                        final sel = (_filter.quarter ?? 1) == q;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(
                              () => _filter = _filter.copyWith(quarter: q),
                            ),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: EdgeInsets.only(right: q < 4 ? 6 : 0),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: sel ? kPrimary : Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Q$q',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: sel ? Colors.white : Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 100,
                    child: _buildDropdown<int>(
                      value: _filter.year ?? now.year,
                      items: _yearList
                          .map(
                            (y) =>
                                DropdownMenuItem(value: y, child: Text('$y')),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _filter = _filter.copyWith(year: v)),
                    ),
                  ),
                ],
              ),
            ],

            if (_filter.mode == DateFilterMode.year) ...[
              const Text(
                'Chọn năm',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _yearList.map((y) {
                  final sel = (_filter.year ?? now.year) == y;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _filter = _filter.copyWith(year: y)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: sel ? kPrimary : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$y',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: sel ? Colors.white : Colors.grey[600],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 20),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Hủy'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onApply(_filter);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Áp dụng',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        isDense: true,
      ),
      style: const TextStyle(fontSize: 13, color: Colors.black87),
    );
  }
}

// ============================================================
// SMALL WIDGETS
// ============================================================

class _StatusToggle extends StatelessWidget {
  final String value;
  final void Function(String) onChanged;

  const _StatusToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _tab('all', 'Tất cả'),
          _tab('done', '✓'),
          _tab('inprogress', '⟳'),
        ],
      ),
    );
  }

  Widget _tab(String v, String label) {
    final sel = value == v;
    return GestureDetector(
      onTap: () => onChanged(v),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFF003366) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: sel ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ResultBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ResultBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(fontSize: 10, color: color.withOpacity(0.7)),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF003366) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF003366) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}
