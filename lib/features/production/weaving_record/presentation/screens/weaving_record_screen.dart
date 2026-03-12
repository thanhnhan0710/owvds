import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:owvds/features/production/weaving_record/domain/weaving_record_model.dart';
import 'package:owvds/features/production/weaving_record/presentation/bloc/weaving_record_cubit.dart';
import 'package:owvds/l10n/app_localizations.dart';

// Import các thư viện hỗ trợ đa nền tảng
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
// ignore: depend_on_referenced_packages
import 'package:universal_io/io.dart' as io;
import 'package:universal_html/html.dart' as html;

enum DateFilterType { day, week, month, quarter, custom }

class WeavingRecordScreen extends StatefulWidget {
  final bool isEmbedded;
  const WeavingRecordScreen({super.key, this.isEmbedded = false});

  @override
  State<WeavingRecordScreen> createState() => _WeavingRecordScreenState();
}

class _WeavingRecordScreenState extends State<WeavingRecordScreen> {
  // State
  DateFilterType _selectedFilter = DateFilterType.day;
  DateTimeRange? _customDateRange;
  List<WeavingRecord> _filteredList = [];

  // Controllers
  final TextEditingController _searchCtrl = TextEditingController();
  // [MỚI] Scroll Controllers cho Desktop
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<WeavingRecordCubit>().loadRecords();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  // --- LOGIC LỌC DỮ LIỆU ---
  void _applyFilter(List<WeavingRecord> originalList) {
    final now = DateTime.now();
    DateTime start;
    DateTime end;

    switch (_selectedFilter) {
      case DateFilterType.day:
        start = DateTime(now.year, now.month, now.day);
        end = start
            .add(const Duration(days: 1))
            .subtract(const Duration(seconds: 1));
        break;
      case DateFilterType.week:
        // Tuần này (Từ thứ 2)
        start = now.subtract(Duration(days: now.weekday - 1));
        start = DateTime(start.year, start.month, start.day);
        end = start
            .add(const Duration(days: 7))
            .subtract(const Duration(seconds: 1));
        break;
      case DateFilterType.month:
        start = DateTime(now.year, now.month, 1);
        end = DateTime(
          now.year,
          now.month + 1,
          1,
        ).subtract(const Duration(seconds: 1));
        break;
      case DateFilterType.quarter:
        int quarter = ((now.month - 1) / 3).floor() + 1;
        start = DateTime(now.year, (quarter - 1) * 3 + 1, 1);
        end = DateTime(
          now.year,
          quarter * 3 + 1,
          1,
        ).subtract(const Duration(seconds: 1));
        break;
      case DateFilterType.custom:
        if (_customDateRange != null) {
          start = _customDateRange!.start;
          end = _customDateRange!.end
              .add(const Duration(days: 1))
              .subtract(const Duration(seconds: 1));
        } else {
          start = DateTime(2000);
          end = DateTime(3000);
        }
        break;
    }

    setState(() {
      _filteredList = originalList.where((item) {
        if (item.updatedAt == null) return false;

        // 1. Lọc theo ngày
        bool inDate =
            item.updatedAt!.isAfter(start) && item.updatedAt!.isBefore(end);

        // 2. Lọc theo từ khóa
        bool matchKeyword = true;
        if (_searchCtrl.text.isNotEmpty) {
          final kw = _searchCtrl.text.toLowerCase();
          matchKeyword =
              (item.machineName ?? '').toLowerCase().contains(kw) ||
              (item.basketCode ?? '').toLowerCase().contains(kw) ||
              (item.updatedByName ?? '').toLowerCase().contains(kw) ||
              (item.shiftName ?? '').toLowerCase().contains(kw);
        }

        return inDate && matchKeyword;
      }).toList();

      // Sắp xếp: Mới nhất lên đầu
      _filteredList.sort(
        (a, b) =>
            (b.updatedAt ?? DateTime(0)).compareTo(a.updatedAt ?? DateTime(0)),
      );
    });
  }

  // --- HÀM HELPER UI ---
  String _getFilterLabel(AppLocalizations l10n) {
    switch (_selectedFilter) {
      case DateFilterType.day:
        return l10n.filterToday;
      case DateFilterType.week:
        return "Tuần này";
      case DateFilterType.month:
        return l10n.filterThisMonth;
      case DateFilterType.quarter:
        return l10n.filterThisQuarter;
      case DateFilterType.custom:
        return l10n.filterCustom;
    }
  }

  Future<void> _pickDateRange(List<WeavingRecord> originalList) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _customDateRange,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: const Color(0xFF003366),
            colorScheme: const ColorScheme.light(primary: Color(0xFF003366)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _selectedFilter = DateFilterType.custom;
      });
      _applyFilter(originalList);
    }
  }

  // --- LOGIC XUẤT EXCEL ---
  Future<void> _exportToExcel() async {
    if (_filteredList.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Không có dữ liệu để xuất")));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Đang tạo file Excel..."),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      var excel = Excel.createExcel();
      Sheet sheet = excel['Sheet1'];

      // Header
      List<String> headers = [
        'Ngày giờ',
        'Máy',
        'Line',
        'Ca',
        'Mã Rổ',
        'KL Tịnh (Kg)',
        'Phế Run (Kg)',
        'Phế Setup (Kg)',
        'Người cập nhật',
      ];
      CellStyle headerStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        backgroundColorHex: ExcelColor.blueGrey200,
      );

      for (var i = 0; i < headers.length; i++) {
        var cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }

      // Data Rows
      for (var i = 0; i < _filteredList.length; i++) {
        final item = _filteredList[i];
        final row = i + 1;

        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value = TextCellValue(
          item.updatedAt != null
              ? DateFormat('dd/MM/yyyy HH:mm').format(item.updatedAt!)
              : "",
        );
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
            .value = TextCellValue(
          item.machineName ?? "-",
        );
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
            .value = IntCellValue(
          item.line,
        );
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
            .value = TextCellValue(
          item.shiftName ?? "-",
        );
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
            .value = TextCellValue(
          item.basketCode ?? "-",
        );
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
            .value = DoubleCellValue(
          item.totalWeight,
        );
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row))
            .value = DoubleCellValue(
          item.runWaste,
        );
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row))
            .value = DoubleCellValue(
          item.setupWaste,
        );
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row))
            .value = TextCellValue(
          item.updatedByName ?? "-",
        );
      }

      final List<int>? fileBytes = excel.save();

      if (fileBytes != null) {
        String fileName =
            'WeavingReport_${DateFormat('ddMMyy_HHmm').format(DateTime.now())}.xlsx';
        await FileSaveHelper.saveAndLaunch(fileBytes, fileName);
        if (!kIsWeb && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Đã lưu file: $fileName"),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi xuất file: $e"),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Màu nền xám nhạt hiện đại
      // AppBar ẩn nếu nhúng, hiện nếu độc lập
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: const Text(
                "Lịch sử Cân & Thống kê",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              backgroundColor: const Color(0xFF003366),
              iconTheme: const IconThemeData(color: Colors.white),
              actions: [
                IconButton(
                  icon: const Icon(Icons.file_download),
                  tooltip: "Xuất Excel",
                  onPressed: _exportToExcel,
                ),
              ],
            ),

      body: Column(
        children: [
          // Toolbar phụ (Chỉ hiện khi Embedded)
          if (widget.isEmbedded)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: _exportToExcel,
                    icon: const Icon(Icons.file_download, size: 18),
                    label: const Text("Xuất Excel"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF003366),
                      side: const BorderSide(color: Color(0xFF003366)),
                    ),
                  ),
                ],
              ),
            ),

          // --- HEADER BỘ LỌC (Compact Style) ---
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.black12)),
            ),
            child: BlocBuilder<WeavingRecordCubit, WeavingRecordState>(
              builder: (context, state) {
                // Lấy data gốc để filter
                List<WeavingRecord> originalList = [];
                if (state is WeavingRecordLoaded) originalList = state.records;

                return Column(
                  children: [
                    // Hàng 1: Search Bar
                    SizedBox(
                      height: 40,
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: "Tìm kiếm (Máy, Rổ, Ca...)",
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.grey,
                            size: 20,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 0,
                          ),
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 14),
                        onChanged: (val) => _applyFilter(originalList),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Hàng 2: Filter Chips & Date Picker
                    Row(
                      children: [
                        // Nút chọn loại thời gian (Popup)
                        PopupMenuButton<DateFilterType>(
                          onSelected: (type) {
                            setState(() => _selectedFilter = type);
                            if (type != DateFilterType.custom) {
                              _applyFilter(originalList);
                            } else {
                              _pickDateRange(originalList);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: DateFilterType.day,
                              child: Text(l10n.filterToday),
                            ), // "Hôm nay"
                            const PopupMenuItem(
                              value: DateFilterType.week,
                              child: Text("Tuần này"),
                            ),
                            PopupMenuItem(
                              value: DateFilterType.month,
                              child: Text(l10n.filterThisMonth),
                            ), // "Tháng này"
                            PopupMenuItem(
                              value: DateFilterType.quarter,
                              child: Text(l10n.filterThisQuarter),
                            ), // "Quý này"
                            const PopupMenuDivider(),
                            PopupMenuItem(
                              value: DateFilterType.custom,
                              child: Text(l10n.filterCustom),
                            ), // "Tùy chọn"
                          ],
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3F2FD), // Xanh nhạt
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.filter_list,
                                  size: 16,
                                  color: Color(0xFF003366),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _getFilterLabel(l10n),
                                  style: const TextStyle(
                                    color: Color(0xFF003366),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_drop_down,
                                  color: Color(0xFF003366),
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Nút hiển thị ngày / Chọn ngày tùy chỉnh
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickDateRange(originalList),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_month,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      (_selectedFilter ==
                                                  DateFilterType.custom &&
                                              _customDateRange != null)
                                          ? "${DateFormat('dd/MM').format(_customDateRange!.start)} - ${DateFormat('dd/MM').format(_customDateRange!.end)}"
                                          : (_selectedFilter ==
                                                    DateFilterType.day
                                                ? DateFormat(
                                                    'dd/MM/yyyy',
                                                  ).format(DateTime.now())
                                                : l10n
                                                      .filterCustom // "Chọn ngày..."
                                                      ),
                                      style: const TextStyle(fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),

          // --- KẾT QUẢ ---
          Expanded(
            child: BlocConsumer<WeavingRecordCubit, WeavingRecordState>(
              listener: (context, state) {
                if (state is WeavingRecordLoaded) {
                  _applyFilter(state.records);
                }
                if (state is WeavingRecordError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is WeavingRecordLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is WeavingRecordLoaded) {
                  final list = _filteredList; // Sử dụng list đã lọc
                  if (list.isEmpty) {
                    return const Center(
                      child: Text(
                        "Không tìm thấy dữ liệu",
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return SelectionArea(
                    child: Column(
                      children: [
                        // Summary Bar
                        Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Số lượng: ${list.length}",
                                style: TextStyle(
                                  color: Colors.blue.shade900,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                "Tổng KL: ${list.fold(0.0, (sum, item) => sum + item.totalWeight).toStringAsFixed(2)} kg",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF003366),
                                ),
                              ),
                            ],
                          ),
                        ),

                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth > 800) {
                                // [QUAN TRỌNG] Truyền constraints vào để tính toán độ rộng
                                return _buildDesktopTable(constraints);
                              } else {
                                return _buildMobileList();
                              }
                            },
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
        ],
      ),
    );
  }

  // --- UI DESKTOP (FULL SCREEN TABLE) ---
  Widget _buildDesktopTable(BoxConstraints constraints) {
    return Container(
      width: double.infinity,
      color: Colors.white, // Nền trắng cho bảng
      child: Scrollbar(
        controller: _verticalScrollController,
        thumbVisibility: true, // Luôn hiện thanh cuộn dọc
        child: SingleChildScrollView(
          controller: _verticalScrollController,
          scrollDirection: Axis.vertical,
          child: Scrollbar(
            controller: _horizontalScrollController,
            thumbVisibility: true, // Luôn hiện thanh cuộn ngang nếu có
            child: SingleChildScrollView(
              controller: _horizontalScrollController,
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                // [QUAN TRỌNG] Ép độ rộng tối thiểu bằng độ rộng màn hình (trừ lề)
                // Giúp bảng trải full màn hình
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(
                    Colors.grey.shade100,
                  ),
                  headingRowHeight: 45,
                  dataRowMinHeight: 45,
                  dataRowMaxHeight: 55,
                  columnSpacing: 20,
                  // border: TableBorder.all(color: Colors.grey.shade200), // Tùy chọn: Thêm viền
                  columns: const [
                    DataColumn(
                      label: Text(
                        'Thời gian',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Máy / Line',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Ca',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Mã Rổ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'KL Tịnh',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      numeric: true,
                    ),
                    DataColumn(
                      label: Text(
                        'Phế Run',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      numeric: true,
                    ),
                    DataColumn(
                      label: Text(
                        'Phế Setup',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      numeric: true,
                    ),
                    DataColumn(
                      label: Text(
                        'Người cập nhật',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  rows: _filteredList.map((item) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            item.updatedAt != null
                                ? DateFormat(
                                    'dd/MM HH:mm',
                                  ).format(item.updatedAt!)
                                : "-",
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        DataCell(
                          Text(
                            "${item.machineName ?? 'ID:${item.machineId}'} (L${item.line})",
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        DataCell(
                          Text(
                            item.shiftName ?? '-',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        DataCell(
                          Text(
                            item.basketCode ?? 'ID:${item.basketId}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            item.totalWeight.toStringAsFixed(2),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            item.runWaste.toStringAsFixed(2),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        DataCell(
                          Text(
                            item.setupWaste.toStringAsFixed(2),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        DataCell(
                          Text(
                            item.updatedByName ?? '-',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- UI MOBILE ---
  Widget _buildMobileList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      itemCount: _filteredList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final item = _filteredList[index];
        return Card(
          elevation: 1,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${item.machineName ?? '?'} - Line ${item.line}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      item.updatedAt != null
                          ? DateFormat('dd/MM HH:mm').format(item.updatedAt!)
                          : "-",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 12, thickness: 0.5),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Rổ: ${item.basketCode ?? 'N/A'}",
                            style: const TextStyle(fontSize: 13),
                          ),
                          Text(
                            "Ca: ${item.shiftName ?? '-'}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "${item.totalWeight.toStringAsFixed(2)} kg",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          "Phế: ${item.runWaste}/${item.setupWaste}",
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// =========================================================
// HELPER CLASS: XỬ LÝ LƯU FILE ĐA NỀN TẢNG
// =========================================================
class FileSaveHelper {
  static Future<void> saveAndLaunch(List<int> bytes, String fileName) async {
    if (kIsWeb) {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      io.Directory? directory;
      if (io.Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory != null) {
        final path = "${directory.path}/$fileName";
        final file = io.File(path);
        await file.writeAsBytes(bytes, flush: true);
        await OpenFile.open(path);
      }
    }
  }
}
